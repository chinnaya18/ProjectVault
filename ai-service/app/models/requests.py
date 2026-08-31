from typing import Optional, List, Dict, Any
from pydantic import BaseModel, Field

class SemanticSearchRequest(BaseModel):
    query: str = Field(..., min_length=1, description="Natural language search query")
    limit: Optional[int] = Field(5, ge=1, le=50, description="Max number of ranked results")
    threshold: Optional[float] = Field(0.20, ge=0.0, le=1.0, description="Minimum cosine similarity threshold")
    department_id: Optional[int] = Field(None, description="Optional department filter")
    academic_year: Optional[str] = Field(None, description="Optional academic year filter")
    project_type: Optional[str] = Field(None, description="Optional project type filter")

class AskQuestionRequest(BaseModel):
    question: str = Field(..., min_length=1, description="User question about ProjectVault projects")
    limit: Optional[int] = Field(5, ge=1, le=15, description="Max relevant projects to retrieve for context")
    project_id: Optional[int] = Field(None, description="Optional specific project ID to scope the question to")
    department_id: Optional[int] = Field(None, description="Optional department filter")
    conversation_context: Optional[List[Dict[str, str]]] = Field(
        None, 
        description="Optional list of prior turns [{'role': 'user'|'model', 'content': '...'}]"
    )

class AnalyzeProjectRequest(BaseModel):
    title: str = Field(..., min_length=2, description="Project title")
    abstract: str = Field(..., min_length=5, description="Project abstract or description")
    tech_stack: Optional[List[str]] = Field(default_factory=list, description="Known tech stack tags")
    domain: Optional[str] = Field(None, description="Known domain")
    keywords: Optional[List[str]] = Field(default_factory=list, description="Known keywords")
    project_id: Optional[int] = Field(None, description="Project ID if already registered in database")
    document_text: Optional[str] = Field(None, description="Optional extended document text from uploaded file")
    save_to_db: Optional[bool] = Field(False, description="Whether to persist the generated analysis to database")

class EmbedRequest(BaseModel):
    text: str = Field(..., min_length=1, description="Input text to generate embedding for")
    normalize: Optional[bool] = Field(True, description="Whether to L2-normalize the output vector")

class SyncEmbeddingsRequest(BaseModel):
    force_refresh: Optional[bool] = Field(False, description="Re-generate embeddings even if already existing")
    project_id: Optional[int] = Field(None, description="Optional single project ID to sync/refresh")
