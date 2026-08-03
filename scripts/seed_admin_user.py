import urllib.request
import json
import subprocess
import os

BASE_URL = "http://localhost:8080/api/v1"

def register_user(email, password, first_name, last_name, dept_id=1):
    payload = {
        "email": email,
        "password": password,
        "firstName": first_name,
        "lastName": last_name,
        "departmentId": dept_id
    }
    headers = {"Content-Type": "application/json"}
    req = urllib.request.Request(f"{BASE_URL}/auth/register", data=json.dumps(payload).encode("utf-8"), headers=headers, method="POST")
    try:
        with urllib.request.urlopen(req) as resp:
            return json.loads(resp.read().decode("utf-8"))
    except urllib.error.HTTPError as e:
        print("Registration error:", e.read().decode("utf-8"))
        return None

def set_role(email, role):
    env = os.environ.copy()
    env["PGPASSWORD"] = "0608"
    sql = f"UPDATE users SET role = '{role}' WHERE email = '{email}';"
    subprocess.run(["psql", "-U", "postgres", "-h", "localhost", "-d", "projectvault", "-c", sql], env=env)
    print(f"Updated role for {email} to {role}")

if __name__ == "__main__":
    print("Registering Admin User...")
    res = register_user("admin.vault@projectvault.edu", "Password@123", "Super", "Admin", 1)
    if res and res.get("success"):
        print("Registered admin.vault@projectvault.edu successfully.")
        set_role("admin.vault@projectvault.edu", "ADMIN")
    else:
        print("Admin user already registered or failed. Setting role anyway...")
        set_role("admin.vault@projectvault.edu", "ADMIN")
