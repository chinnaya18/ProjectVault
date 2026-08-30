import os
import psycopg2

DB_HOST = os.getenv("DB_HOST", "localhost")
DB_PORT = os.getenv("DB_PORT", "5432")
DB_NAME = os.getenv("DB_NAME", "projectvault")
DB_USER = os.getenv("DB_USER", "postgres")
DB_PASS = os.getenv("DB_PASSWORD", "0608")

def run_migration():
    print(f"Connecting to database {DB_NAME} at {DB_HOST}:{DB_PORT}...")
    conn = psycopg2.connect(
        host=DB_HOST,
        port=DB_PORT,
        dbname=DB_NAME,
        user=DB_USER,
        password=DB_PASS
    )
    conn.autocommit = True
    cursor = conn.cursor()

    steps = [
        ("Step 1: Add new columns", 
         "ALTER TABLE users ADD COLUMN IF NOT EXISTS name VARCHAR(150); ALTER TABLE users ADD COLUMN IF NOT EXISTS roll_no VARCHAR(50);"),
        
        ("Step 2: Populate name from existing records",
         """
         DO $$
         BEGIN
             IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='users' AND column_name='first_name') THEN
                 UPDATE users 
                 SET name = TRIM(CONCAT(COALESCE(first_name, ''), ' ', COALESCE(last_name, ''))) 
                 WHERE name IS NULL OR name = '';
             END IF;
         END $$;
         """),
         
        ("Step 3: Populate roll_no for student accounts",
         """
         UPDATE users 
         SET roll_no = UPPER(SPLIT_PART(email, '@', 1))
         WHERE role = 'STUDENT' AND (roll_no IS NULL OR roll_no = '');
         """),
         
        ("Step 4: Set constraints and drop legacy columns",
         """
         UPDATE users SET name = 'User' WHERE name IS NULL OR name = '';
         ALTER TABLE users ALTER COLUMN name SET NOT NULL;
         ALTER TABLE users DROP COLUMN IF EXISTS first_name;
         ALTER TABLE users DROP COLUMN IF EXISTS last_name;
         """)
    ]

    for title, sql in steps:
        print(f"Executing: {title}")
        cursor.execute(sql)
        print("  -> Success")

    cursor.execute("SELECT id, email, name, roll_no, role FROM users LIMIT 5;")
    rows = cursor.fetchall()
    print("\nSample rows from users table:")
    for r in rows:
        print(f"  ID: {r[0]} | Email: {r[1]} | Name: {r[2]} | RollNo: {r[3]} | Role: {r[4]}")

    cursor.close()
    conn.close()
    print("\nDatabase migration completed successfully!")

if __name__ == "__main__":
    run_migration()
