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

IR_STOP_WORDS = {
    "a", "an", "the", "and", "or", "of", "in", "on", "at", "to", "for", "with", "via", "by",
    "from", "into", "over", "after", "is", "are", "was", "were", "be", "been", "using", "based",
    "system", "systems", "powered", "platform", "platforms", "framework", "frameworks",
    "application", "applications", "app", "solution", "solutions", "project", "projects",
    "engine", "engines", "service", "services", "management", "automated", "tool", "tools",
    "model", "models", "architecture", "implementation", "development", "approach", "high"
}

class VectorService:

    def _compute_lexical_score(
        self,
        query_tokens: List[str],
        query_text: Optional[str],
        title: str,
        abstract: str,
        domain: Optional[str],
        tech_stack: Any,
        keywords: Any
    ) -> float:
        """Compute keyword, compound phrase, prefix, and domain overlap score in range [0.0, 1.0]."""
        if not query_tokens and not query_text:
            return 0.0

        title_lower = (title or "").lower()
        abstract_lower = (abstract or "").lower()
        domain_lower = (domain or "").lower()
        q_raw_lower = (query_text or "").lower().strip()
        
        tech_list = []
        if isinstance(tech_stack, list):
            tech_list = [str(t).lower() for t in tech_stack]
        elif isinstance(tech_stack, str):
            tech_list = [t.lower().strip() for t in tech_stack.strip("{}[]").split(",") if t.strip()]

        kw_list = []
        if isinstance(keywords, list):
            kw_list = [str(k).lower() for k in keywords]
        elif isinstance(keywords, str):
            kw_list = [k.lower().strip() for k in keywords.strip("{}[]").split(",") if k.strip()]

        score = 0.0
        matched_tokens_count = 0
        total_tokens = len(query_tokens)

        # 1. Compound Bigram / Phrase Exact Match (e.g., "smart city", "smart cities", "infrastructure monitoring")
        bigrams = []
        if len(query_tokens) >= 2:
            for i in range(len(query_tokens) - 1):
                t1, t2 = query_tokens[i], query_tokens[i+1]
                bigrams.append(f"{t1} {t2}")
                if t1.endswith("y"):
                    bigrams.append(f"{t1[:-1]}ies {t2}")
                if t2.endswith("y"):
                    bigrams.append(f"{t1} {t2[:-1]}ies")

        has_bigram_match = False
        for bg in bigrams:
            # Polysemy check: "health monitoring" vs "structural health monitoring"
            # If project is Civil Structural Health (Bridges/Buildings) and user didn't ask for "structural", skip
            if bg == "health monitoring" and "structural" in title_lower and "structural" not in q_raw_lower:
                continue

            if bg in domain_lower or bg in title_lower or bg in abstract_lower:
                score += 0.50
                has_bigram_match = True
                break

        # 2. Token-level matching with stemming normalization
        for token in query_tokens:
            if not token or len(token) < 2:
                continue

            # Skip "health" token matching on civil structural bridge projects unless query specifies "structural"
            if token == "health" and "structural" in title_lower and "structural" not in q_raw_lower:
                continue

            stems = [token]
            if token.endswith("y"):
                stems.append(token[:-1] + "ies")
            elif token.endswith("ies"):
                stems.append(token[:-3] + "y")
            if token.endswith("s"):
                stems.append(token[:-1])

            matched_title = any(s in title_lower for s in stems)
            matched_domain = any(s in domain_lower for s in stems)
            matched_kw = any(any(s in kw for s in stems) for kw in kw_list)
            matched_abstract = any(s in abstract_lower for s in stems)

            if matched_domain or matched_title or matched_kw or matched_abstract:
                matched_tokens_count += 1
                if matched_domain:
                    score += 0.20
                if matched_title:
                    score += 0.25
                if matched_kw:
                    score += 0.15
                if matched_abstract:
                    score += 0.10

        # 3. Query Coverage Gating:
        # If the user supplied >= 3 distinct search terms, require at least 50% term coverage OR a compound bigram match
        if total_tokens >= 3:
            coverage = matched_tokens_count / total_tokens
            if not has_bigram_match and coverage < 0.50:
                # Isolated word coincidence (e.g., only "smart" in smart contract, or only "infrastructure" in cloud)
                return 0.0

        return min(1.0, score)

    def search_similar_projects(
        self,
        query_vector: List[float],
        query_text: Optional[str] = None,
        limit: int = 5,
        threshold: float = 0.20,
        department_id: Optional[int] = None,
        academic_year: Optional[str] = None,
        project_type: Optional[str] = None,
        status: Optional[str] = "APPROVED",
        visibility: Optional[str] = "PUBLIC"
    ) -> List[ProjectSearchResult]:
        """Perform hybrid semantic similarity search combining pgvector dense embeddings with lexical boosting."""
        has_pgvector = is_vector_extension_available()
        results: List[ProjectSearchResult] = []
        
        # Extract discriminative query tokens (filtering out generic stop words & boilerplate)
        clean_tokens = []
        if query_text:
            norm_text = query_text.lower().replace("-", " ").replace("_", " ")
            raw_tokens = norm_text.split()
            for t in raw_tokens:
                ct = t.strip(".,!?:;\"'()[]{}")
                if len(ct) >= 2 and ct not in IR_STOP_WORDS:
                    clean_tokens.append(ct)
            # If all words were stop words (e.g. query was just "ai"), fallback to all non-empty tokens
            if not clean_tokens and raw_tokens:
                clean_tokens = [t.strip(".,!?:;\"'()[]{}") for t in raw_tokens if len(t.strip(".,!?:;\"'()[]{}")) >= 2]

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
        candidate_limit = max(limit * 5, 30)

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
                        exec_params = [vector_str] + params + [vector_str, candidate_limit]
                        cur.execute(query_sql, exec_params)
                        raw_rows = cur.fetchall()
                    else:
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
                        for row in raw_rows:
                            emb = row.get("embedding_vector")
                            if emb is not None:
                                if isinstance(emb, str):
                                    cleaned = emb.strip("[]{}").split(",")
                                    emb = [float(x) for x in cleaned if x.strip()]
                                score = embedding_service.cosine_similarity(query_vector, list(emb))
                                row["similarity_score"] = score
                            else:
                                row["similarity_score"] = 0.0

            # Compute Hybrid Reranked Score
            scored_candidates = []
            for r in raw_rows:
                v_score = float(r.get("similarity_score") or 0.0)
                lex_score = self._compute_lexical_score(
                    query_tokens=clean_tokens,
                    query_text=query_text,
                    title=r.get("title", ""),
                    abstract=r.get("abstract", ""),
                    domain=r.get("domain"),
                    tech_stack=r.get("tech_stack"),
                    keywords=r.get("extracted_keywords")
                )

                # Hybrid scoring formula:
                if clean_tokens:
                    if lex_score > 0:
                        # Meaningful keyword match boost
                        final_score = min(1.0, 0.50 * v_score + 0.45 * lex_score + 0.05)
                    else:
                        # User provided specific keywords but project has 0 lexical overlap:
                        # Apply penalty so unrelated domains (smart grids, event bus, etc.) are filtered out
                        final_score = max(0.0, v_score * 0.45)
                else:
                    final_score = v_score

                r["similarity_score"] = final_score
                if final_score >= threshold:
                    scored_candidates.append(r)

            # Sort by highest hybrid similarity score
            scored_candidates.sort(key=lambda x: x["similarity_score"], reverse=True)
            final_rows = scored_candidates[:limit]

            for r in final_rows:
                score = float(r.get("similarity_score") or 0.0)
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
                            
            logger.info(f"Hybrid search retrieved {len(results)} projects above threshold {threshold} for query '{query_text}'")
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

    def get_project_recommendations(
        self,
        project_id: int,
        limit: int = 5,
        threshold: float = 0.10
    ) -> List[ProjectSearchResult]:
        """Compute top-N similar projects for a selected project using vector cosine distance, excluding itself."""
        target_proj = self.get_project_by_id(project_id)
        if not target_proj:
            logger.warning(f"Project #{project_id} not found for recommendations")
            return []

        # 1. Retrieve or generate target embedding
        has_pgvector = is_vector_extension_available()
        target_vector: Optional[List[float]] = None

        try:
            with get_db_connection() as conn:
                with conn.cursor(cursor_factory=RealDictCursor) as cur:
                    cur.execute("SELECT embedding_vector FROM project_embeddings WHERE project_id = %s;", (project_id,))
                    emb_row = cur.fetchone()
                    if emb_row and emb_row.get("embedding_vector") is not None:
                        raw_emb = emb_row["embedding_vector"]
                        if isinstance(raw_emb, str):
                            target_vector = [float(x) for x in raw_emb.strip("[]{}").split(",") if x.strip()]
                        else:
                            target_vector = list(raw_emb)
        except Exception as e:
            logger.warn(f"Failed to fetch existing embedding for project #{project_id}: {e}")

        if not target_vector:
            # Generate embedding on the fly
            tech = target_proj.get("ai_tech_stack") or []
            if isinstance(tech, str):
                tech = [t.strip() for t in tech.strip("{}[]").split(",") if t.strip()]
            keywords = target_proj.get("ai_keywords") or []
            if isinstance(keywords, str):
                keywords = [k.strip() for k in keywords.strip("{}[]").split(",") if k.strip()]

            target_vector = embedding_service.generate_project_embedding(
                title=target_proj["title"],
                abstract=target_proj["abstract"],
                tech_stack=tech,
                domain=target_proj.get("ai_domain"),
                keywords=keywords
            )
            # Store it for future use
            self.upsert_embedding(project_id, target_vector)

        # 2. Search similar projects excluding current project (p.id != project_id)
        results: List[ProjectSearchResult] = []
        try:
            with get_db_connection() as conn:
                with conn.cursor(cursor_factory=RealDictCursor) as cur:
                    if has_pgvector:
                        vector_str = f"[{','.join(map(str, target_vector))}]"
                        query_sql = """
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
                            WHERE p.id != %s
                              AND p.status = 'APPROVED'
                              AND p.visibility = 'PUBLIC'
                            ORDER BY pe.embedding_vector <=> %s::vector ASC
                            LIMIT %s;
                        """
                        cur.execute(query_sql, (vector_str, project_id, vector_str, limit))
                        raw_rows = cur.fetchall()
                    else:
                        query_sql = """
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
                            WHERE p.id != %s
                              AND p.status = 'APPROVED'
                              AND p.visibility = 'PUBLIC';
                        """
                        cur.execute(query_sql, (project_id,))
                        raw_candidates = cur.fetchall()
                        scored = []
                        for row in raw_candidates:
                            emb = row.get("embedding_vector")
                            if emb is not None:
                                if isinstance(emb, str):
                                    emb = [float(x) for x in emb.strip("[]{}").split(",") if x.strip()]
                                score = embedding_service.cosine_similarity(target_vector, list(emb))
                                row["similarity_score"] = score
                                scored.append(row)
                        scored.sort(key=lambda r: r["similarity_score"], reverse=True)
                        raw_rows = scored[:limit]

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

            logger.info(f"Generated {len(results)} recommendations for project #{project_id}")
            return results
        except Exception as e:
            logger.error(f"Error generating recommendations for project #{project_id}: {e}")
            return []

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
