import psycopg2

conn = psycopg2.connect("postgresql://postgres:0608@localhost:5432/projectvault")
with open("d:/projectvault/scripts/add_plagiarism_columns.sql", "r") as f:
    sql = f.read()

with conn.cursor() as cur:
    cur.execute(sql)
conn.commit()
conn.close()
print("MIGRATION_OK")
