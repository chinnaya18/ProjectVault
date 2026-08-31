# ProjectVault — AI Microservice

The **AI Intelligence Microservice** for **ProjectVault** (Academic Project Repository and Knowledge Preservation Platform). Built as an independent Python FastAPI microservice providing dense vector embeddings, pgvector semantic search, grounded Retrieval-Augmented Generation (RAG), and generative project analysis.

---

## 1. System Architecture

```
User / React Frontend
         │
         ▼
Spring Boot Backend (Port 8080)
         │
         ▼
FastAPI AI Service (Port 8000)
    ├── 1. SentenceTransformers (all-MiniLM-L6-v2) ──> 384-dim Dense Embeddings
    ├── 2. PostgreSQL + pgvector ─────────────────────> Vector Cosine Similarity Search
    ├── 3. Retrieval-Augmented Generation (RAG) ──────> Grounded Project Context Assembly
    └── 4. Google Gemini API (gemini-1.5-flash) ──────> Fact-Grounded Answers & Analysis
```

---

## 2. Technology Stack

* **Framework:** Python 3.10+ / FastAPI / Uvicorn
* **Dense Embeddings:** `sentence-transformers/all-MiniLM-L6-v2` (384 dimensions, normalized)
* **Vector Database:** PostgreSQL 15+ with `pgvector` (HNSW indexing & cosine distance `<=>`)
* **Large Language Model:** Google Gemini API (`gemini-1.5-flash`)
* **Validation & Settings:** Pydantic v2 & `pydantic-settings`
* **Driver:** `psycopg2-binary` with connection pooling

---

## 3. Core Features

### 1. Embedding Service (`SentenceTransformers`)
- Model loaded **once at startup** into application memory.
- Builds structured project representations:
  ```
  Title: {title}
  Abstract: {abstract}
  Domain: {domain}
  Technologies: {technologies}
  Keywords: {keywords}
  ```
- Normalizes vectors via L2 norm for standard cosine similarity.

### 2. Semantic Project Search (`pgvector`)
- Translates natural language queries (e.g., *"machine learning for plant disease"*) into dense vector embeddings.
- Executes vector similarity queries against `project_embeddings` using cosine distance.
- Filters by lifecycle status (`APPROVED`), visibility (`PUBLIC`), department, and academic year.
- Returns ranked results with similarity scores and technical metadata.

### 3. RAG-Based AI Assistant
- Two-stage pipeline:
  1. **Dense Retrieval:** Retrieves the top-$K$ most relevant ProjectVault projects via pgvector.
  2. **Grounded Generation:** Formats retrieved project metadata into strict context and prompts Gemini to produce fact-checked answers without hallucination.
- Cites specific Project IDs and titles in responses.

### 4. Structured Project Content Analysis
- Analyzes title, abstract, and uploaded document text.
- Extracts structured academic metadata:
  - 3-sentence summary
  - Academic domain & sub-domains
  - Key technologies
  - Keywords & tags
  - Problem statement
- Features heuristic rule-based fallback when Gemini API key is not configured or during internet downtime.

### 5. Embedding Management & Synchronization
- Syncs and generates embeddings for newly registered or updated projects in PostgreSQL.
- Safe bulk synchronization endpoint (`POST /api/v1/ai/sync-embeddings`).

---

## 4. Setup & Installation

### Prerequisites
- Python 3.10+ installed
- PostgreSQL 15+ running (with `projectvault` database initialized)

### 1. Install Dependencies
```bash
cd ai-service
pip install -r requirements.txt
```

### 2. Configure Environment Variables
Copy `.env.example` to `.env` and fill in your settings:
```bash
cp .env.example .env
```

`.env` configuration keys:
```env
# Database Settings
DB_HOST=localhost
DB_PORT=5432
DB_NAME=projectvault
DB_USER=postgres
DB_PASSWORD=your_password

# Google Gemini API
GEMINI_API_KEY=your_google_gemini_api_key_here
GEMINI_MODEL=gemini-1.5-flash

# Sentence Transformer Model
EMBEDDING_MODEL_NAME=sentence-transformers/all-MiniLM-L6-v2
EMBEDDING_DIMENSION=384

# Vector Search Parameters
SIMILARITY_THRESHOLD=0.20
DEFAULT_SEARCH_LIMIT=5

# Server Port
AI_SERVICE_HOST=0.0.0.0
AI_SERVICE_PORT=8000
```

