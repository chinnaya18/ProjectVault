import psycopg2
import os

conn = psycopg2.connect(
    dbname="projectvault",
    user="postgres",
    password=os.environ.get("DB_PASSWORD", "0608"),
    host="localhost",
    port=5432
)
cur = conn.cursor()
cur.execute("""
CREATE OR REPLACE FUNCTION lower(bytea) 
RETURNS text AS $$ 
    SELECT lower(convert_from($1, 'UTF8')); 
$$ LANGUAGE sql IMMUTABLE;
""")
conn.commit()
print("Function lower(bytea) created successfully")
conn.close()
