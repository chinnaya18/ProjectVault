from typing import Optional, List, Dict, Any
from pydantic import BaseModel, Field

class ProjectSearchResult(BaseModel):
    id: int = Field(..., description="Project ID")
    title: str = Field(..., description="Project Title")
    abstract: str = Field(..., description="Project Abstract")
    academic_year: str = Field(..., description="Academic Year e.g. 2025-2026")
    semester: int = Field(..., description="Semester")
    project_type: str = Field(..., description="Project Type")
    status: str = Field(..., description="Lifecycle Status")
    visibility: str = Field(..., description="Visibility")
    department_id: int = Field(..., description="Department ID")
    department_name: Optional[str] = Field(None, description="Department Name")
    author_name: Optional[str] = Field(None, description="Author / Creator Name")
    similarity_score: float = Field(..., description="Cosine Similarity score (0.0 to 1.0)")
    domain: Optional[str] = Field(None, description="AI Classified Domain")
    tech_stack: List[str] = Field(default_factory=list, description="Extracted / Tagged Tech Stack")
    keywords: List[str] = Field(default_factory=list, description="Extracted / Tagged Keywords")
    repository_url: Optional[str] = Field(None, description="Repository URL if available")

class SemanticSearchResponse(BaseModel):
    query: str
    total_results: int
    results: List[ProjectSearchResult]
    execution_time_ms: float
    topic_feedback: Optional[Dict[str, Any]] = Field(None, description="AI topic viability analysis and recommendations if query is novel or sparse")

class ProjectCitation(BaseModel):
    id: int
    title: str
    similarity_score: float
    domain: Optional[str] = None
    tech_stack: List[str] = Field(default_factory=list)

class AskQuestionResponse(BaseModel):
    question: str
    answer: str
    grounded: bool = Field(True, description="Whether the answer is grounded in retrieved ProjectVault projects")
    referenced_projects: List[ProjectCitation]
    retrieved_count: int
    confidence: str = Field("HIGH", description="Confidence assessment (HIGH, MEDIUM, LOW, INSUFFICIENT_CONTEXT)")
    execution_time_ms: float

class AnalyzeProjectResponse(BaseModel):
    project_id: Optional[int] = None
    summary: str
    domain: str
    sub_domains: List[str] = Field(default_factory=list)
    tech_stack: List[str] = Field(default_factory=list)
    extracted_keywords: List[str] = Field(default_factory=list)
    problem_statement: str
    ai_status: str = Field("COMPLETED", description="Status: COMPLETED, HEURISTIC_FALLBACK, or FAILED")
    is_persisted: bool = Field(False, description="Whether saved to database ai_analyses table")

class EmbedResponse(BaseModel):
    embedding: List[float]
    dimension: int
    model: str

class SyncEmbeddingsResponse(BaseModel):
    total_processed: int
    generated_count: int
    updated_count: int
    skipped_count: int
    errors: List[str] = Field(default_factory=list)
    message: str

class HealthResponse(BaseModel):
    status: str
    service: str
    version: str
    embedding_model: str
    embedding_dimension: int
    gemini_configured: bool
    gemini_model: str
    database: Dict[str, Any]

class MatchedArchivedProject(BaseModel):
    project_id: int
    title: str
    similarity_score: float
    status: str
    department_name: Optional[str] = None
    similarity_summary: Optional[str] = None

class PlagiarismReportDetail(BaseModel):
    plagiarism_score: float = Field(..., description="Plagiarism score percentage (0-100)")
    plagiarism_verdict: str = Field(..., description="Verdict e.g. CLEAN, MODERATE_PLAGIARISM, SEVERE_PLAGIARISM")
    duplication_score: float = Field(..., description="Duplication score percentage against archived projects (0-100)")
    duplication_verdict: str = Field(..., description="Verdict e.g. UNIQUE, PARTIAL_DUPLICATE, HIGH_DUPLICATE")
    internet_sources_detected: List[Dict[str, Any]] = Field(default_factory=list)
    valid_citations_detected: List[Dict[str, Any]] = Field(default_factory=list, description="Citations found that were properly attributed and excluded from plagiarism")
    uncited_matches: List[str] = Field(default_factory=list, description="Uncited text fragments or claims")
    matched_archived_projects: List[MatchedArchivedProject] = Field(default_factory=list)
    summary_explanation: str
    recommendation_for_faculty: str

class PlagiarismCheckResponse(BaseModel):
    project_id: Optional[int] = None
    plagiarism_score: float
    duplication_score: float
    report: PlagiarismReportDetail
    ai_status: str = Field("COMPLETED", description="COMPLETED, HEURISTIC_FALLBACK, or FAILED")
    is_persisted: bool = False

