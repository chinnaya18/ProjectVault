import psycopg2
conn = psycopg2.connect("postgresql://postgres:0608@localhost:5432/projectvault")
cur = conn.cursor()
cur.execute("SELECT column_name FROM information_schema.columns WHERE table_name = 'project_files';")
print("project_files columns:", [r[0] for r in cur.fetchall()])
