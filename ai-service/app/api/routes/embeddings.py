import logging
from fastapi import APIRouter, HTTPException, status
from app.models.requests import EmbedRequest, SyncEmbeddingsRequest
from app.models.responses import EmbedResponse, SyncEmbeddingsResponse
from app.services.embedding_service import embedding_service
from app.services.vector_service import vector_service
from app.core.config import settings

logger = logging.getLogger("ai_service.routes.embeddings")

router = APIRouter(tags=["Embeddings Management"])

@router.post(
    "/embed",
    response_model=EmbedResponse,
    summary="Generate 384-dim Dense Vector Embedding",
    description="Generates normalized vector embedding for any input string using SentenceTransformers."
)
async def generate_embedding(req: EmbedRequest) -> EmbedResponse:
    if not req.text or not req.text.strip():
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Input text cannot be empty."
        )

    try:
        vec = embedding_service.generate_embedding(
            text=req.text,
            normalize=req.normalize if req.normalize is not None else True
        )
        return EmbedResponse(
            embedding=vec,
            dimension=len(vec),
            model=settings.EMBEDDING_MODEL_NAME
        )
    except Exception as e:
        logger.error(f"Embedding generation failed: {e}", exc_info=True)
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Embedding error: {str(e)}"
        )

@router.post(
    "/sync-embeddings",
    response_model=SyncEmbeddingsResponse,
    summary="Sync/Generate Embeddings for Projects",
    description="Scans project repository in PostgreSQL and generates embeddings for any project missing them, or forces refresh."
)
async def sync_embeddings(req: SyncEmbeddingsRequest = SyncEmbeddingsRequest()) -> SyncEmbeddingsResponse:
    try:
        res = vector_service.sync_all_embeddings(
            force_refresh=req.force_refresh or False,
            specific_project_id=req.project_id
        )
        return res
    except Exception as e:
        logger.error(f"Sync embeddings failed: {e}", exc_info=True)
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Sync embeddings error: {str(e)}"
        )

@router.post(
    "/embeddings/generate",
    response_model=SyncEmbeddingsResponse,
    summary="Alias for /sync-embeddings",
    description="Generates or refreshes embeddings for one or all projects."
)
async def generate_project_embeddings(req: SyncEmbeddingsRequest = SyncEmbeddingsRequest()) -> SyncEmbeddingsResponse:
    return await sync_embeddings(req)
