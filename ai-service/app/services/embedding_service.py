import logging
import numpy as np
from typing import List, Optional, Union
from sentence_transformers import SentenceTransformer
from app.core.config import settings

logger = logging.getLogger("ai_service.embedding")

class EmbeddingService:
    _instance: Optional["EmbeddingService"] = None
    _model: Optional[SentenceTransformer] = None

    def __new__(cls):
        if cls._instance is None:
            cls._instance = super(EmbeddingService, cls).__new__(cls)
        return cls._instance

    def load_model(self) -> None:
        """Load the SentenceTransformer model once into memory."""
        if self._model is None:
            model_name = settings.EMBEDDING_MODEL_NAME
            logger.info(f"Loading SentenceTransformer model '{model_name}'...")
            try:
                self._model = SentenceTransformer(model_name)
                logger.info(f"SentenceTransformer model '{model_name}' successfully loaded.")
            except Exception as e:
                logger.error(f"Failed to load SentenceTransformer model '{model_name}': {e}")
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

    def generate_embedding(self, text: str, normalize: bool = True) -> List[float]:
        """Generate a 384-dimensional dense vector embedding for input text."""
        if not text or not text.strip():
            # Return zero vector of proper dimension
            return [0.0] * settings.EMBEDDING_DIMENSION
        
        try:
            vector = self.model.encode(text, convert_to_numpy=True, normalize_embeddings=normalize)
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
