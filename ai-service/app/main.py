import logging
from contextlib import asynccontextmanager
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.core.config import settings
from app.database import init_db_pool, close_db_pool, check_db_health
from app.services.embedding_service import embedding_service
from app.services.gemini_service import gemini_service
from app.services.vector_service import vector_service

from app.api.routes import search, chat, analysis, embeddings
from app.models.responses import HealthResponse

# Configure root logger
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(name)s: %(message)s"
)
logger = logging.getLogger("ai_service.main")

@asynccontextmanager
async def lifespan(app: FastAPI):
    """Lifespan context manager: handles startup and shutdown tasks."""
    logger.info("==================================================")
    logger.info(f"Starting {settings.PROJECT_NAME} v{settings.VERSION}")
    logger.info("==================================================")
    
    # 1. Initialize PostgreSQL Connection Pool
    try:
        init_db_pool()
    except Exception as e:
        logger.warning(f"Could not connect to PostgreSQL on startup: {e}")

    # 2. Pre-load SentenceTransformer Embedding Model (only once into memory)
    try:
        embedding_service.load_model()
    except Exception as e:
        logger.error(f"Failed to pre-load SentenceTransformer model: {e}")

    # 3. Check Gemini LLM Configuration
    if gemini_service.is_configured():
        logger.info(f"Google Gemini configured successfully (Model: {settings.GEMINI_MODEL})")
    else:
        logger.warning("Google Gemini is not configured. Heuristic fallback will be used.")

    # 4. Safe sync of embeddings for unindexed projects in database
    try:
        sync_res = vector_service.sync_all_embeddings(force_refresh=False)
        logger.info(f"Startup embedding check: {sync_res.message}")
    except Exception as e:
        logger.warning(f"Startup embedding sync skipped/failed: {e}")

    yield

    # Shutdown
    logger.info("Shutting down AI Service...")
    close_db_pool()
    logger.info("AI Service shutdown complete.")

app = FastAPI(
    title=settings.PROJECT_NAME,
    version=settings.VERSION,
    description="Intelligent AI layer for ProjectVault: Semantic Search, RAG Question Answering, and Project Analysis.",
    openapi_url=f"{settings.API_V1_STR}/openapi.json",
    lifespan=lifespan
)

# CORS Middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Mount Routes under /api/v1/ai
app.include_router(search.router, prefix=settings.API_V1_STR)
app.include_router(chat.router, prefix=settings.API_V1_STR)
app.include_router(analysis.router, prefix=settings.API_V1_STR)
app.include_router(embeddings.router, prefix=settings.API_V1_STR)

# Mount Route Aliases under /api/ai for compatibility
app.include_router(search.router, prefix="/api/ai")
app.include_router(chat.router, prefix="/api/ai")
app.include_router(analysis.router, prefix="/api/ai")
app.include_router(embeddings.router, prefix="/api/ai")

@app.get("/health", response_model=HealthResponse, tags=["Health Check"])
async def health_check() -> HealthResponse:
    """Service health and component status check."""
    db_health = check_db_health()
    return HealthResponse(
        status="UP" if db_health.get("connected", False) else "DEGRADED",
        service=settings.PROJECT_NAME,
        version=settings.VERSION,
        embedding_model=settings.EMBEDDING_MODEL_NAME,
        embedding_dimension=settings.EMBEDDING_DIMENSION,
        gemini_configured=gemini_service.is_configured(),
        gemini_model=settings.GEMINI_MODEL,
        database=db_health
    )

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(
        "app.main:app",
        host=settings.AI_SERVICE_HOST,
        port=settings.AI_SERVICE_PORT,
        reload=True
    )
