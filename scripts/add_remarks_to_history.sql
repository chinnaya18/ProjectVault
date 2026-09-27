-- Migration: Add remarks column to project_workflow_history for faculty feedback
ALTER TABLE project_workflow_history ADD COLUMN IF NOT EXISTS remarks TEXT;
