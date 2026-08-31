import logging
from typing import Optional, Dict, Any, List
import psycopg2
from psycopg2.extras import RealDictCursor

from app.database import get_db_connection
from app.models.requests import AnalyzeProjectRequest
from app.models.responses import AnalyzeProjectResponse
from app.services.gemini_service import gemini_service
from app.services.vector_service import vector_service
from app.services.embedding_service import embedding_service

logger = logging.getLogger("ai_service.analysis")

class AnalysisService:

    async def analyze_project(self, req: AnalyzeProjectRequest) -> AnalyzeProjectResponse:
        """
        Analyze project content (title, abstract, optional document text) to generate
        structured academic metadata (summary, domain, tech stack, keywords, problem statement).
        """
        logger.info(f"Analyzing project '{req.title}' (ID: {req.project_id})...")
        
        analysis = await gemini_service.analyze_project(
            title=req.title,
            abstract=req.abstract,
            document_text=req.document_text
        )

        # Merge any caller-provided tech stack or keywords if returned empty
        tech_stack = analysis.get("tech_stack") or req.tech_stack or []
        extracted_keywords = analysis.get("extracted_keywords") or req.keywords or []
        domain = analysis.get("domain") or req.domain or "Computer Science"
        summary = analysis.get("summary") or req.abstract
        problem_statement = analysis.get("problem_statement") or f"Addressing challenges in {domain} via {req.title}."
        ai_status = analysis.get("ai_status", "COMPLETED")

        is_persisted = False

        if req.save_to_db and req.project_id:
            is_persisted = self.persist_analysis(
                project_id=req.project_id,
                summary=summary,
                domain=domain,
                tech_stack=tech_stack,
                extracted_keywords=extracted_keywords,
                problem_statement=problem_statement,
                ai_status=ai_status
            )
            # Also generate and upsert vector embedding with new analysis metadata
            try:
                emb = embedding_service.generate_project_embedding(
                    title=req.title,
                    abstract=req.abstract,
                    tech_stack=tech_stack,
                    domain=domain,
                    keywords=extracted_keywords
                )
                vector_service.upsert_embedding(req.project_id, emb)
                logger.info(f"Generated and persisted embedding for project #{req.project_id}")
            except Exception as e:
                logger.warning(f"Could not auto-generate embedding for project #{req.project_id}: {e}")

        return AnalyzeProjectResponse(
            project_id=req.project_id,
            summary=summary,
            domain=domain,
            sub_domains=analysis.get("sub_domains", []),
            tech_stack=tech_stack,
            extracted_keywords=extracted_keywords,
            problem_statement=problem_statement,
            ai_status=ai_status,
            is_persisted=is_persisted
        )

    def persist_analysis(
        self,
        project_id: int,
        summary: str,
        domain: str,
        tech_stack: List[str],
        extracted_keywords: List[str],
        problem_statement: str,
        ai_status: str
    ) -> bool:
        """Persist structured analysis to ai_analyses table in PostgreSQL."""
        try:
            with get_db_connection() as conn:
                with conn.cursor() as cur:
                    query = """
                        INSERT INTO ai_analyses (
                            project_id, summary, domain, extracted_keywords, 
                            tech_stack, problem_statement, ai_status, updated_at
                        )
                        VALUES (%s, %s, %s, %s, %s, %s, %s, CURRENT_TIMESTAMP)
                        ON CONFLICT (project_id) DO UPDATE SET
                            summary = EXCLUDED.summary,
                            domain = EXCLUDED.domain,
                            extracted_keywords = EXCLUDED.extracted_keywords,
                            tech_stack = EXCLUDED.tech_stack,
                            problem_statement = EXCLUDED.problem_statement,
                            ai_status = EXCLUDED.ai_status,
                            updated_at = CURRENT_TIMESTAMP;
                    """
                    cur.execute(query, (
                        project_id,
                        summary,
                        domain,
                        extracted_keywords,
                        tech_stack,
                        problem_statement,
                        ai_status
                    ))
                    conn.commit()
                    logger.info(f"Successfully persisted AI analysis for project #{project_id}")
                    return True
        except Exception as e:
            logger.error(f"Failed to persist AI analysis for project #{project_id}: {e}")
            return False

analysis_service = AnalysisService()
