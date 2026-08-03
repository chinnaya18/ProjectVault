# ProjectVault — Database Architecture & Schema Specification

**Document Version:** 1.0.0  
**Date:** August 2026  
**Status:** Approved Database Specification (Phase 1)

---

## 1. Overview & Engine Specification

* **Database Engine:** PostgreSQL 15 or higher.
* **Vector Extension:** `pgvector` (`CREATE EXTENSION IF NOT EXISTS vector;`).
* **Primary Key Strategy:** `BIGSERIAL` (64-bit auto-incrementing integer) or `UUID` v4 for secure reference keys where applicable. Standardized on `BIGSERIAL` for high performance and low index footprint.
* **Character Encoding:** UTF-8.
* **Timestamp Standard:** `TIMESTAMPTZ` (UTC timestamp with time zone).

---

## 2. Entity Relationship (ER) Diagram

```
                        +--------------------+
                        |    departments     |
                        +--------------------+
                        | PK id              |
                        |    name            |
                        |    code            |
                        +---------┬----------+
                                  | 1
                                  |
                                  | *
                        +---------┴----------+
                        |       users        |
                        +--------------------+
                        | PK id              |
                        | FK department_id   |
                        |    email           |
                        |    role            | (ADMIN, FACULTY, STUDENT)
                        |    user_status     | (ACTIVE, ALUMNI, INACTIVE)
                        +---------┬----------+
                                  | 1
                                  |
            ┌─────────────────────┼─────────────────────┐
            | 1                   | *                   | *
+-----------┴----------+ +--------┴-----------+ +-------┴------------+
|   project_members    | |      projects      | |     audit_logs     |
+----------------------+ +--------------------+ +--------------------+
| PK id                | | PK id              | | PK id              |
| FK project_id        | | FK department_id   | | FK user_id         |
| FK user_id           | | FK created_by_user | |    action          |
|    member_role       | |    status          | |    details         |
+----------------------+ |    visibility      | +--------------------+
                         +---------┬----------+
                                   | 1
       ┌───────────────────────────┼───────────────────────────┐
       | 1..*                      | 0..1                      | 0..1
+------┴---------------+ +---------┴----------+ +--------------┴-----+
|    project_files     | |    ai_analyses     | | project_embeddings |
+----------------------+ +--------------------+ +--------------------+
| PK id                | | PK id              | | PK id              |
| FK project_id        | | FK project_id      | | FK project_id      |
|    file_name         | |    summary         | |    embedding_vector| (vector(384))
|    storage_path      | |    domain          | +--------------------+
+----------------------+ |    tech_stack      |
                         +--------------------+
                                   | 1
                                   | *
                         +---------┴----------+
                         |  project_keywords  |
                         +--------------------+
                         | FK project_id      |
                         | FK keyword_id      |
                         +---------┬----------+
                                   | *
                                   | 1
                         +---------┴----------+
                         |      keywords      |
                         +--------------------+
                         | PK id              |
                         |    name            |
                         +--------------------+
```

---

## 3. Enumerated Types (Enums)

### 3.1 `user_role`
* `ADMIN` - System administrator
* `FACULTY` - Faculty guide / Department reviewer
* `STUDENT` - Student project author / team member

### 3.2 `user_status`
* `ACTIVE` - Active account (current student, faculty, admin)
* `ALUMNI` - Graduated student (preserves single user identity and historical projects)
* `INACTIVE` - Deactivated / suspended account

### 3.3 `project_status`
* `DRAFT` - Project under creation by student
* `SUBMITTED` - Project submitted for faculty evaluation
* `UNDER_REVIEW` - Faculty actively reviewing project
* `APPROVED` - Project approved and discoverable
* `REJECTED` - Project returned to student with feedback
* `ARCHIVED` - Historical project archived by department

### 3.4 `project_visibility`
* `PUBLIC` - Accessible to all (including unauthenticated Public Visitors)
* `DEPARTMENT_ONLY` - Restricted to users in the same department
* `PRIVATE` - Restricted to project authors and assigned faculty guide

---

## 4. Table Schema Definitions

