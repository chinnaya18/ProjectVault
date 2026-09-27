import psycopg2

conn = psycopg2.connect("postgresql://postgres:0608@localhost:5432/projectvault")
cur = conn.cursor()
cur.execute("""
    ALTER TABLE project_files ADD COLUMN IF NOT EXISTS uploaded_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP;
    UPDATE project_files SET uploaded_at = created_at WHERE uploaded_at IS NULL AND created_at IS NOT NULL;
""")
conn.commit()
print("UPLOADED_AT_ADDED")
