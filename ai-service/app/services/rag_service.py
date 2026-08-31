import time
import logging
from typing import Optional, List, Dict, Any

from app.models.requests import AskQuestionRequest
from app.models.responses import AskQuestionResponse, ProjectCitation
from app.services.embedding_service import embedding_service
from app.services.vector_service import vector_service
from app.services.gemini_service import gemini_service

logger = logging.getLogger("ai_service.rag")

class RagService:

    async def answer_question(self, req: AskQuestionRequest) -> AskQuestionResponse:
        """
        Execute full RAG question answering pipeline:
        1. Receive question
        2. Generate question embedding
        3. Retrieve relevant projects from pgvector
        4. Construct strict ProjectVault context
        5. Invoke Gemini with grounded prompt
        6. Return validated grounded answer
        """
        start_time = time.time()
        question = req.question.strip()
        limit = req.limit or 5
        
        logger.info(f"Received RAG question: '{question}' (limit={limit}, project_id={req.project_id})")

        retrieved_projects = []
        citations: List[ProjectCitation] = []

        # If user targeted a specific project ID
        if req.project_id:
            target_proj = vector_service.get_project_by_id(req.project_id)
            if target_proj:
                retrieved_projects.append(target_proj)
                citations.append(ProjectCitation(
                    id=target_proj["id"],
                    title=target_proj["title"],
                    similarity_score=1.0,
                    domain=target_proj.get("ai_domain"),
                    tech_stack=target_proj.get("ai_tech_stack") or []
                ))

        # Perform semantic vector retrieval
        query_vector = embedding_service.generate_embedding(question)
        search_results = vector_service.search_similar_projects(
            query_vector=query_vector,
            limit=limit,
            threshold=0.15,
            department_id=req.department_id
        )

        for res in search_results:
            # Avoid duplicate if already added via specific project_id
            if not any(p.get("id") == res.id for p in retrieved_projects):
                retrieved_projects.append({
                    "id": res.id,
                    "title": res.title,
                    "abstract": res.abstract,
                    "department_name": res.department_name,
                    "author_name": res.author_name,
                    "academic_year": res.academic_year,
                    "semester": res.semester,
                    "domain": res.domain,
                    "tech_stack": res.tech_stack,
                    "similarity_score": res.similarity_score
                })
                citations.append(ProjectCitation(
                    id=res.id,
                    title=res.title,
                    similarity_score=res.similarity_score,
                    domain=res.domain,
                    tech_stack=res.tech_stack
                ))

        # Build Context String
        if not retrieved_projects:
            context_str = "No matching projects found in the ProjectVault database."
            confidence = "INSUFFICIENT_CONTEXT"
        else:
            context_blocks = []
            for p in retrieved_projects:
                tech = ", ".join(p.get("tech_stack") or []) or "Not specified"
                domain = p.get("domain") or "General"
                score = p.get("similarity_score", 1.0)
                block = (
                    f"Project ID: {p.get('id')}\n"
                    f"Title: {p.get('title')}\n"
                    f"Author: {p.get('author_name', 'Student Contributor')}\n"
                    f"Department: {p.get('department_name', 'MCA')}\n"
                    f"Academic Year: {p.get('academic_year')} (Semester {p.get('semester')})\n"
                    f"Domain: {domain}\n"
                    f"Technologies: {tech}\n"
                    f"Abstract: {p.get('abstract')}\n"
                    f"Relevance Score: {score:.3f}"
                )
                context_blocks.append(block)
            
            context_str = "\n\n".join(context_blocks)
            max_score = max([p.get("similarity_score", 0.0) for p in retrieved_projects])
            if max_score >= 0.5:
                confidence = "HIGH"
            elif max_score >= 0.3:
                confidence = "MEDIUM"
            else:
                confidence = "LOW"

        # Generate Grounded LLM Response
        if not retrieved_projects:
            answer = (
                "Based on the current ProjectVault repository, no projects were found matching your query. "
                "Try searching for other domains such as 'machine learning', 'IoT', or 'blockchain'."
            )
        else:
            answer = await gemini_service.generate_grounded_answer(
                question=question,
                context=context_str,
                conversation_history=req.conversation_context
            )

        execution_time = round((time.time() - start_time) * 1000, 2)
        logger.info(f"RAG question answered in {execution_time}ms with {len(citations)} citations.")

        return AskQuestionResponse(
            question=question,
            answer=answer,
            grounded=len(retrieved_projects) > 0,
            referenced_projects=citations,
            retrieved_count=len(retrieved_projects),
            confidence=confidence,
            execution_time_ms=execution_time
        )

rag_service = RagService()
