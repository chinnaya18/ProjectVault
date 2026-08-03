# ProjectVault — System Architecture Specification

**Document Version:** 1.0.0  
**Date:** August 2026  
**Status:** Approved Architecture Baseline (Phase 1)

---

## 1. System Overview

ProjectVault is built as a decoupled, multi-tier microservice-oriented architecture designed to handle high-concurrency academic repository management alongside resource-intensive NLP and vector similarity search.

```
+---------------------------------------------------------------------------------+
|                              REACT FRONTEND                                     |
|                  (TypeScript, Vite, React Router, Tailwind/CSS)                 |
+---------------------------------------------------------------------------------+
                                         |
                             HTTP / REST (JWT Bearer)
                                         v
+---------------------------------------------------------------------------------+
|                             SPRING BOOT BACKEND                                 |
|            (Java 17, Spring Security, JPA/Hibernate, Maven, OpenAPI)           |
+---------------------------------------------------------------------------------+
             |                                           |
   JPA / SQL |                                           | REST Call (Internal)
             v                                           v
+------------------------+                       +--------------------------------+
| POSTGRESQL + PGVECTOR  |                       |       FASTAPI AI SERVICE       |
| (Relational Tables &   |                       | (Python 3.10, PyPDF, Docx,     |
| 384-dim Embeddings)    |                       |  SentenceXformer, Gemini API)  |
+------------------------+                       +--------------------------------+
                                                                 |
                                                                 | Outbound HTTPS
                                                                 v (Internet)
                                                        Google Gemini API
```

---

## 2. Component Breakdown

### 2.1 React Frontend Tier
* **Technology:** React 18, TypeScript, Vite, Tailwind CSS, Axios, React Router v6.
* **Responsibility:** Provides a rich, responsive user interface for Public Visitors, Students, Faculty, and Administrators.
* **Key Modules:**
  * **Public Portal:** Unauthenticated project discovery, hybrid search bar, project detail viewer, public file downloader.
  * **Student Portal:** Project creation wizard, file uploader, member/guide selector, submission workflow manager.
  * **Faculty Review Desk:** Department review queue, submission inspector, AI summary/analysis preview, approval/rejection panel with feedback.
  * **Admin Console:** User account manager (role/status assignments), department editor, system metrics dashboard, audit log viewer.

### 2.2 Spring Boot Core Backend Tier
* **Technology:** Java 17, Spring Boot 3.2+, Spring Web, Spring Security, Spring Data JPA, Hibernate, Maven.
* **Responsibility:** Serves as the primary business logic engine, API gateway, RBAC authorization engine, transaction manager, and storage orchestrator.
* **Layered Design:**
  * **Controller Layer:** Handles HTTP request/response mappings, OpenAPI documentation, and delegates to service layer. Contains NO business logic.
  * **Service Layer:** Implements core business logic, lifecycle state transitions, permission validations, and external AI service coordination.
  * **Repository Layer:** Spring Data JPA interfaces and custom Specifications for dynamic PostgreSQL queries.
  * **Entity / DTO / Mapper:** Strict separation between database JPA entities and API Data Transfer Objects (DTOs), transformed via dedicated mapper classes.
  * **Security Layer:** Stateless JWT filter, BCrypt password encoder, method-level `@PreAuthorize` guards.
  * **Storage Adapter:** Abstract `FileStorageService` managing local filesystem storage (`storage/projects/project-xxx/`) with interfaces for future cloud/NAS migration.

### 2.3 FastAPI AI Service Tier
* **Technology:** Python 3.10+, FastAPI, Pydantic v2, Uvicorn, SentenceTransformers, Google Gemini API SDK.
* **Responsibility:** Handles heavy document text extraction, generative LLM metadata analysis, and vector embedding computation.
* **Key Sub-services:**
  * **Text Extraction Engine:** Uses `pypdf`/`pdfplumber` for PDF, `python-docx` for Word, `python-pptx` for PowerPoint files.
  * **Generative AI Provider:** Modular `AIService` interface with `GeminiProvider` implementation calling Google Gemini API (`GEMINI_API_KEY`) for structured summary, domain classification, tech stack, and problem statement extraction.
  * **Embedding Engine:** Loads `sentence-transformers/all-MiniLM-L6-v2` locally to produce 384-float array dense embeddings.

