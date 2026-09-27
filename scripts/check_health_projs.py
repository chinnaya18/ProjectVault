import psycopg2

conn = psycopg2.connect('postgresql://postgres:0608@localhost:5432/projectvault')
cur = conn.cursor()
cur.execute("""
    SELECT p.id, p.title, ai.domain, p.abstract 
    FROM projects p 
    LEFT JOIN ai_analyses ai ON p.id = ai.project_id 
    WHERE ai.domain ILIKE '%health%' 
       OR ai.domain ILIKE '%medic%' 
       OR p.title ILIKE '%wearable%' 
       OR p.abstract ILIKE '%wearable%'
       OR p.title ILIKE '%ecg%'
       OR p.title ILIKE '%eeg%'
       OR p.title ILIKE '%patient%'
    ORDER BY p.id;
""")
rows = cur.fetchall()
print(f"Total matching health/biomedical projects: {len(rows)}")
for r in rows:
    print(f"#{r[0]}: {r[1]}")
    print(f"   Domain: {r[2]}")
    print(f"   Abstract: {r[3][:100]}...\n")
