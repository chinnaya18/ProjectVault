import psycopg2
import requests

# The literal BCrypt hash for "Password@123"
BCRYPT_HASH = "$2a$10$htdtCpRhaMgUkO7LKcP/cOsuvmEWwRbZFkUz2csu/16.GvvGjgMzq"

def update_passwords():
    conn = psycopg2.connect(
        dbname="projectvault",
        user="postgres",
        password="0608",
        host="localhost",
        port=5432
    )
    cur = conn.cursor()
    
    # Update all user accounts in database to have Password@123
    cur.execute("UPDATE users SET password_hash = %s;", (BCRYPT_HASH,))
    conn.commit()
    print(f"Updated {cur.rowcount} users with BCrypt hash for 'Password@123'")
    
    # Verify the stored hash in PostgreSQL
    cur.execute("SELECT email, password_hash, role, must_change_password FROM users LIMIT 3;")
    for row in cur.fetchall():
        print("DB check:", row[0], "->", row[1][:15] + "...", "| Role:", row[2])
    
    conn.close()

    # Now verify live login against Spring Boot on port 8081
    test_accounts = [
        ("Admin", "admin@psgtech.ac.in"),
        ("Faculty", "nir.mca@psgtech.ac.in"),
        ("Student", "24mx207@psgtech.ac.in")
    ]
    
    print("\n--- Live Login Verification ---")
    for role_name, email in test_accounts:
        res = requests.post(
            "http://localhost:8081/api/v1/auth/login",
            json={"email": email, "password": "Password@123"},
            timeout=5
        )
        if res.status_code == 200:
            print(f"  [SUCCESS] {role_name} ({email}) logged in successfully with 'Password@123'")
        else:
            print(f"  [FAILED] {role_name} ({email}): status {res.status_code}, {res.text}")

if __name__ == "__main__":
    update_passwords()
