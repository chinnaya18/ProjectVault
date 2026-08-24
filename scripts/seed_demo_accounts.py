import urllib.request
import json

BASE_URL = "http://localhost:8080/api/v1"

def make_request(url, method="GET", data=None, token=None):
    headers = {"Content-Type": "application/json"}
    if token:
        headers["Authorization"] = f"Bearer {token}"
    encoded_data = json.dumps(data).encode("utf-8") if data else None
    req = urllib.request.Request(url, data=encoded_data, headers=headers, method=method)
    try:
        with urllib.request.urlopen(req) as resp:
            return resp.status, json.loads(resp.read().decode("utf-8"))
    except urllib.error.HTTPError as e:
        body = e.read().decode("utf-8")
        try:
            return e.code, json.loads(body)
        except Exception:
            return e.code, {"raw": body}
    except Exception as e:
        return 0, {"error": str(e)}

def seed_roles():
    print("--- Seeding Demo User Accounts & Roles ---")
    
    # 1. Register Accounts
    accounts = [
        ("admin@university.edu", "Password@123", "System", "Admin", "ADMIN"),
        ("geetha@university.edu", "Password@123", "Geetha", "Faculty", "FACULTY"),
        ("gayathri@university.edu", "Password@123", "Gayathri", "Faculty", "FACULTY"),
        ("manavalan@university.edu", "Password@123", "Manavalan", "Faculty", "FACULTY"),
        ("25mx101@university.edu", "Password@123", "Bala", "Student", "STUDENT"),
        ("25mx102@university.edu", "Password@123", "Gopi", "Student", "STUDENT"),
        ("25mx103@university.edu", "Password@123", "Kaleel", "Student", "STUDENT"),
        ("25mx104@university.edu", "Password@123", "Vikram", "Student", "STUDENT"),
        ("25mx105@university.edu", "Password@123", "Chinnaya", "Student", "STUDENT"),
        ("25mx106@university.edu", "Password@123", "Saravanavel", "Student", "STUDENT")
    ]
    for email, pwd, fname, lname, _ in accounts:
        status, res = make_request(f"{BASE_URL}/auth/register", method="POST", data={
            "email": email, "password": pwd, "firstName": fname, "lastName": lname, "departmentId": 1
        })
        print(f"Register {email}: Status [{status}]")

    # 2. Login as Admin
    status, login_res = make_request(f"{BASE_URL}/auth/login", method="POST", data={
        "email": "admin@university.edu", "password": "Password@123"
    })
    admin_token = login_res.get("data", {}).get("accessToken")
    print(f"Admin Login Status: [{status}]")

    if not admin_token:
        print("Could not obtain Admin Token")
        return

    # 3. Get all users and update roles
    status, users_res = make_request(f"{BASE_URL}/users?size=100", token=admin_token)
    users = users_res.get("data", {}).get("content", [])

    role_map = {email: role for email, _, _, _, role in accounts}

    for u in users:
        uid = u["id"]
        uemail = u["email"]
        target_role = role_map.get(uemail)

        if target_role:
            r_status, r_res = make_request(f"{BASE_URL}/users/{uid}/role", method="PUT", data={"role": target_role}, token=admin_token)
            print(f"Set User #{uid} ({uemail}) -> Role: {target_role} [Status {r_status}]")

    print("\n--- Verified Credentials Ready ---")
    print("Admin:   admin@university.edu / Password@123")
    print("Faculty: geetha@university.edu, gayathri@university.edu, manavalan@university.edu / Password@123")
    print("Student: 25mx101@university.edu ... 25mx106@university.edu / Password@123")

if __name__ == "__main__":
    seed_roles()
