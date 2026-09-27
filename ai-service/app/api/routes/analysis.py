import logging
from fastapi import APIRouter, HTTPException, status
from app.models.requests import AnalyzeProjectRequest, PlagiarismCheckRequest
from app.models.responses import AnalyzeProjectResponse, PlagiarismCheckResponse
from app.services.analysis_service import analysis_service

logger = logging.getLogger("ai_service.routes.analysis")

router = APIRouter(tags=["Project Content Analysis"])

@router.post(
    "/analyze",
    response_model=AnalyzeProjectResponse,
    summary="Analyze Project Content & Extract Metadata",
    description="Uses Gemini to extract structured summary, domain classification, tech stack, and keywords from project abstract and artifacts."
)
async def analyze_project(req: AnalyzeProjectRequest) -> AnalyzeProjectResponse:
    if not req.title or not req.title.strip():
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Project title is required for analysis."
        )
    if not req.abstract or not req.abstract.strip():
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Project abstract is required for analysis."
        )

    try:
        response = await analysis_service.analyze_project(req)
        return response
    except Exception as e:
        logger.error(f"Project analysis failed: {e}", exc_info=True)
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Analysis error: {str(e)}"
        )

@router.post(
    "/plagiarism-check",
    response_model=PlagiarismCheckResponse,
    summary="Analyze Plagiarism (Internet & Citations) and Duplication (Archived Projects)",
    description="Evaluates project draft against internet sources (excluding valid citations) and against existing archived projects."
)
async def check_plagiarism(req: PlagiarismCheckRequest) -> PlagiarismCheckResponse:
    if not req.title or not req.title.strip():
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Project title is required for plagiarism scan."
        )
    if not req.abstract or not req.abstract.strip():
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Project abstract is required for plagiarism scan."
        )

    try:
        res = await analysis_service.analyze_plagiarism_and_duplication(
            project_id=req.project_id,
            title=req.title,
            abstract=req.abstract,
            document_text=req.document_text,
            repository_url=req.repository_url,
            save_to_db=req.save_to_db if req.save_to_db is not None else True
        )
        return PlagiarismCheckResponse(**res)
    except Exception as e:
        logger.error(f"Plagiarism check failed: {e}", exc_info=True)
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Plagiarism evaluation error: {str(e)}"
        )

