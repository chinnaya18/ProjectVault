import time
import logging
from fastapi import APIRouter, HTTPException, status
from app.models.requests import SemanticSearchRequest
from app.models.responses import SemanticSearchResponse
from app.services.embedding_service import embedding_service
from app.services.vector_service import vector_service
from app.core.config import settings

logger = logging.getLogger("ai_service.routes.search")

router = APIRouter(tags=["Semantic Search"])

@router.post(
    "/search",
    response_model=SemanticSearchResponse,
    summary="Semantic Vector Search for Projects",
    description="Embeds natural language query using SentenceTransformers and retrieves top matching projects from pgvector."
)
async def semantic_search(req: SemanticSearchRequest) -> SemanticSearchResponse:
    if not req.query or not req.query.strip():
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Search query string cannot be empty."
        )

    start_time = time.time()
    try:
        # 1. Generate Query Vector
        query_vector = embedding_service.generate_embedding(req.query)
        
        # 2. Query Postgres pgvector
        limit = min(req.limit or settings.DEFAULT_SEARCH_LIMIT, settings.MAX_SEARCH_LIMIT)
        threshold = req.threshold if req.threshold is not None else settings.SIMILARITY_THRESHOLD

        results = vector_service.search_similar_projects(
            query_vector=query_vector,
            limit=limit,
            threshold=threshold,
            department_id=req.department_id,
            academic_year=req.academic_year,
            project_type=req.project_type
        )

        exec_time = round((time.time() - start_time) * 1000, 2)
        return SemanticSearchResponse(
            query=req.query,
            total_results=len(results),
            results=results,
            execution_time_ms=exec_time
        )
    except Exception as e:
        logger.error(f"Semantic search failed: {e}", exc_info=True)
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Semantic search error: {str(e)}"
        )
