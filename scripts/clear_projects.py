import subprocess
import os
import sys

PG_HOST = os.environ.get("DB_HOST", "localhost")
PG_PORT = os.environ.get("DB_PORT", "5432")
PG_USER = os.environ.get("DB_USER", "postgres")
PG_PASSWORD = os.environ.get("DB_PASSWORD", "0608")
DB_NAME = os.environ.get("DB_NAME", "projectvault")

env = os.environ.copy()
env["PGPASSWORD"] = PG_PASSWORD

def run_psql(cmd_args, db=DB_NAME):
    full_cmd = ["psql", "-U", PG_USER, "-h", PG_HOST, "-p", PG_PORT, "-d", db] + cmd_args
    res = subprocess.run(full_cmd, env=env, capture_output=True, text=True)
    return res

def clear_projects():
    print("--- Clearing Old Projects from Database ---")
    sql = """
    TRUNCATE TABLE project_files, project_keywords, project_members, project_workflow_history, ai_analyses, project_embeddings, projects RESTART IDENTITY CASCADE;
    
    -- Ensure admin user role is ADMIN
    UPDATE users SET role = 'ADMIN' WHERE email = 'admin@university.edu';
    """
    res = run_psql(["-c", sql])
    if res.returncode != 0:
        print(f"Failed to clear projects: {res.stderr}")
    else:
        print("All old projects successfully removed. Database is clean and ready for fresh project workflow!")

if __name__ == "__main__":
    clear_projects()