### 4.1 `departments`
Stores academic departments.
```sql
CREATE TABLE departments (
    id BIGSERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL UNIQUE,
    code VARCHAR(20) NOT NULL UNIQUE,
    description TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);
```

### 4.2 `users`
Stores user accounts. Note: Public visitors do NOT have entries here.
```sql
CREATE TABLE users (
    id BIGSERIAL PRIMARY KEY,
    email VARCHAR(150) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    role VARCHAR(20) NOT NULL CHECK (role IN ('ADMIN', 'FACULTY', 'STUDENT')),
    user_status VARCHAR(20) NOT NULL DEFAULT 'ACTIVE' CHECK (user_status IN ('ACTIVE', 'ALUMNI', 'INACTIVE')),
    department_id BIGINT REFERENCES departments(id) ON DELETE SET NULL,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_users_department ON users(department_id);
CREATE INDEX idx_users_role ON users(role);
CREATE INDEX idx_users_email ON users(email);
```

### 4.3 `projects`
Core project metadata and lifecycle state table.
```sql
CREATE TABLE projects (
    id BIGSERIAL PRIMARY KEY,
    title VARCHAR(255) NOT NULL,
    abstract TEXT NOT NULL,
    academic_year VARCHAR(10) NOT NULL, -- e.g., '2025-2026'
    semester INT NOT NULL CHECK (semester BETWEEN 1 AND 10),
    project_type VARCHAR(50) NOT NULL, -- e.g., 'Mini Project', 'Major Project', 'Capstone'
    status VARCHAR(20) NOT NULL DEFAULT 'DRAFT' CHECK (status IN ('DRAFT', 'SUBMITTED', 'UNDER_REVIEW', 'APPROVED', 'REJECTED', 'ARCHIVED')),
    visibility VARCHAR(20) NOT NULL DEFAULT 'PUBLIC' CHECK (visibility IN ('PUBLIC', 'DEPARTMENT_ONLY', 'PRIVATE')),
    department_id BIGINT NOT NULL REFERENCES departments(id) ON DELETE CASCADE,
    created_by_user_id BIGINT NOT NULL REFERENCES users(id) ON DELETE RESTRICT,
    repository_url VARCHAR(255),
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_projects_department ON projects(department_id);
CREATE INDEX idx_projects_status ON projects(status);
CREATE INDEX idx_projects_visibility ON projects(visibility);
CREATE INDEX idx_projects_academic_year ON projects(academic_year);
CREATE INDEX idx_projects_created_by ON projects(created_by_user_id);
```

### 4.4 `project_members`
Junction table linking multiple student authors and faculty guides to a project.
```sql
CREATE TABLE project_members (
    id BIGSERIAL PRIMARY KEY,
    project_id BIGINT NOT NULL REFERENCES projects(id) ON DELETE CASCADE,
    user_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    member_role VARCHAR(50) NOT NULL, -- e.g., 'Lead Developer', 'Faculty Guide', 'Researcher'
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uk_project_user UNIQUE (project_id, user_id)
);

CREATE INDEX idx_project_members_project ON project_members(project_id);
CREATE INDEX idx_project_members_user ON project_members(user_id);
```

### 4.5 `project_files`
Stores metadata and disk storage reference paths for project artifacts. (No binary content stored).
```sql
CREATE TABLE project_files (
    id BIGSERIAL PRIMARY KEY,
    project_id BIGINT NOT NULL REFERENCES projects(id) ON DELETE CASCADE,
    file_name VARCHAR(255) NOT NULL,
    file_type VARCHAR(50) NOT NULL, -- e.g., 'PDF', 'PPTX', 'DOCX'
    file_size BIGINT NOT NULL, -- bytes
    storage_path VARCHAR(500) NOT NULL, -- e.g., 'storage/projects/project-12/report.pdf'
    storage_type VARCHAR(20) NOT NULL DEFAULT 'LOCAL', -- 'LOCAL', 'NAS', 'S3'
    uploaded_by_user_id BIGINT NOT NULL REFERENCES users(id) ON DELETE RESTRICT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_project_files_project ON project_files(project_id);
```

