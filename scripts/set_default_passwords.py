import psycopg2
import requests

# BCrypt hash for "Password@123" (students/faculty default)
BCRYPT_HASH = "$2a$10$htdtCpRhaMgUkO7LKcP/cOsuvmEWwRbZFkUz2csu/16.GvvGjgMzq"
# BCrypt hash for "Adminpsg2025@" (admin default)
ADMIN_BCRYPT_HASH = "$2a$10$yj9QYa6wDSQ4NEWn22aGGeGcTZoqm6DUeGGlSXxrIk636CQ3acqSi"

def update_passwords():
    conn = psycopg2.connect(
        dbname="projectvault",
        user="postgres",
        password="0608",
        host="localhost",
        port=5432
    )
    cur = conn.cursor()
    
    # Update non-admin accounts to Password@123
    cur.execute("UPDATE users SET password_hash = %s WHERE role != 'ADMIN' AND email != 'admin@psgtech.ac.in';", (BCRYPT_HASH,))
    print(f"Updated {cur.rowcount} student/faculty accounts with 'Password@123'")

    # Update admin account to Adminpsg2025@
    cur.execute("UPDATE users SET password_hash = %s WHERE role = 'ADMIN' OR email = 'admin@psgtech.ac.in';", (ADMIN_BCRYPT_HASH,))
    print(f"Updated {cur.rowcount} admin account(s) with 'Adminpsg2025@'")
    conn.commit()
    
    # Verify the stored hash in PostgreSQL
    cur.execute("SELECT email, password_hash, role, must_change_password FROM users WHERE role = 'ADMIN';")
    for row in cur.fetchall():
        print("Admin DB check:", row[0], "->", row[1][:15] + "...", "| Role:", row[2])
    
    conn.close()

    # Now verify live login against Spring Boot on port 8081
    test_accounts = [
        ("Admin", "admin@psgtech.ac.in", "Adminpsg2025@"),
        ("Faculty", "nir.mca@psgtech.ac.in", "Password@123"),
        ("Student", "24mx207@psgtech.ac.in", "Password@123")
    ]
    
    print("\n--- Live Login Verification ---")
    for role_name, email, pwd in test_accounts:
        try:
            res = requests.post(
                "http://localhost:8081/api/v1/auth/login",
                json={"email": email, "password": pwd},
                timeout=5
            )
            if res.status_code == 200:
                print(f"  [SUCCESS] {role_name} ({email}) logged in successfully with '{pwd}'")
            else:
                print(f"  [FAILED] {role_name} ({email}): status {res.status_code}, {res.text}")
        except Exception as e:
            print(f"  [SKIPPED] {role_name} ({email}): backend server not listening on 8081")


if __name__ == "__main__":
    update_passwords()
