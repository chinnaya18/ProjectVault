import logging
from fastapi import APIRouter, HTTPException, status
from app.models.requests import AnalyzeProjectRequest
from app.models.responses import AnalyzeProjectResponse
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