### 2.4 Database Tier (PostgreSQL + pgvector)
* **Technology:** PostgreSQL 15+, `pgvector` extension.
* **Responsibility:** Stores relational data (users, departments, projects, files, audit logs) and dense 384-dimensional vector embeddings (`project_embeddings`).
* **Vector Search:** Uses `pgvector` cosine similarity operator `<=>` indexed via HNSW (`halfvec`/`vector`).

---

## 3. Core Interaction & Data Workflows

### 3.1 Asynchronous Project Ingestion & Indexing Workflow
```
[User] -> (Upload File & Submit) -> [Spring Boot]
                                          |
                                          |-- 1. Save file to Local Storage (disk)
                                          |-- 2. Save metadata in `project_files`
                                          |-- 3. Return 202 Accepted to UI
                                          |
                                          +--> (Async Background Task)
                                                    |
                                                    v
                                          [FastAPI AI Service]
                                                    |
                                 +------------------+------------------+
                                 |                                     |
                                 v                                     v
                       [Google Gemini API]                   [SentenceTransformers]
                   (Generative Metadata: Summary,           (Compute 384-dim Vector)
                    Domain, Keywords, Tech Stack)                      |
                                 |                                     |
                                 +------------------+------------------+
                                                    |
                                                    v
                                        [Spring Boot DB Ingest]
                                                    |
                                                    |-- Save to `ai_analyses`
                                                    |-- Save to `project_embeddings`
                                                    v
                                       Project Searchable in Vector DB
```

### 3.2 Hybrid Search Workflow
```
[Visitor / Student Query] -> "deep learning for crop disease"
                                       |
                                       v
                               [Spring Boot API]
                                       |
                   ┌───────────────────┴───────────────────┐
                   │ Keyword Criteria                      │ Semantic Search Request
                   v                                       v
        [JPA Specification]                     [FastAPI /embed Endpoint]
        (Dept, Year, Status)                               │
                   │                                       v
                   │                            [SentenceTransformers]
                   │                            (Generative Query Vector)
                   │                                       │
                   └───────────────────┬───────────────────┘
                                       |
                                       v
                             [PostgreSQL + pgvector]
                     (Cosine Similarity Match `<=>` + SQL Filters)
                                       |
                                       v
                         Sorted Search Results to React UI
```

---

## 4. Intranet & Deployment Topology

ProjectVault is architected for deployment inside a college LAN/Wi-Fi network while maintaining controlled outbound access to external cloud AI APIs:

```
+---------------------------------------------------------------------------------+
|                         COLLEGE INTRANET NETWORK (LAN / WI-FI)                  |
|                                                                                 |
|   Student / Faculty / Visitor Devices                                           |
|   (Browser / Mobile Web)                                                        |
|             │                                                                   |
|             ▼                                                                   |
|   +-----------------------+      +-----------------------+                      |
|   | NGINX / Web Server    | ---> | React App (Static)    |                      |
|   +-----------┬-----------+      +-----------------------+                      |
|               │                                                                 |
|               ▼ REST HTTP (Port 8080)                                           |
|   +-----------------------+      +-----------------------+                      |
|   | Spring Boot Service   | ---> | Local File Storage    |                      |
|   +-----------┬-----------+      | (storage/projects/)   |                      |
|               │                  +-----------------------+                      |
|               ├──────────────────────────┐                                      |
|               ▼ JDBC (Port 5432)         ▼ REST HTTP (Port 8000)                |
|   +-----------------------+      +-----------------------+                      |
|   | PostgreSQL + pgvector |      | FastAPI AI Service    |                      |
|   +-----------------------+      +-----------┬-----------+                      |
|                                              │                                  |
+----------------------------------------------|----------------------------------+
                                               │ Outbound HTTPS (Port 443)
                                               v
                                      Google Gemini API
```

---

## 5. Architectural Quality Attributes

* **Modularity:** Strict separation of UI, API, Business Logic, Persistence, and AI Inference tiers.
* **Resiliency:** External Gemini API failures trigger graceful fallbacks (`PENDING_RETRY` status) without breaking core application workflows or local vector search.
* **Scalability:** Stateless Spring Boot backend and FastAPI service can be independently containerized and horizontally scaled.
* **Maintainability:** Clear package structure, DTO isolation, and interface abstractions.

---
*End of System Architecture Specification.*