---

## 5. Running the AI Service

### Development Mode:
```bash
uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload
```

### Direct Python Execution:
```bash
python -m app.main
```

The interactive OpenAPI / Swagger documentation will be available at:
`http://localhost:8000/docs`

---

## 6. API Endpoints

### 1. Health Check
* **Endpoint:** `GET /health`
* **Response Example:**
```json
{
  "status": "UP",
  "service": "ProjectVault AI Microservice",
  "version": "1.0.0",
  "embedding_model": "sentence-transformers/all-MiniLM-L6-v2",
  "embedding_dimension": 384,
  "gemini_configured": true,
  "gemini_model": "gemini-1.5-flash",
  "database": {
    "connected": true,
    "total_projects": 5,
    "total_embeddings": 5,
    "pgvector_active": true
  }
}
```

### 2. Semantic Search
* **Endpoint:** `POST /api/v1/ai/search`
* **Request:**
```json
{
  "query": "deep learning for agriculture and crop disease",
  "limit": 5,
  "threshold": 0.20
}
```
* **Response:**
```json
{
  "query": "deep learning for agriculture and crop disease",
  "total_results": 1,
  "results": [
    {
      "id": 1,
      "title": "Crop Disease Detection Using Convolutional Neural Networks",
      "abstract": "An automated deep learning system to identify plant pathogens from leaf imagery using ResNet50.",
      "academic_year": "2024-2025",
      "semester": 4,
      "project_type": "Major Project",
      "status": "APPROVED",
      "visibility": "PUBLIC",
      "department_id": 1,
      "department_name": "Master of Computer Applications",
      "author_name": "Gayathri Faculty",
      "similarity_score": 0.684,
      "domain": "Computer Vision",
      "tech_stack": ["Python", "TensorFlow", "ResNet50"],
      "keywords": ["CNN", "Leaf Disease", "ResNet50"]
    }
  ],
  "execution_time_ms": 42.15
}
```

### 3. RAG Project Question Answering
* **Endpoint:** `POST /api/v1/ai/ask`
* **Request:**
```json
{
  "question": "What projects are available related to IoT and smart parking?",
  "limit": 5
}
```
* **Response:**
```json
{
  "question": "What projects are available related to IoT and smart parking?",
  "answer": "ProjectVault includes Project #2 titled 'Smart Campus Parking Management via IoT Sensors'. This project implements real-time parking spot occupancy tracking using ultrasonic sensors and an MQTT broker.",
  "grounded": true,
  "referenced_projects": [
    {
      "id": 2,
      "title": "Smart Campus Parking Management via IoT Sensors",
      "similarity_score": 0.712,
      "domain": "Internet of Things",
      "tech_stack": ["IoT", "MQTT", "Python"]
    }
  ],
  "retrieved_count": 1,
  "confidence": "HIGH",
  "execution_time_ms": 1150.32
}
```

### 4. Project Content Analysis
* **Endpoint:** `POST /api/v1/ai/analyze`
* **Request:**
```json
{
  "title": "Decentralized Academic Credential Verification Platform",
  "abstract": "A blockchain-based system using Ethereum smart contracts to issue and verify tamper-proof university diplomas and transcripts.",
  "save_to_db": false
}
```
* **Response:**
```json
{
  "summary": "This project implements a decentralized platform for issuing and verifying university academic credentials using Ethereum smart contracts.",
  "domain": "Blockchain & Distributed Ledgers",
  "sub_domains": ["Smart Contracts", "Decentralized Identity"],
  "tech_stack": ["Solidity", "Ethereum", "Web3.js", "React"],
  "extracted_keywords": ["Blockchain", "Smart Contracts", "Credentials", "Ethereum"],
  "problem_statement": "Eliminating fraudulent academic certificates through immutable distributed ledger verification.",
  "ai_status": "COMPLETED",
  "is_persisted": false
}
```

### 5. Generate & Synchronize Embeddings
* **Endpoint:** `POST /api/v1/ai/sync-embeddings`
* **Request:**
```json
{
  "force_refresh": false
}
```

---

## 7. Running Tests

Run the test suite using `pytest`:
```bash
pytest -v tests/test_ai_service.py
```
