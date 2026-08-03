import urllib.request
import json

BASE_URL = "http://localhost:8080/api/v1"

def make_request(url, method="GET", data=None, headers=None):
    if headers is None:
        headers = {}
    
    headers["Content-Type"] = "application/json"
    encoded_data = json.dumps(data).encode("utf-8") if data else None

    req = urllib.request.Request(url, data=encoded_data, headers=headers, method=method)
    try:
        with urllib.request.urlopen(req) as resp:
            body = resp.read().decode("utf-8")
            return resp.status, json.loads(body)
    except urllib.error.HTTPError as e:
        body = e.read().decode("utf-8")
        try:
            return e.code, json.loads(body)
        except Exception:
            return e.code, {"raw": body}
    except Exception as e:
        return 0, {"error": str(e)}

def run_tests():
    print("--- 1. Testing GET /departments (Public Access) ---")
    status, depts_res = make_request(f"{BASE_URL}/departments")
    print(f"Status [{status}]: Total Depts = {depts_res['data']['totalElements']}")
    for d in depts_res['data']['content']:
        print(f"  - [{d['id']}] {d['code']} : {d['name']}")

    print("\n--- 2. Logging in as ADMIN (admin.vault@projectvault.edu) ---")
    admin_login = {
        "email": "admin.vault@projectvault.edu",
        "password": "Password@123"
    }
    status, admin_res = make_request(f"{BASE_URL}/auth/login", method="POST", data=admin_login)
    admin_token = admin_res["data"]["accessToken"]
    print(f"Admin Token obtained: {admin_token[:30]}...")

    headers_admin = {"Authorization": f"Bearer {admin_token}"}

    print("\n--- 3. Testing POST /departments (ADMIN Only) ---")
    new_dept = {
        "name": "Data Science & Artificial Intelligence",
        "code": "DSAI",
        "description": "Department of Data Science and AI"
    }
    status, create_dept_res = make_request(f"{BASE_URL}/departments", method="POST", data=new_dept, headers=headers_admin)
    print(f"Create Dept Status [{status}]: {create_dept_res['message']}")
    if status == 201:
        print(f"  Created Dept ID: {create_dept_res['data']['id']} ({create_dept_res['data']['name']})")

    print("\n--- 4. Testing GET /users (ADMIN Only) ---")
    status, users_res = make_request(f"{BASE_URL}/users", headers=headers_admin)
    print(f"Users Status [{status}]: Total Users = {users_res['data']['totalElements']}")
    for u in users_res['data']['content']:
        print(f"  - User #{u['id']}: {u['email']} | Role: {u['role']} | Status: {u['userStatus']}")

    print("\n--- 5. Testing PUT /users/{id}/status (Graduation Lifecycle to ALUMNI) ---")
    status_payload = {"userStatus": "ALUMNI"}
    status, alumni_res = make_request(f"{BASE_URL}/users/9/status", method="PUT", data=status_payload, headers=headers_admin)
    print(f"Graduation Status [{status}]: {alumni_res['message']}")
    if status == 200:
        u = alumni_res['data']
        print(f"  Updated User #{u['id']} ({u['email']}) -> Status: {u['userStatus']}, Role: {u['role']}")

if __name__ == "__main__":
    run_tests()
