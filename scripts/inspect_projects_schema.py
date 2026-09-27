import psycopg2
import os

try:
    conn = psycopg2.connect(
        dbname="projectvault",
        user="postgres",
        password=os.environ.get("DB_PASSWORD", "0608"),
        host="localhost",
        port=5432
    )
    cur = conn.cursor()
    cur.execute("""
        SELECT column_name, data_type, udt_name 
        FROM information_schema.columns 
        WHERE table_name = 'projects';
    """)
    for row in cur.fetchall():
        print(row)
    conn.close()
except Exception as e:
    print(f"Error: {e}")
