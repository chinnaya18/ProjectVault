import logging
from contextlib import contextmanager
from typing import Optional, Generator
import psycopg2
from psycopg2 import pool
from psycopg2.extras import RealDictCursor

from app.core.config import settings

logger = logging.getLogger("ai_service.database")

_connection_pool: Optional[pool.ThreadedConnectionPool] = None
_has_pgvector: Optional[bool] = None

def init_db_pool(minconn: int = 1, maxconn: int = 10) -> None:
    """Initialize the PostgreSQL connection pool."""
    global _connection_pool
    if _connection_pool is None:
        try:
            logger.info("Initializing PostgreSQL connection pool...")
            _connection_pool = pool.ThreadedConnectionPool(
                minconn=minconn,
                maxconn=maxconn,
                host=settings.DB_HOST,
                port=settings.DB_PORT,
                database=settings.DB_NAME,
                user=settings.DB_USER,
                password=settings.DB_PASSWORD
            )
            logger.info("PostgreSQL connection pool initialized successfully.")
            _check_vector_extension()
        except Exception as e:
            logger.error(f"Failed to initialize database connection pool: {e}")
            raise e

def close_db_pool() -> None:
    """Close all database connections in the pool."""
    global _connection_pool
    if _connection_pool is not None:
        logger.info("Closing PostgreSQL connection pool...")
        _connection_pool.closeall()
        _connection_pool = None
        logger.info("PostgreSQL connection pool closed.")

def _check_vector_extension() -> bool:
    """Check if the vector extension is available in PostgreSQL."""
    global _has_pgvector
    try:
        with get_db_connection() as conn:
            with conn.cursor() as cur:
                cur.execute("SELECT 1 FROM pg_extension WHERE extname = 'vector';")
                res = cur.fetchone()
                _has_pgvector = bool(res)
                logger.info(f"pgvector extension status: {'Available' if _has_pgvector else 'Not installed (fallback enabled)'}")
                return _has_pgvector
    except Exception as e:
        logger.warning(f"Could not verify pgvector extension: {e}")
        _has_pgvector = False
        return False

def is_vector_extension_available() -> bool:
    global _has_pgvector
    if _has_pgvector is None:
        return _check_vector_extension()
    return _has_pgvector

@contextmanager
def get_db_connection() -> Generator[psycopg2.extensions.connection, None, None]:
    """Context manager for acquiring and releasing a connection from the pool."""
    global _connection_pool
    if _connection_pool is None:
        init_db_pool()
    
    conn = _connection_pool.getconn()
    try:
        # Register pgvector if extension is available
        if _has_pgvector:
            try:
                from pgvector.psycopg2 import register_vector
                register_vector(conn)
            except Exception:
                pass
        yield conn
    finally:
        _connection_pool.putconn(conn)

def check_db_health() -> dict:
    """Check the health of the PostgreSQL database."""
    try:
        with get_db_connection() as conn:
            with conn.cursor() as cur:
                cur.execute("SELECT 1;")
                cur.execute("SELECT count(*) FROM projects;")
                project_count = cur.fetchone()[0]
                
                cur.execute("SELECT count(*) FROM project_embeddings;")
                embedding_count = cur.fetchone()[0]
                
                return {
                    "connected": True,
                    "total_projects": project_count,
                    "total_embeddings": embedding_count,
                    "pgvector_active": is_vector_extension_available()
                }
    except Exception as e:
        logger.error(f"Database health check failed: {e}")
        return {
            "connected": False,
            "error": str(e),
            "total_projects": 0,
            "total_embeddings": 0,
            "pgvector_active": False
        }
