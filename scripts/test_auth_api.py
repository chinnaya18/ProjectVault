import urllib.request
import json
import time
import sys

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
    print("Testing Backend Health Endpoint...")
    status, res = make_request(f"{BASE_URL}/health")
    print(f"Health Status [{status}]: {res}")
    if status != 200:
        print("Backend not ready yet. Retrying...")
        time.sleep(3)
        status, res = make_request(f"{BASE_URL}/health")
        print(f"Retry Health Status [{status}]: {res}")

    print("\n--- Testing Registration ---")
    reg_payload = {
        "email": "test.student@projectvault.edu",
        "password": "Password@123",
        "firstName": "Test",
        "lastName": "Student",
        "departmentId": 1
    }
    status, reg_res = make_request(f"{BASE_URL}/auth/register", method="POST", data=reg_payload)
    print(f"Registration Status [{status}]: {json.dumps(reg_res, indent=2)}")

    print("\n--- Testing Login ---")
    login_payload = {
        "email": "test.student@projectvault.edu",
        "password": "Password@123"
    }
    status, login_res = make_request(f"{BASE_URL}/auth/login", method="POST", data=login_payload)
    print(f"Login Status [{status}]: {json.dumps(login_res, indent=2)}")

    token = None
    if status == 200 and login_res.get("success"):
        token = login_res["data"]["accessToken"]
        print(f"\nObtained JWT Token: {token[:30]}...")

    if token:
        print("\n--- Testing /me Endpoint with JWT Bearer Token ---")
        headers = {"Authorization": f"Bearer {token}"}
        status, me_res = make_request(f"{BASE_URL}/auth/me", headers=headers)
        print(f"/me Status [{status}]: {json.dumps(me_res, indent=2)}")

if __name__ == "__main__":
    run_tests()
