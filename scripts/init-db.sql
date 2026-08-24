-- ProjectVault PostgreSQL & pgvector Database Initialization Script
-- Run this script on PostgreSQL 15+ to set up tables, vector extension, indexes, and constraints.

-- Try to create vector extension if installed on system
DO $$
BEGIN
    BEGIN
        CREATE EXTENSION IF NOT EXISTS vector;
    EXCEPTION
        WHEN OTHERS THEN
            RAISE NOTICE 'pgvector extension not installed on system; fallback array storage will be used.';
    END;
END $$;

-- 1. Departments Table
CREATE TABLE IF NOT EXISTS departments (
    id BIGSERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL UNIQUE,
    code VARCHAR(20) NOT NULL UNIQUE,
    description TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- 2. Users Table
CREATE TABLE IF NOT EXISTS users (
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

CREATE INDEX IF NOT EXISTS idx_users_department ON users(department_id);
CREATE INDEX IF NOT EXISTS idx_users_role ON users(role);
CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);

-- 3. Projects Table
CREATE TABLE IF NOT EXISTS projects (
    id BIGSERIAL PRIMARY KEY,
    title VARCHAR(255) NOT NULL,
    abstract TEXT NOT NULL,
    academic_year VARCHAR(10) NOT NULL,
    semester INT NOT NULL CHECK (semester BETWEEN 1 AND 10),
    project_type VARCHAR(50) NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'DRAFT' CHECK (status IN ('DRAFT', 'SUBMITTED', 'UNDER_REVIEW', 'APPROVED', 'REJECTED', 'ARCHIVED')),
    visibility VARCHAR(20) NOT NULL DEFAULT 'PUBLIC' CHECK (visibility IN ('PUBLIC', 'DEPARTMENT_ONLY', 'PRIVATE')),
    department_id BIGINT NOT NULL REFERENCES departments(id) ON DELETE CASCADE,
    created_by_user_id BIGINT NOT NULL REFERENCES users(id) ON DELETE RESTRICT,
    guide_faculty_id BIGINT REFERENCES users(id) ON DELETE SET NULL,
    repository_url VARCHAR(255),
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_projects_department ON projects(department_id);
CREATE INDEX IF NOT EXISTS idx_projects_status ON projects(status);
CREATE INDEX IF NOT EXISTS idx_projects_visibility ON projects(visibility);
CREATE INDEX IF NOT EXISTS idx_projects_academic_year ON projects(academic_year);
CREATE INDEX IF NOT EXISTS idx_projects_created_by ON projects(created_by_user_id);

-- 4. Project Members Table
CREATE TABLE IF NOT EXISTS project_members (
    id BIGSERIAL PRIMARY KEY,
    project_id BIGINT NOT NULL REFERENCES projects(id) ON DELETE CASCADE,
    user_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    member_role VARCHAR(50) NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uk_project_user UNIQUE (project_id, user_id)
);

CREATE INDEX IF NOT EXISTS idx_project_members_project ON project_members(project_id);
CREATE INDEX IF NOT EXISTS idx_project_members_user ON project_members(user_id);

-- 5. Project Files Table
CREATE TABLE IF NOT EXISTS project_files (
    id BIGSERIAL PRIMARY KEY,
    project_id BIGINT NOT NULL REFERENCES projects(id) ON DELETE CASCADE,
    file_name VARCHAR(255) NOT NULL,
    file_type VARCHAR(50) NOT NULL,
    file_size BIGINT NOT NULL,
    storage_path VARCHAR(500) NOT NULL,
    storage_type VARCHAR(20) NOT NULL DEFAULT 'LOCAL',
    uploaded_by_user_id BIGINT NOT NULL REFERENCES users(id) ON DELETE RESTRICT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_project_files_project ON project_files(project_id);

-- 6. Keywords Table
CREATE TABLE IF NOT EXISTS keywords (
    id BIGSERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL UNIQUE,
    normalized_name VARCHAR(100) NOT NULL UNIQUE
);

CREATE INDEX IF NOT EXISTS idx_keywords_normalized ON keywords(normalized_name);

-- 7. Project Keywords Table
CREATE TABLE IF NOT EXISTS project_keywords (
    project_id BIGINT NOT NULL REFERENCES projects(id) ON DELETE CASCADE,
    keyword_id BIGINT NOT NULL REFERENCES keywords(id) ON DELETE CASCADE,
    is_ai_generated BOOLEAN NOT NULL DEFAULT FALSE,
    PRIMARY KEY (project_id, keyword_id)
);

-- 8. AI Analyses Table
CREATE TABLE IF NOT EXISTS ai_analyses (
    id BIGSERIAL PRIMARY KEY,
    project_id BIGINT NOT NULL UNIQUE REFERENCES projects(id) ON DELETE CASCADE,
    summary TEXT NOT NULL,
    domain VARCHAR(100) NOT NULL,
    extracted_keywords TEXT[],
    tech_stack TEXT[],
    problem_statement TEXT,
    ai_status VARCHAR(20) NOT NULL DEFAULT 'COMPLETED',
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_ai_analyses_domain ON ai_analyses(domain);

-- 9. Project Embeddings Table (Dynamic Vector / Real[] Fallback)
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM pg_type WHERE typname = 'vector') THEN
        EXECUTE 'CREATE TABLE IF NOT EXISTS project_embeddings (
            id BIGSERIAL PRIMARY KEY,
            project_id BIGINT NOT NULL UNIQUE REFERENCES projects(id) ON DELETE CASCADE,
            embedding_vector vector(384) NOT NULL,
            model_version VARCHAR(50) NOT NULL DEFAULT ''sentence-transformers/all-MiniLM-L6-v2'',
            created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
            updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
        )';
        BEGIN
            EXECUTE 'CREATE INDEX IF NOT EXISTS idx_project_embeddings_vector ON project_embeddings USING hnsw (embedding_vector vector_cosine_ops) WITH (m = 16, ef_construction = 64)';
        EXCEPTION WHEN OTHERS THEN
            RAISE NOTICE 'HNSW index build skipped or already exists.';
        END;
    ELSE
        EXECUTE 'CREATE TABLE IF NOT EXISTS project_embeddings (
            id BIGSERIAL PRIMARY KEY,
            project_id BIGINT NOT NULL UNIQUE REFERENCES projects(id) ON DELETE CASCADE,
            embedding_vector real[] NOT NULL,
            model_version VARCHAR(50) NOT NULL DEFAULT ''sentence-transformers/all-MiniLM-L6-v2'',
            created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
            updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
        )';
    END IF;
END $$;

-- Fallback Cosine Similarity Function for real[] arrays
CREATE OR REPLACE FUNCTION cosine_similarity(a real[], b real[]) RETURNS real AS $$
DECLARE
    dot_product real := 0;
    norm_a real := 0;
    norm_b real := 0;
    i int;
BEGIN
    FOR i IN 1..array_length(a, 1) LOOP
        dot_product := dot_product + (a[i] * b[i]);
        norm_a := norm_a + (a[i] * a[i]);
        norm_b := norm_b + (b[i] * b[i]);
    END LOOP;
    IF norm_a = 0 OR norm_b = 0 THEN
        RETURN 0;
    END IF;
    RETURN dot_product / (sqrt(norm_a) * sqrt(norm_b));
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- 10. Audit Logs Table
CREATE TABLE IF NOT EXISTS audit_logs (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT REFERENCES users(id) ON DELETE SET NULL,
    action VARCHAR(100) NOT NULL,
    entity_type VARCHAR(50) NOT NULL,
    entity_id BIGINT,
    details TEXT,
    ip_address VARCHAR(45),
    timestamp TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_audit_logs_user ON audit_logs(user_id);
CREATE INDEX IF NOT EXISTS idx_audit_logs_action ON audit_logs(action);
CREATE INDEX IF NOT EXISTS idx_audit_logs_timestamp ON audit_logs(timestamp);
