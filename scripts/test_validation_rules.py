import urllib.request
import json
import uuid

BASE_URL = "http://localhost:8080/api/v1"

def req(url, method="GET", data=None, token=None):
    headers = {"Content-Type": "application/json"}
    if token:
        headers["Authorization"] = f"Bearer {token}"
    encoded = json.dumps(data).encode("utf-8") if data else None
    r = urllib.request.Request(url, data=encoded, headers=headers, method=method)
    try:
        with urllib.request.urlopen(r) as resp:
            return resp.status, json.loads(resp.read().decode("utf-8"))
    except urllib.error.HTTPError as e:
        body = e.read().decode("utf-8")
        try:
            return e.code, json.loads(body)
        except Exception:
            return e.code, {"raw": body}

def main():
    print("=== TESTING MANDATORY VALIDATIONS ===")

    # 1. Register with missing departmentId -> Expect 400
    random_email = f"test_{uuid.uuid4().hex[:6]}@university.edu"
    st, res = req(f"{BASE_URL}/auth/register", method="POST", data={
        "name": "Test Student",
        "rollNo": "25MX999",
        "email": random_email,
        "password": "Password@123"
    })
    print(f"1. Register without departmentId: Status {st} -> {res.get('message', res)}")
    assert st == 400, f"Expected 400, got {st}"

    # 2. Register with missing rollNo -> Expect 400
    st, res = req(f"{BASE_URL}/auth/register", method="POST", data={
        "name": "Test Student",
        "email": random_email,
        "password": "Password@123",
        "departmentId": 1
    })
    print(f"2. Register without rollNo: Status {st} -> {res.get('message', res)}")
    assert st == 400, f"Expected 400, got {st}"

    # 3. Register with all mandatory fields -> Expect 200/201
    st, res = req(f"{BASE_URL}/auth/register", method="POST", data={
        "name": "Test Student",
        "rollNo": "25MX999",
        "email": random_email,
        "password": "Password@123",
        "departmentId": 1
    })
    print(f"3. Register with complete fields: Status {st} -> Success")
    assert st == 200 or st == 201, f"Expected 200/201, got {st}"
    token = res["data"]["accessToken"]

    # 4. Create project without guideFacultyId -> Expect 400
    st, res = req(f"{BASE_URL}/projects", method="POST", data={
        "title": "Autonomous Robotics Vision",
        "abstractText": "Detailed abstract of robotics vision system with deep neural networks.",
        "academicYear": "2025-2026",
        "semester": 4,
        "projectType": "CAPSTONE",
        "visibility": "PUBLIC",
        "departmentId": 1,
        "repositoryUrl": "https://github.com/test/robotics"
    }, token=token)
    print(f"4. Create project without guideFacultyId: Status {st} -> {res.get('message', res)}")
    assert st == 400, f"Expected 400, got {st}"

    # 5. Create project with guideFacultyId -> Expect 201
    st, res = req(f"{BASE_URL}/projects", method="POST", data={
        "title": "Autonomous Robotics Vision",
        "abstractText": "Detailed abstract of robotics vision system with deep neural networks.",
        "academicYear": "2025-2026",
        "semester": 4,
        "projectType": "CAPSTONE",
        "visibility": "PUBLIC",
        "departmentId": 1,
        "repositoryUrl": "https://github.com/test/robotics",
        "guideFacultyId": 2
    }, token=token)
    print(f"5. Create project with guideFacultyId: Status {st} -> Project ID #{res['data']['id']}, Guide: {res['data']['guideFacultyName']}")
    assert st == 201, f"Expected 201, got {st}"
    proj_id = res['data']['id']

    # 6. Submit project for review -> Expect 200
    st, res = req(f"{BASE_URL}/projects/{proj_id}/status", method="PATCH", data={"status": "SUBMITTED"}, token=token)
    print(f"6. Submit project with guide: Status {st} -> Status '{res['data']['status']}'")
    assert st == 200, f"Expected 200, got {st}"

    print("\nALL MANDATORY VALIDATION TESTS PASSED SUCCESSFULLY! 🎉")

if __name__ == "__main__":
    main()
