from app.services.embedding_service import embedding_service, EmbeddingService
from app.services.vector_service import vector_service, VectorService
from app.services.gemini_service import gemini_service, GeminiService
from app.services.rag_service import rag_service, RagService
from app.services.analysis_service import analysis_service, AnalysisService

def get_embedding_service() -> EmbeddingService:
    return embedding_service

def get_vector_service() -> VectorService:
    return vector_service

def get_gemini_service() -> GeminiService:
    return gemini_service

def get_rag_service() -> RagService:
    return rag_service

def get_analysis_service() -> AnalysisService:
    return analysis_service
