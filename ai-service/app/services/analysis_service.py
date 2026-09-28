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

from app.services.code_similarity_service import code_similarity_service

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

    async def analyze_plagiarism_and_duplication(
        self,
        project_id: Optional[int],
        title: str,
        abstract: str,
        document_text: Optional[str] = None,
        repository_url: Optional[str] = None,
        save_to_db: bool = True
    ) -> Dict[str, Any]:
        """
        Comprehensive Multi-Modal AI Evaluation:
        1. Internet plagiarism score with intelligent citation / attribution exclusion.
        2. Internal Multi-Modal duplication scan against vault projects:
           - Layer A: Vector Cosine Similarity of SRS & Abstract text
           - Layer B: Canonical Git Repository & Codebase Identity Check
           - Layer C: Source Code AST & Dependency Structure Analysis
        """
        logger.info(f"Running Plagiarism & Duplication scan for project '{title}' (ID: {project_id})...")

        # 1. Internet Plagiarism Scan via Gemini (with citation exclusion)
        internet_res = await gemini_service.check_internet_plagiarism(
            title=title,
            abstract=abstract,
            document_text=document_text,
            repository_url=repository_url
        )
        plagiarism_score = float(internet_res.get("plagiarism_score", 0.0))
        plagiarism_verdict = internet_res.get("plagiarism_verdict", "CLEAN")
        valid_citations = internet_res.get("valid_citations_detected", [])
        uncited_matches = internet_res.get("uncited_matches", [])

        # 2. Multi-Modal Duplication Scan against ProjectVault DB
        matched_archived = []
        max_composite_sim = 0.0
        max_text_sim = 0.0
        max_code_sim = 0.0
        repo_duplicate_found = False

        try:
            # Generate vector embedding for submitted text content
            query_emb = embedding_service.generate_project_embedding(
                title=title,
                abstract=abstract
            )

            with get_db_connection() as conn:
                with conn.cursor(cursor_factory=RealDictCursor) as cur:
                    # Query existing projects across ALL lifecycle states (Submitted, Under Review, Approved, Archived, and Drafts with repos)
                    query = """
                        SELECT 
                            p.id, p.title, p.abstract, p.status, p.repository_url, p.created_at,
                            d.name as department_name,
                            u.email as author_email,
                            pe.embedding_vector,
                            ai.tech_stack
                        FROM projects p
                        LEFT JOIN departments d ON p.department_id = d.id
                        LEFT JOIN users u ON p.created_by_user_id = u.id
                        LEFT JOIN project_embeddings pe ON p.id = pe.project_id
                        LEFT JOIN ai_analyses ai ON p.id = ai.project_id
                        WHERE (p.status IN ('SUBMITTED', 'UNDER_REVIEW', 'APPROVED', 'ARCHIVED') 
                               OR (p.status = 'DRAFT' AND p.repository_url IS NOT NULL))
                          AND (%s IS NULL OR p.id != %s);
                    """
                    cur.execute(query, (project_id, project_id))
                    rows = cur.fetchall()

                    for r in rows:
                        other_id = r["id"]
                        other_title = r["title"]
                        other_status = r["status"]
                        other_repo = r.get("repository_url")
                        other_tech = r.get("tech_stack") or []
                        dept_name = r.get("department_name") or "Computer Applications"
                        emb = r.get("embedding_vector")

                        # Layer A: Text Vector Similarity
                        text_sim = 0.0
                        if emb is not None:
                            if isinstance(emb, str):
                                cleaned = emb.strip("[]{}").split(",")
                                emb = [float(x) for x in cleaned if x.strip()]
                            text_sim = float(embedding_service.cosine_similarity(query_emb, list(emb)))
                        else:
                            words1 = set(f"{title} {abstract}".lower().split())
                            words2 = set(f"{other_title} {r['abstract']}".lower().split())
                            intersection = words1.intersection(words2)
                            text_sim = float(len(intersection) / max(len(words1), 1))

                        if text_sim > max_text_sim:
                            max_text_sim = text_sim

                        # Layer B: Canonical Git Repository Exact / Fork Match
                        is_same_repo = code_similarity_service.check_repo_exact_match(repository_url, other_repo)
                        repo_sim = 1.0 if is_same_repo else 0.0
                        if is_same_repo:
                            repo_duplicate_found = True
                            logger.warning(f"Project '{title}' shares identical repository URL with Project #{other_id} ({other_repo})")

                        # Layer C: Code AST / Dependency Structure Check
                        code_sim = 0.0
                        if document_text and len(document_text) > 50:
                            # Compare code fragments if present in document text
                            code_sim = code_similarity_service.compare_code_snippets(
                                document_text,
                                r.get("abstract", "")
                            )
                        if code_sim > max_code_sim:
                            max_code_sim = code_sim

                        # Layer D: Composite Multi-Modal Similarity
                        composite_sim = max(text_sim, repo_sim, code_sim)
                        if composite_sim > max_composite_sim:
                            max_composite_sim = composite_sim

                        # If similarity is significant, record candidate with detailed diagnostic summary
                        if composite_sim >= 0.25:
                            if is_same_repo:
                                summary = f"CRITICAL: 100% Identical Git Codebase Repository ({other_repo})"
                            elif code_sim >= 0.70:
                                summary = f"CRITICAL: Structural Code AST Logic Clone ({round(code_sim * 100, 1)}%) with Project #{other_id}"
                            elif text_sim >= 0.50:
                                summary = f"High Conceptual & Abstract Text Overlap ({round(text_sim * 100, 1)}%) with Project #{other_id}"
                            else:
                                summary = f"Moderate Topic Overlap ({round(text_sim * 100, 1)}%) with Project #{other_id}"

                            matched_archived.append({
                                "project_id": other_id,
                                "title": other_title,
                                "similarity_score": round(float(composite_sim), 4),
                                "text_similarity": round(float(text_sim), 4),
                                "repo_match": is_same_repo,
                                "status": other_status,
                                "department_name": dept_name,
                                "similarity_summary": summary
                            })

            matched_archived.sort(key=lambda x: x["similarity_score"], reverse=True)
            matched_archived = matched_archived[:5]

        except Exception as e:
            logger.error(f"Error during archive duplication search: {e}")

        # Duplication score: scaled from 0.0 to 100.0
        duplication_score = round(max(0.0, min(100.0, max_composite_sim * 100.0)), 1)
        if duplication_score >= 75.0 or repo_duplicate_found:
            duplication_verdict = "HIGH_DUPLICATE"
        elif duplication_score >= 40.0:
            duplication_verdict = "PARTIAL_DUPLICATE"
        else:
            duplication_verdict = "UNIQUE"

        # Build comprehensive report detail
        report_detail = {
            "plagiarism_score": plagiarism_score,
            "plagiarism_verdict": plagiarism_verdict,
            "duplication_score": duplication_score,
            "duplication_verdict": duplication_verdict,
            "text_similarity_score": round(max_text_sim * 100.0, 1),
            "code_similarity_score": round(max_code_sim * 100.0, 1),
            "repo_duplicate_detected": repo_duplicate_found,
            "internet_sources_detected": internet_res.get("internet_sources_detected", []),
            "valid_citations_detected": valid_citations,
            "uncited_matches": uncited_matches,
            "matched_archived_projects": matched_archived,
            "summary_explanation": internet_res.get("summary_explanation", "Analysis completed."),
            "recommendation_for_faculty": (
                "CRITICAL WARNING: Identical codebase or repository clone detected with an existing project. Reject or require substantial refactoring."
                if repo_duplicate_found or duplication_score >= 80.0
                else internet_res.get("recommendation_for_faculty", "Verify citations and technical implementation.")
            )
        }

        is_persisted = False
        if save_to_db and project_id:
            try:
                import json
                with get_db_connection() as conn:
                    with conn.cursor() as cur:
                        update_sql = """
                            UPDATE projects 
                            SET plagiarism_score = %s,
                                duplication_score = %s,
                                plagiarism_report = %s,
                                plagiarism_status = 'COMPLETED',
                                updated_at = CURRENT_TIMESTAMP
                            WHERE id = %s;
                        """
                        cur.execute(update_sql, (
                            plagiarism_score,
                            duplication_score,
                            json.dumps(report_detail),
                            project_id
                        ))
                        conn.commit()
                        is_persisted = True
                        logger.info(f"Updated project #{project_id} with Plagiarism ({plagiarism_score}%) & Duplication ({duplication_score}%)")
            except Exception as e:
                logger.error(f"Failed to persist plagiarism results for project #{project_id}: {e}")

        return {
            "project_id": project_id,
            "plagiarism_score": plagiarism_score,
            "duplication_score": duplication_score,
            "report": report_detail,
            "ai_status": internet_res.get("ai_status", "COMPLETED"),
            "is_persisted": is_persisted
        }

analysis_service = AnalysisService()

