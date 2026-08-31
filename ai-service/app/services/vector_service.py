import logging
import json
from typing import List, Optional, Dict, Any, Tuple
import psycopg2
from psycopg2.extras import RealDictCursor

from app.database import get_db_connection, is_vector_extension_available
from app.core.config import settings
from app.models.responses import ProjectSearchResult, SyncEmbeddingsResponse
from app.services.embedding_service import embedding_service

logger = logging.getLogger("ai_service.vector")

class VectorService:

    def search_similar_projects(
        self,
        query_vector: List[float],
        limit: int = 5,
        threshold: float = 0.20,
        department_id: Optional[int] = None,
        academic_year: Optional[str] = None,
        project_type: Optional[str] = None,
        status: Optional[str] = "APPROVED",
        visibility: Optional[str] = "PUBLIC"
    ) -> List[ProjectSearchResult]:
        """Perform semantic similarity search against project_embeddings in PostgreSQL."""
        has_pgvector = is_vector_extension_available()
        results: List[ProjectSearchResult] = []
        
        # Build dynamic where filters
        where_clauses = []
        params: List[Any] = []
        
        if status:
            where_clauses.append("p.status = %s")
            params.append(status)
        if visibility:
            where_clauses.append("p.visibility = %s")
            params.append(visibility)
        if department_id:
            where_clauses.append("p.department_id = %s")
            params.append(department_id)
        if academic_year:
            where_clauses.append("p.academic_year = %s")
            params.append(academic_year)
        if project_type:
            where_clauses.append("p.project_type = %s")
            params.append(project_type)
            
        where_sql = ("WHERE " + " AND ".join(where_clauses)) if where_clauses else ""

        try:
            with get_db_connection() as conn:
                with conn.cursor(cursor_factory=RealDictCursor) as cur:
                    if has_pgvector:
                        vector_str = f"[{','.join(map(str, query_vector))}]"
                        query_sql = f"""
                            SELECT 
                                p.id,
                                p.title,
                                p.abstract,
                                p.academic_year,
                                p.semester,
                                p.project_type,
                                p.status,
                                p.visibility,
                                p.department_id,
                                d.name as department_name,
                                COALESCE(u.name, 'Student Contributor') as author_name,
                                p.repository_url,
                                ai.domain,
                                ai.tech_stack,
                                ai.extracted_keywords,
                                (1 - (pe.embedding_vector <=> %s::vector)) as similarity_score
                            FROM projects p
                            INNER JOIN project_embeddings pe ON p.id = pe.project_id
                            LEFT JOIN departments d ON p.department_id = d.id
                            LEFT JOIN users u ON p.created_by_user_id = u.id
                            LEFT JOIN ai_analyses ai ON p.id = ai.project_id
                            {where_sql}
                            ORDER BY pe.embedding_vector <=> %s::vector ASC
                            LIMIT %s;
                        """
                        # Insert vector_str twice (for select similarity and order by), and limit
                        exec_params = [vector_str] + params + [vector_str, limit]
                        cur.execute(query_sql, exec_params)
                    else:
                        # Fallback using cosine_similarity function or python calculation
                        query_sql = f"""
                            SELECT 
                                p.id,
                                p.title,
                                p.abstract,
                                p.academic_year,
                                p.semester,
                                p.project_type,
                                p.status,
                                p.visibility,
                                p.department_id,
                                d.name as department_name,
                                COALESCE(u.name, 'Student Contributor') as author_name,
                                p.repository_url,
                                ai.domain,
                                ai.tech_stack,
                                ai.extracted_keywords,
                                pe.embedding_vector
                            FROM projects p
                            INNER JOIN project_embeddings pe ON p.id = pe.project_id
                            LEFT JOIN departments d ON p.department_id = d.id
                            LEFT JOIN users u ON p.created_by_user_id = u.id
                            LEFT JOIN ai_analyses ai ON p.id = ai.project_id
                            {where_sql};
                        """
                        cur.execute(query_sql, params)
                        raw_rows = cur.fetchall()
                        
                        # Compute similarity in python
                        scored_rows = []
                        for row in raw_rows:
                            emb = row.get("embedding_vector")
                            if emb is not None:
                                if isinstance(emb, str):
                                    # parse string array "[0.1, 0.2...]" or "{0.1, 0.2...}"
                                    cleaned = emb.strip("[]{}").split(",")
                                    emb = [float(x) for x in cleaned if x.strip()]
                                score = embedding_service.cosine_similarity(query_vector, list(emb))
                                row["similarity_score"] = score
                                scored_rows.append(row)
                                
                        scored_rows.sort(key=lambda r: r["similarity_score"], reverse=True)
                        rows = scored_rows[:limit]
                        raw_rows = rows
                    
                    if has_pgvector:
                        raw_rows = cur.fetchall()

                    for r in raw_rows:
                        score = float(r.get("similarity_score") or 0.0)
                        if score >= threshold:
                            tech_stack = r.get("tech_stack") or []
                            if isinstance(tech_stack, str):
                                tech_stack = [t.strip() for t in tech_stack.strip("{}[]").split(",") if t.strip()]
                            
                            keywords = r.get("extracted_keywords") or []
                            if isinstance(keywords, str):
                                keywords = [k.strip() for k in keywords.strip("{}[]").split(",") if k.strip()]

                            results.append(ProjectSearchResult(
                                id=r["id"],
                                title=r["title"],
                                abstract=r["abstract"],
                                academic_year=r["academic_year"],
                                semester=r["semester"],
                                project_type=r["project_type"],
                                status=r["status"],
                                visibility=r["visibility"],
                                department_id=r["department_id"],
                                department_name=r.get("department_name"),
                                author_name=r.get("author_name"),
                                similarity_score=round(score, 4),
                                domain=r.get("domain"),
                                tech_stack=tech_stack,
                                keywords=keywords,
                                repository_url=r.get("repository_url")
                            ))
                            
            logger.info(f"Vector search retrieved {len(results)} projects above threshold {threshold}")
            return results

        except Exception as e:
            logger.error(f"Error during vector search: {e}")
            raise e

    def get_project_by_id(self, project_id: int) -> Optional[Dict[str, Any]]:
        """Retrieve full project details with department and ai_analysis."""
        try:
            with get_db_connection() as conn:
                with conn.cursor(cursor_factory=RealDictCursor) as cur:
                    query = """
                        SELECT 
                            p.id,
                            p.title,
                            p.abstract,
                            p.academic_year,
                            p.semester,
                            p.project_type,
                            p.status,
                            p.visibility,
                            p.department_id,
                            d.name as department_name,
                            COALESCE(u.name, 'Student Contributor') as author_name,
                            p.repository_url,
                            ai.summary as ai_summary,
                            ai.domain as ai_domain,
                            ai.tech_stack as ai_tech_stack,
                            ai.extracted_keywords as ai_keywords,
                            ai.problem_statement as ai_problem_statement
                        FROM projects p
                        LEFT JOIN departments d ON p.department_id = d.id
                        LEFT JOIN users u ON p.created_by_user_id = u.id
                        LEFT JOIN ai_analyses ai ON p.id = ai.project_id
                        WHERE p.id = %s;
                    """
                    cur.execute(query, (project_id,))
                    row = cur.fetchone()
                    return dict(row) if row else None
        except Exception as e:
            logger.error(f"Error fetching project #{project_id}: {e}")
            return None

    def upsert_embedding(
        self,
        project_id: int,
        embedding: List[float],
        model_version: str = "sentence-transformers/all-MiniLM-L6-v2"
    ) -> bool:
        """Upsert a project's embedding vector into project_embeddings table."""
        has_pgvector = is_vector_extension_available()
        try:
            with get_db_connection() as conn:
                with conn.cursor() as cur:
                    if has_pgvector:
                        vector_str = f"[{','.join(map(str, embedding))}]"
                        query = """
                            INSERT INTO project_embeddings (project_id, embedding_vector, model_version, updated_at)
                            VALUES (%s, %s::vector, %s, CURRENT_TIMESTAMP)
                            ON CONFLICT (project_id) DO UPDATE 
                            SET embedding_vector = EXCLUDED.embedding_vector,
                                model_version = EXCLUDED.model_version,
                                updated_at = CURRENT_TIMESTAMP;
                        """
                        cur.execute(query, (project_id, vector_str, model_version))
                    else:
                        query = """
                            INSERT INTO project_embeddings (project_id, embedding_vector, model_version, updated_at)
                            VALUES (%s, %s, %s, CURRENT_TIMESTAMP)
                            ON CONFLICT (project_id) DO UPDATE 
                            SET embedding_vector = EXCLUDED.embedding_vector,
                                model_version = EXCLUDED.model_version,
                                updated_at = CURRENT_TIMESTAMP;
                        """
                        cur.execute(query, (project_id, embedding, model_version))
                    conn.commit()
                    return True
        except Exception as e:
            logger.error(f"Error upserting embedding for project #{project_id}: {e}")
            return False

    def sync_all_embeddings(
        self,
        force_refresh: bool = False,
        specific_project_id: Optional[int] = None
    ) -> SyncEmbeddingsResponse:
        """Scan projects table and generate embeddings for projects lacking them or force all."""
        total_processed = 0
        generated_count = 0
        updated_count = 0
        skipped_count = 0
        errors: List[str] = []

        try:
            with get_db_connection() as conn:
                with conn.cursor(cursor_factory=RealDictCursor) as cur:
                    if specific_project_id:
                        cur.execute("""
                            SELECT p.id, p.title, p.abstract, ai.domain, ai.tech_stack, ai.extracted_keywords,
                                   pe.id as existing_embedding_id
                            FROM projects p
                            LEFT JOIN ai_analyses ai ON p.id = ai.project_id
                            LEFT JOIN project_embeddings pe ON p.id = pe.project_id
                            WHERE p.id = %s;
                        """, (specific_project_id,))
                    else:
                        cur.execute("""
                            SELECT p.id, p.title, p.abstract, ai.domain, ai.tech_stack, ai.extracted_keywords,
                                   pe.id as existing_embedding_id
                            FROM projects p
                            LEFT JOIN ai_analyses ai ON p.id = ai.project_id
                            LEFT JOIN project_embeddings pe ON p.id = pe.project_id
                            ORDER BY p.id ASC;
                        """)
                    
                    rows = cur.fetchall()

            for r in rows:
                pid = r["id"]
                has_existing = bool(r.get("existing_embedding_id"))
                total_processed += 1

                if has_existing and not force_refresh:
                    skipped_count += 1
                    continue

                try:
                    tech_stack = r.get("tech_stack")
                    if isinstance(tech_stack, str):
                        tech_stack = [t.strip() for t in tech_stack.strip("{}[]").split(",") if t.strip()]
                    keywords = r.get("extracted_keywords")
                    if isinstance(keywords, str):
                        keywords = [k.strip() for k in keywords.strip("{}[]").split(",") if k.strip()]

                    embedding = embedding_service.generate_project_embedding(
                        title=r["title"],
                        abstract=r["abstract"],
                        tech_stack=tech_stack,
                        domain=r.get("domain"),
                        keywords=keywords
                    )

                    success = self.upsert_embedding(
                        project_id=pid,
                        embedding=embedding,
                        model_version=settings.EMBEDDING_MODEL_NAME
                    )

                    if success:
                        if has_existing:
                            updated_count += 1
                        else:
                            generated_count += 1
                    else:
                        errors.append(f"Failed to upsert embedding for project #{pid}")

                except Exception as ex:
                    logger.error(f"Error processing embedding for project #{pid}: {ex}")
                    errors.append(f"Project #{pid}: {str(ex)}")

            msg = f"Processed {total_processed} projects. Generated: {generated_count}, Updated: {updated_count}, Skipped: {skipped_count}."
            logger.info(msg)
            return SyncEmbeddingsResponse(
                total_processed=total_processed,
                generated_count=generated_count,
                updated_count=updated_count,
                skipped_count=skipped_count,
                errors=errors,
                message=msg
            )

        except Exception as e:
            logger.error(f"Error in sync_all_embeddings: {e}")
            raise e

vector_service = VectorService()
