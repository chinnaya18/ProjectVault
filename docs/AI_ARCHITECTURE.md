# ProjectVault — AI Architecture & NLP Pipeline Specification

**Document Version:** 1.0.0  
**Date:** August 2026  
**Status:** Approved AI Architecture Specification (Phase 1)

---

## 1. System Overview & Core Philosophy

The AI layer in ProjectVault is strictly decoupled from the main Spring Boot business backend and operates as an independent Python FastAPI microservice.

### Key Separation of Responsibilities
1. **Google Gemini API (`gemini-1.5-flash`):** Responsible exclusively for **Generative Metadata Analysis** (summarization, domain classification, keyword extraction, tech stack identification, problem statement extraction).
2. **SentenceTransformers (`all-MiniLM-L6-v2`):** Responsible exclusively for **384-dimensional Dense Vector Embedding Computation** (used for semantic similarity search, related project recommendations, and similarity scoring).
3. **PostgreSQL + `pgvector`:** Responsible exclusively for **Vector Storage and Similarity Indexing** using HNSW cosine distance (`<=>`).

```
+-------------------------------------------------------------------------------+
|                             FASTAPI AI SERVICE                                |
|                                                                               |
|  +---------------------+    +----------------------+    +------------------+  |
|  | Text Extractor      |    | AIService Provider   |    | SentenceXformer  |  |
|  | (PyPDF/Docx/PPTX)   |    | (Gemini Provider)    |    | (all-MiniLM-L6)  |  |
|  +----------┬----------+    +----------┬-----------+    +--------┬---------+  |
+-------------│--------------------------│-------------------------│------------+
              │                          │                         │
              v                          v                         v
     Raw File Text Payload       Google Gemini API         384-Float Vector
                              (Generative Structured    (pgvector Indexing &
                                 JSON Metadata)              Search)
```

---

## 2. Ingestion & Extraction Workflows

### 2.1 Multi-Format Document Parsing Engine
The FastAPI service ingests uploaded academic files and converts them into standardized, clean text streams:
* **PDF Artifacts:** Processed using `pypdf` / `pdfplumber` with header/footer strip rules.
* **Word Documents (`.docx`):** Processed using `python-docx` extracting paragraph blocks and structural tables.
* **PowerPoint Presentations (`.pptx`):** Processed using `python-pptx` extracting slide notes and text shapes.

### 2.2 Text Normalization Pipeline
1. **Sanitization:** Removes control characters, invalid UTF-8 sequences, and excessive whitespace.
2. **Structural Chunking:** Truncates extremely long documents (retaining first 10,000 words covering Abstract, Introduction, System Design, and Conclusion) to maximize LLM context efficiency and stay comfortably within Gemini rate limits.

---

## 3. Generative Metadata Pipeline (Google Gemini API)

### 3.1 LLM Abstraction & Provider Pattern
The FastAPI AI service defines an abstract `AIService` interface with a concrete `GeminiProvider` implementation.

```python
class AIServiceProvider(ABC):
    @abstractmethod
    async def analyze_document(self, text_content: str) -> AIAnalysisResult:
        pass
```

### 3.2 Structured Output Schema (Pydantic v2)
Gemini is prompted using strict JSON Schema enforcement:

```json
{
  "summary": "3-5 sentence academic summary of the project",
  "domain": "Primary Domain (e.g., Computer Vision, Distributed Systems, NLP, Cybersecurity)",
  "sub_domains": ["Deep Learning", "Agricultural Technology"],
  "extracted_keywords": ["CNN", "Leaf Disease", "ResNet50", "Precision Agriculture"],
  "tech_stack": ["Python", "TensorFlow", "React", "FastAPI"],
  "problem_statement": "Automating real-time identification of crop leaf pathogens to prevent yield loss."
}
```

### 3.3 Prompt Engineering Strategy
Prompts explicitly instruct Gemini to act as a senior academic reviewer, extracting factual methodology from the document while eliminating conversational fluff.

---

## 4. Semantic Embedding & Vector Search Architecture

### 4.1 SentenceTransformers Model (`all-MiniLM-L6-v2`)
* **Model Name:** `sentence-transformers/all-MiniLM-L6-v2`
* **Output Dimensions:** 384 dense floating-point values.
* **Properties:** Optimized for sentence-level semantic similarity, low memory footprint (~90MB), ultra-fast inference (< 25ms on CPU).
* **Execution:** Sentence Transformers model runs locally inside the FastAPI service memory space without requiring GPU hardware for initial deployments of 30 to 300+ projects.

### 4.2 Query Embedding Flow vs Ingestion Embedding Flow
* **Ingestion Flow (Async):** Triggered upon project submission. Document text is converted to a 384-float array vector and stored in `project_embeddings.embedding_vector`.
* **Search Query Flow (Real-time):** When a user enters a search query string (e.g., *"machine learning for plant leaf disease"*), the query string is sent to `/api/v1/ai/embed`, producing a query vector in ~20ms, which is then passed to PostgreSQL `pgvector`.

---

## 5. Internet Resiliency & Offline Fallback Strategy

ProjectVault is designed to operate seamlessly inside a college intranet even during external Internet outages:

```
                          FASTAPI INTERNET RESILIENCY
                                       │
                        Is Gemini API Reachable?
                                       │
                     ┌─────────────────┴─────────────────┐
                     │ YES                               │ NO / Timeout
                     v                                   v
             [GeminiProvider]                  [Local Heuristic NLP]
         Full AI Extraction                Extract Basic Keywords & Tech
                 │                                       │
                 └─────────────────┬─────────────────────┘
                                   │
                                   v
                      [SentenceTransformers]
               Generates 384-dim Vector (Local CPU)
                                   │
                                   v
                      Saved to PostgreSQL + pgvector
```

1. **Local Vector Generation:** SentenceTransformers runs 100% locally. Embedding generation and vector search DO NOT depend on external Internet connectivity.
2. **Graceful Fallback:** If Gemini API calls fail or time out (due to lack of Internet or API rate limits), the AI analysis record status is set to `PENDING_RETRY`. A local rule-based heuristic extractor extracts basic keywords and tech tags from text so ingestion is never blocked.
3. **Re-indexing Endpoint:** Faculty or Admins can trigger `POST /api/v1/ai/reindex/{projectId}` at any time to re-run Gemini analysis once Internet connection is restored.

---
*End of AI Architecture & NLP Pipeline Specification.*
