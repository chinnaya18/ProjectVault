import os
import shutil
import psycopg2

DB_HOST = os.environ.get("DB_HOST", "localhost")
DB_PORT = os.environ.get("DB_PORT", "5432")
DB_NAME = os.environ.get("DB_NAME", "projectvault")
DB_USER = os.environ.get("DB_USER", "postgres")
DB_PASS = os.environ.get("DB_PASSWORD", "0608")

STORAGE_DIR = os.environ.get("STORAGE_LOCAL_DIR", "d:/projectvault/storage/projects")

def reset_clean_data():
    print("=" * 70)
    print("PHASE 1: PURGING DUMMY DATA & RESETTING STORAGE")
    print("=" * 70)

    # 1. Connect to PostgreSQL
    conn = psycopg2.connect(
        host=DB_HOST,
        port=DB_PORT,
        dbname=DB_NAME,
        user=DB_USER,
        password=DB_PASS
    )
    conn.autocommit = True
    cur = conn.cursor()

    # 2. Truncate project tables & audit logs
    print("[1/4] Truncating mock project tables and test audit logs...")
    cur.execute("""
        TRUNCATE TABLE 
            project_files, 
            project_keywords, 
            project_members, 
            project_workflow_history, 
            ai_analyses, 
            project_embeddings, 
            projects 
        RESTART IDENTITY CASCADE;
    """)

    # Truncate audit logs if table exists
    cur.execute("""
        DO $$
        BEGIN
            IF EXISTS (SELECT FROM pg_tables WHERE tablename = 'audit_logs') THEN
                TRUNCATE TABLE audit_logs RESTART IDENTITY CASCADE;
            END IF;
        END $$;
    """)
    print("  -> Projects and related relational tables truncated successfully.")

    # 3. Remove all dummy student accounts, preserving Admin and Faculty
    print("[2/4] Removing dummy student accounts...")
    cur.execute("DELETE FROM users WHERE role = 'STUDENT';")
    print(f"  -> Deleted test student records.")

    # Verify retained accounts
    cur.execute("SELECT id, name, email, role FROM users ORDER BY role, id;")
    users = cur.fetchall()
    print("\n[RETAINED INSTITUTIONAL ACCOUNTS]")
    for u in users:
        print(f"  - [{u[3]}] {u[1]} ({u[2]})")

    # 4. Clean physical storage directory
    print("\n[3/4] Purging mock files and folders from physical disk storage...")
    if os.path.exists(STORAGE_DIR):
        for item in os.listdir(STORAGE_DIR):
            item_path = os.path.join(STORAGE_DIR, item)
            if item == ".gitkeep":
                continue
            if os.path.isdir(item_path):
                shutil.rmtree(item_path)
            elif os.path.isfile(item_path):
                os.remove(item_path)
    else:
        os.makedirs(STORAGE_DIR, exist_ok=True)

    gitkeep_path = os.path.join(STORAGE_DIR, ".gitkeep")
    if not os.path.exists(gitkeep_path):
        with open(gitkeep_path, "w") as f:
            f.write("# ProjectVault storage root\n")

    print(f"  -> Physical directory '{STORAGE_DIR}' cleaned cleanly.")

    # 5. Final Statistics Verification
    print("\n[4/4] Verifying Final Database & Storage State...")
    cur.execute("SELECT count(*) FROM projects;")
    proj_count = cur.fetchone()[0]

    cur.execute("SELECT count(*) FROM users WHERE role = 'STUDENT';")
    student_count = cur.fetchone()[0]

    cur.execute("SELECT count(*) FROM users WHERE role = 'FACULTY';")
    faculty_count = cur.fetchone()[0]

    cur.execute("SELECT count(*) FROM users WHERE role = 'ADMIN';")
    admin_count = cur.fetchone()[0]

    cur.close()
    conn.close()

    disk_dirs = [d for d in os.listdir(STORAGE_DIR) if d != ".gitkeep"]

    print(f"  • Projects Count:      {proj_count} (Expected: 0)")
    print(f"  • Students Count:      {student_count} (Expected: 0)")
    print(f"  • Faculty Count:       {faculty_count} (Expected: 18)")
    print(f"  • Admin Count:         {admin_count} (Expected: 1)")
    print(f"  • Storage Subfolders:  {len(disk_dirs)} (Expected: 0)")

    assert proj_count == 0, "Error: Projects table not empty!"
    assert student_count == 0, "Error: Student accounts not empty!"
    assert faculty_count == 18, f"Error: Faculty count is {faculty_count}, expected 18!"
    assert admin_count == 1, f"Error: Admin count is {admin_count}, expected 1!"
    assert len(disk_dirs) == 0, "Error: Storage folder not empty!"

    print("\n" + "=" * 70)
    print("PHASE 1 COMPLETE: SYSTEM IS CLEAN & READY FOR REAL DATA INGESTION!")
    print("=" * 70)

if __name__ == "__main__":
    reset_clean_data()
