import logging
from fastapi import APIRouter, HTTPException, status
from app.models.requests import AskQuestionRequest
from app.models.responses import AskQuestionResponse
from app.services.rag_service import rag_service

logger = logging.getLogger("ai_service.routes.chat")

router = APIRouter(tags=["RAG Question Answering"])

@router.post(
    "/ask",
    response_model=AskQuestionResponse,
    summary="RAG Natural Language Project Q&A",
    description="Retrieves relevant ProjectVault projects and uses Google Gemini to generate grounded, fact-checked answers."
)
async def ask_question(req: AskQuestionRequest) -> AskQuestionResponse:
    if not req.question or not req.question.strip():
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Question string cannot be empty."
        )

    try:
        response = await rag_service.answer_question(req)
        return response
    except Exception as e:
        logger.error(f"RAG question answering failed: {e}", exc_info=True)
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"RAG QA error: {str(e)}"
        )

@router.post(
    "/chat",
    response_model=AskQuestionResponse,
    summary="RAG Chat Endpoint (Alias for /ask)",
    description="Alias endpoint for conversational project exploration."
)
async def chat_question(req: AskQuestionRequest) -> AskQuestionResponse:
    return await ask_question(req)
