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
        # 1. Generate Query Vector with semantic abbreviation expansion
        query_vector = embedding_service.generate_embedding(req.query, expand=True)
        
        # 2. Query Postgres pgvector with hybrid lexical re-ranking
        limit = min(req.limit or settings.DEFAULT_SEARCH_LIMIT, settings.MAX_SEARCH_LIMIT)
        threshold = req.threshold if req.threshold is not None else settings.SIMILARITY_THRESHOLD

        results = vector_service.search_similar_projects(
            query_vector=query_vector,
            query_text=req.query,
            limit=limit,
            threshold=threshold,
            department_id=req.department_id,
            academic_year=req.academic_year,
            project_type=req.project_type
        )

        topic_feedback = None
        # If no projects found or similarity is below threshold, generate AI topic viability guidance
        if len(results) == 0 or (len(results) > 0 and results[0].similarity_score < 0.28):
            try:
                from app.services.gemini_service import gemini_service
                topic_feedback = await gemini_service.evaluate_project_topic(req.query)
            except Exception as tf_err:
                logger.warning(f"Could not generate topic feedback: {tf_err}")

        exec_time = round((time.time() - start_time) * 1000, 2)
        return SemanticSearchResponse(
            query=req.query,
            total_results=len(results),
            results=results,
            execution_time_ms=exec_time,
            topic_feedback=topic_feedback
        )
    except Exception as e:
        logger.error(f"Semantic search failed: {e}", exc_info=True)
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Semantic search error: {str(e)}"
        )

@router.get(
    "/topic-feedback",
    summary="Evaluate Novel Topic Feasibility & Guidance",
    description="Analyzes whether a proposed capstone idea is feasible, provides tech stack recommendations, and roadmap."
)
async def evaluate_topic(query: str):
    if not query or not query.strip():
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Query string cannot be empty."
        )
    from app.services.gemini_service import gemini_service
    feedback = await gemini_service.evaluate_project_topic(query)
    return feedback

@router.get(
    "/recommendations/{project_id}",
    response_model=SemanticSearchResponse,
    summary="Get Top Semantic Recommendations for a Project",
    description="Retrieves top similar academic projects in pgvector excluding the target project."
)
async def get_project_recommendations(
    project_id: int,
    limit: int = 5,
    threshold: float = 0.10
) -> SemanticSearchResponse:
    start_time = time.time()
    try:
        results = vector_service.get_project_recommendations(
            project_id=project_id,
            limit=min(limit, 20),
            threshold=threshold
        )
        exec_time = round((time.time() - start_time) * 1000, 2)
        return SemanticSearchResponse(
            query=f"recommendations_for_project_{project_id}",
            total_results=len(results),
            results=results,
            execution_time_ms=exec_time
        )
    except Exception as e:
        logger.error(f"Recommendation generation failed: {e}", exc_info=True)
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Recommendation error: {str(e)}"
        )

