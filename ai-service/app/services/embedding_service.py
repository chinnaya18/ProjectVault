import os
import logging
import numpy as np
from typing import List, Optional, Union
from sentence_transformers import SentenceTransformer
from app.core.config import settings

logger = logging.getLogger("ai_service.embedding")

ACADEMIC_EXPANSIONS = {
    "agri": "agriculture farming crop harvest soil",
    "agric": "agriculture farming",
    "crop": "crop agriculture farming yield harvest",
    "ml": "machine learning deep learning neural network",
    "ai": "artificial intelligence machine learning deep learning",
    "crypto": "cryptocurrency blockchain web3 ethereum",
    "iot": "internet of things sensors embedded hardware esp32",
    "nlp": "natural language processing text transformer llm",
    "cv": "computer vision image processing opencv yolo",
    "ehr": "electronic health records healthcare medical clinical",
    "sbt": "soulbound tokens decentralized identity",
    "did": "decentralized identifier verifiable credential",
    "vrf": "verifiable random function oracle chainlink",
    "ecg": "electrocardiogram cardiac arrhythmia heart signal",
    "mri": "magnetic resonance imaging neuroimaging brats brain tumor",
    "kyc": "know your customer identity compliance zero knowledge",
    "gis": "geographic information systems spatial maps telemetry",
    "rag": "retrieval augmented generation vector search llm",
    "defi": "decentralized finance liquidity staking yield automated market maker",
    "dapp": "decentralized application web3 solidity smart contract",
    "p2p": "peer-to-peer distributed network",
}

class EmbeddingService:
    _instance: Optional["EmbeddingService"] = None
    _model: Optional[SentenceTransformer] = None

    def __new__(cls):
        if cls._instance is None:
            cls._instance = super(EmbeddingService, cls).__new__(cls)
        return cls._instance

    def expand_query(self, query: str) -> str:
        """Expand short academic abbreviations or single-word terms to enrich dense vector retrieval."""
        if not query or not query.strip():
            return query
        tokens = query.lower().strip().split()
        
        # If the user already wrote a descriptive multi-word query (>= 3 words), preserve exact semantics
        if len(tokens) >= 3:
            return query

        expanded_tokens = []
        has_expansion = False
        for t in tokens:
            clean_t = t.strip(".,!?:;\"'()[]{}")
            if clean_t in ACADEMIC_EXPANSIONS:
                expanded_tokens.append(f"{t} ({ACADEMIC_EXPANSIONS[clean_t]})")
                has_expansion = True
            else:
                expanded_tokens.append(t)
        return " ".join(expanded_tokens) if has_expansion else query

    def load_model(self) -> None:
        """Load the SentenceTransformer model once into memory with offline fallbacks."""
        if self._model is None:
            model_name = settings.EMBEDDING_MODEL_NAME
            
            # Check local candidate paths (in case model was transferred manually as files)
            base_dir = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
            candidate_paths = [
                os.path.join(base_dir, "models", "all-MiniLM-L6-v2"),
                os.path.join(base_dir, "models"),
                os.path.join(base_dir, "all-MiniLM-L6-v2")
            ]
            
            loaded = False
            for path in candidate_paths:
                if os.path.exists(path) and os.path.isdir(path):
                    try:
                        logger.info(f"Checking local offline SentenceTransformer model path: '{path}'...")
                        self._model = SentenceTransformer(path)
                        logger.info(f"SentenceTransformer successfully loaded from local path: '{path}'.")
                        loaded = True
                        break
                    except Exception as e:
                        logger.warning(f"Could not load from candidate path '{path}': {e}")

            if not loaded:
                logger.info(f"Loading SentenceTransformer model '{model_name}'...")
                try:
                    self._model = SentenceTransformer(model_name)
                    logger.info(f"SentenceTransformer model '{model_name}' successfully loaded.")
                except Exception as e:
                    logger.warning(f"Standard download/load for '{model_name}' failed: {e}. Trying local cache...")
                    try:
                        self._model = SentenceTransformer(model_name, local_files_only=True)
                        logger.info("SentenceTransformer successfully loaded from local HuggingFace cache.")
                    except Exception as cache_err:
                        logger.error(f"Failed to load SentenceTransformer even from cache: {cache_err}")
                        raise e

    @property
    def model(self) -> SentenceTransformer:
        if self._model is None:
            self.load_model()
        return self._model

    def build_project_text(
        self,
        title: str,
        abstract: str,
        tech_stack: Optional[List[str]] = None,
        domain: Optional[str] = None,
        keywords: Optional[List[str]] = None
    ) -> str:
        """Build standardized text representation from project metadata for embedding."""
        parts = [
            f"Title: {title.strip() if title else ''}",
            f"Abstract: {abstract.strip() if abstract else ''}"
        ]
        if domain:
            parts.append(f"Domain: {domain.strip()}")
        if tech_stack and len(tech_stack) > 0:
            tech_str = ", ".join([t.strip() for t in tech_stack if t.strip()])
            if tech_str:
                parts.append(f"Technologies: {tech_str}")
        if keywords and len(keywords) > 0:
            kw_str = ", ".join([k.strip() for k in keywords if k.strip()])
            if kw_str:
                parts.append(f"Keywords: {kw_str}")
        return "\n".join(parts)

    def generate_embedding(self, text: str, normalize: bool = True, expand: bool = False) -> List[float]:
        """Generate a 384-dimensional dense vector embedding for input text."""
        if not text or not text.strip():
            return [0.0] * settings.EMBEDDING_DIMENSION
        
        target_text = self.expand_query(text) if expand else text
        try:
            vector = self.model.encode(target_text, convert_to_numpy=True, normalize_embeddings=normalize)
            return vector.tolist()
        except Exception as e:
            logger.error(f"Error generating embedding for text: {e}")
            raise e

    def generate_project_embedding(
        self,
        title: str,
        abstract: str,
        tech_stack: Optional[List[str]] = None,
        domain: Optional[str] = None,
        keywords: Optional[List[str]] = None,
        normalize: bool = True
    ) -> List[float]:
        """Generate embedding for project metadata."""
        project_text = self.build_project_text(
            title=title,
            abstract=abstract,
            tech_stack=tech_stack,
            domain=domain,
            keywords=keywords
        )
        return self.generate_embedding(project_text, normalize=normalize)

    def cosine_similarity(self, vec1: List[float], vec2: List[float]) -> float:
        """Compute cosine similarity between two vector lists."""
        a = np.array(vec1, dtype=np.float32)
        b = np.array(vec2, dtype=np.float32)
        norm_a = np.linalg.norm(a)
        norm_b = np.linalg.norm(b)
        if norm_a == 0 or norm_b == 0:
            return 0.0
        return float(np.dot(a, b) / (norm_a * norm_b))

embedding_service = EmbeddingService()
