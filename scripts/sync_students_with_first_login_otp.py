import sys
import io
import psycopg2
import requests

# Fix encoding for Windows console
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')

BCRYPT_HASH = "$2a$10$htdtCpRhaMgUkO7LKcP/cOsuvmEWwRbZFkUz2csu/16.GvvGjgMzq" # "Password@123"

def sync_students():
    conn = psycopg2.connect(
        dbname="projectvault",
        user="postgres",
        password="0608",
        host="localhost",
        port=5432
    )
    cur = conn.cursor()

    # 1. Ensure all existing senior students have must_change_password = true
    cur.execute("""
        UPDATE users 
        SET must_change_password = true, 
            password_hash = %s 
        WHERE role = 'STUDENT';
    """, (BCRYPT_HASH,))
    seniors_updated = cur.rowcount
    print(f"Updated {seniors_updated} existing senior students with must_change_password = true")

    # 2. Fetch all 119 students from student_roster
    cur.execute("""
        SELECT roll_no, name, email, department_id 
        FROM student_roster 
        WHERE batch = '2025-2027' AND is_eligible = true;
    """)
    roster_students = cur.fetchall()
    print(f"Found {len(roster_students)} eligible 25MX students in nominal roll.")

    created_count = 0
    updated_count = 0

    insert_user_sql = """
        INSERT INTO users (email, password_hash, name, roll_no, role, user_status, department_id, is_active, must_change_password, created_at, updated_at)
        VALUES (%s, %s, %s, %s, 'STUDENT', 'ACTIVE', %s, true, true, NOW(), NOW())
        ON CONFLICT (email) DO UPDATE SET
            name = EXCLUDED.name,
            roll_no = EXCLUDED.roll_no,
            password_hash = EXCLUDED.password_hash,
            role = 'STUDENT',
            user_status = 'ACTIVE',
            department_id = EXCLUDED.department_id,
            is_active = true,
            must_change_password = true,
            updated_at = NOW()
        RETURNING (xmax = 0);
    """

    for roll, name, email, dept_id in roster_students:
        clean_email = email.strip().lower()
        clean_roll = roll.strip().upper()
        clean_name = name.strip()
        dept = dept_id if dept_id else 1

        cur.execute(insert_user_sql, (clean_email, BCRYPT_HASH, clean_name, clean_roll, dept))
        is_insert = cur.fetchone()[0]
        if is_insert:
            created_count += 1
        else:
            updated_count += 1

    # 3. Update student_roster is_registered to true ONLY for students who completed activation (must_change_password = false)
    cur.execute("""
        UPDATE student_roster 
        SET is_registered = true, updated_at = NOW() 
        WHERE email IN (SELECT email FROM users WHERE role = 'STUDENT' AND must_change_password = false);
    """)

    conn.commit()

    # Query statistics
    cur.execute("SELECT COUNT(*) FROM users WHERE role = 'STUDENT';")
    total_students = cur.fetchone()[0]

    cur.execute("SELECT COUNT(*) FROM users WHERE role = 'STUDENT' AND must_change_password = true;")
    students_must_change = cur.fetchone()[0]

    cur.execute("SELECT email, roll_no, name, must_change_password FROM users WHERE role = 'STUDENT' ORDER BY roll_no ASC LIMIT 5;")
    sample_students = cur.fetchall()

    conn.close()

    print("\n--- STUDENT SYNC SUMMARY ---")
    print(f"Total Student User Accounts in System: {total_students}")
    print(f"Students Requiring First-Login Email OTP: {students_must_change}")
    print(f"New 25MX Accounts Created: {created_count}, Updated: {updated_count}")
    print("\nSample Students (All flagged must_change_password = true):")
    for email, roll, name, mcp in sample_students:
        print(f"  [{roll}] {name} ({email}) -> mustChangePassword={mcp}")

    # 4. Test live login for a 25MX student
    sample_email = sample_students[0][0]
    print(f"\nTesting live login for student: {sample_email} with password 'Password@123'")
    try:
        res = requests.post(
            "http://localhost:8080/api/v1/auth/login",
            json={"email": sample_email, "password": "Password@123"},
            timeout=5
        )
        if res.status_code == 200:
            user_data = res.json()["data"]["user"]
            print(f"Login Response 200 OK! mustChangePassword = {user_data.get('mustChangePassword')}")
            assert user_data.get("mustChangePassword") == True, "Expected mustChangePassword to be true!"
            print("Verified! Student login triggers Email OTP first-login verification modal immediately.")
        else:
            print(f"Login failed with status {res.status_code}: {res.text}")
    except Exception as e:
        print(f"Could not reach live API: {e}")

if __name__ == "__main__":
    sync_students()