### 4.6 `keywords`
Unique canonical and AI-extracted keywords dictionary.
```sql
CREATE TABLE keywords (
    id BIGSERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL UNIQUE,
    normalized_name VARCHAR(100) NOT NULL UNIQUE
);

CREATE INDEX idx_keywords_normalized ON keywords(normalized_name);
```

### 4.7 `project_keywords`
Junction table mapping keywords to projects with extraction source tag.
```sql
CREATE TABLE project_keywords (
    project_id BIGINT NOT NULL REFERENCES projects(id) ON DELETE CASCADE,
    keyword_id BIGINT NOT NULL REFERENCES keywords(id) ON DELETE CASCADE,
    is_ai_generated BOOLEAN NOT NULL DEFAULT FALSE,
    PRIMARY KEY (project_id, keyword_id)
);
```

### 4.8 `ai_analyses`
Stores generative AI metadata extracted by Google Gemini API.
```sql
CREATE TABLE ai_analyses (
    id BIGSERIAL PRIMARY KEY,
    project_id BIGINT NOT NULL UNIQUE REFERENCES projects(id) ON DELETE CASCADE,
    summary TEXT NOT NULL,
    domain VARCHAR(100) NOT NULL,
    extracted_keywords TEXT[], -- array of strings
    tech_stack TEXT[], -- array of tech tags e.g. {'React', 'Spring Boot', 'PostgreSQL'}
    problem_statement TEXT,
    ai_status VARCHAR(20) NOT NULL DEFAULT 'COMPLETED', -- 'COMPLETED', 'FAILED', 'PENDING_RETRY'
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_ai_analyses_domain ON ai_analyses(domain);
```

### 4.9 `project_embeddings`
Stores 384-dimensional dense vector embeddings for semantic search and recommendation matching via `pgvector`.
```sql
CREATE TABLE project_embeddings (
    id BIGSERIAL PRIMARY KEY,
    project_id BIGINT NOT NULL UNIQUE REFERENCES projects(id) ON DELETE CASCADE,
    embedding_vector vector(384) NOT NULL,
    model_version VARCHAR(50) NOT NULL DEFAULT 'sentence-transformers/all-MiniLM-L6-v2',
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- HNSW Vector Index for Cosine Similarity Search
CREATE INDEX idx_project_embeddings_vector 
ON project_embeddings 
USING hnsw (embedding_vector vector_cosine_ops)
WITH (m = 16, ef_construction = 64);
```

### 4.10 `audit_logs`
Tracks institutional system events and governance audit trails.
```sql
CREATE TABLE audit_logs (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT REFERENCES users(id) ON DELETE SET NULL, -- NULL for unauthenticated visitor actions
    action VARCHAR(100) NOT NULL, -- e.g., 'PROJECT_SUBMITTED', 'STATUS_APPROVED', 'ROLE_CHANGED'
    entity_type VARCHAR(50) NOT NULL, -- e.g., 'PROJECT', 'USER', 'FILE'
    entity_id BIGINT,
    details TEXT,
    ip_address VARCHAR(45),
    timestamp TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_audit_logs_user ON audit_logs(user_id);
CREATE INDEX idx_audit_logs_action ON audit_logs(action);
CREATE INDEX idx_audit_logs_timestamp ON audit_logs(timestamp);
```

---

## 5. Optimization & Query Strategies

1. **pgvector Cosine Search Query:**
   ```sql
   SELECT p.id, p.title, p.abstract, (1 - (e.embedding_vector <=> :queryVector)) AS similarity
   FROM projects p
   JOIN project_embeddings e ON p.id = e.project_id
   WHERE p.status = 'APPROVED' AND p.visibility = 'PUBLIC'
   ORDER BY e.embedding_vector <=> :queryVector
   LIMIT 10;
   ```
2. **DTO Projections:** Spring Data JPA Interface and Constructor DTO Projections are enforced to avoid loading heavy `abstract` or `ai_analyses` text when rendering project search list cards.
3. **N+1 Prevention:** `JOIN FETCH` queries and `@EntityGraph` definitions are used for retrieving `project_members` and `project_files` in single-query fetches.

---
*End of Database Architecture Specification.*
