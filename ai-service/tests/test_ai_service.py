import os
import sys
import pytest

sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), "..")))

from app.core.config import settings

from app.services.embedding_service import embedding_service
from app.services.vector_service import vector_service
from app.services.gemini_service import gemini_service
from app.services.rag_service import rag_service
from app.models.requests import AskQuestionRequest, AnalyzeProjectRequest

def test_config():
    """Verify settings configuration."""
    assert settings.PROJECT_NAME == "ProjectVault AI Microservice"
    assert settings.EMBEDDING_DIMENSION == 384
    assert settings.API_V1_STR == "/api/v1/ai"

def test_embedding_generation():
    """Verify SentenceTransformer model loads and outputs 384-dim vector."""
    text = "Machine learning models for plant pathogen detection using ResNet50."
    vector = embedding_service.generate_embedding(text, normalize=True)
    assert isinstance(vector, list)
    assert len(vector) == 384
    # Check that vector is non-zero
    assert sum(abs(x) for x in vector) > 0.0

def test_project_text_builder():
    """Verify standardized text representation format."""
    p_text = embedding_service.build_project_text(
        title="IoT Smart Parking",
        abstract="Smart parking sensor network using MQTT.",
        tech_stack=["IoT", "MQTT", "Python"],
        domain="Smart Cities",
        keywords=["Sensors", "Parking"]
    )
    assert "Title: IoT Smart Parking" in p_text
    assert "Abstract: Smart parking sensor network using MQTT." in p_text
    assert "Technologies: IoT, MQTT, Python" in p_text
    assert "Domain: Smart Cities" in p_text
    assert "Keywords: Sensors, Parking" in p_text

def test_cosine_similarity():
    """Verify cosine similarity calculation."""
    v1 = [1.0, 0.0, 0.0]
    v2 = [1.0, 0.0, 0.0]
    v3 = [0.0, 1.0, 0.0]
    assert abs(embedding_service.cosine_similarity(v1, v2) - 1.0) < 1e-5
    assert abs(embedding_service.cosine_similarity(v1, v3) - 0.0) < 1e-5

@pytest.mark.asyncio
async def test_heuristic_analysis():
    """Verify heuristic project content analyzer fallback."""
    req = AnalyzeProjectRequest(
        title="Crop Leaf Disease Identification via Convolutional Neural Networks",
        abstract="A deep learning vision pipeline using CNNs and ResNet50 to detect leaf blight in agricultural crops.",
        tech_stack=["Python", "TensorFlow", "ResNet50"]
    )
    res = gemini_service._heuristic_analysis(req.title, req.abstract)
    assert "Deep Learning" in res["domain"] or "Computer Vision" in res["domain"]
    assert "Python" in res["tech_stack"] or "TensorFlow" in res["tech_stack"]
    assert res["ai_status"] == "HEURISTIC_FALLBACK"

@pytest.mark.asyncio
async def test_rag_pipeline_empty_handling():
    """Verify RAG response when no matching projects are retrieved."""
    req = AskQuestionRequest(
        question="What projects relate to Martian terraforming aerospace mechanics?",
        limit=3
    )
    res = await rag_service.answer_question(req)
    assert res.question == req.question
    assert isinstance(res.answer, str)
    assert res.confidence in ["HIGH", "MEDIUM", "LOW", "INSUFFICIENT_CONTEXT"]
