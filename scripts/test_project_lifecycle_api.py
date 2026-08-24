import urllib.request
import json
import time

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

def login(email, password):
    payload = {"email": email, "password": password}
    status, res = make_request(f"{BASE_URL}/auth/login", method="POST", data=payload)
    if status == 200 and res.get("success"):
        return res["data"]["accessToken"]
    return None

def run_tests():
    print("--- 1. Testing Public Visitor Project Discovery (GET /projects) ---")
    status, public_res = make_request(f"{BASE_URL}/projects")
    print(f"Public Visitor List Status [{status}]: Approved Public Projects Count = {public_res['data']['totalElements']}")
    for p in public_res['data']['content']:
        print(f"  - [{p['id']}] {p['title']} ({p['academicYear']}) - Status: {p['status']}, Vis: {p['visibility']}")

    print("\n--- 2. Student Authentication ---")
    student_token = login("25mx101@university.edu", "Password@123")
    if not student_token:
        print("Failed to authenticate student 25mx101@university.edu")
        return
    print(f"Student Token obtained: {student_token[:25]}...")
    headers_student = {"Authorization": f"Bearer {student_token}"}

    print("\n--- 3. Student Creates New Project Entry (POST /projects) ---")
    create_project_payload = {
        "title": "Autonomous Drone Path Planning via Q-Learning",
        "abstractText": "An intelligent reinforcement learning framework for quadcopter collision avoidance in dense obstacle fields.",
        "academicYear": "2025-2026",
        "semester": 4,
        "projectType": "CAPSTONE",
        "visibility": "PUBLIC",
        "departmentId": 1,
        "guideFacultyId": 2,
        "repositoryUrl": "https://github.com/example/drone-q-learning"
    }
    status, create_res = make_request(f"{BASE_URL}/projects", method="POST", data=create_project_payload, headers=headers_student)
    print(f"Create Project Status [{status}]: {create_res.get('message')}")
    project_id = create_res.get("data", {}).get("id")

    print("\n--- 4. Faculty Authentication & Review ---")
    faculty_token = login("geetha@university.edu", "Password@123")
    if not faculty_token:
        print("Failed to authenticate faculty geetha@university.edu")
        return
    print(f"Faculty Token obtained: {faculty_token[:25]}...")
    headers_faculty = {"Authorization": f"Bearer {faculty_token}"}
    
    # Test 4a: Student submits draft project (DRAFT -> SUBMITTED)
    print("  4a. Transitioning DRAFT -> SUBMITTED (Student)")
    trans_payload = {"status": "SUBMITTED", "feedback": "Submitting capstone project for faculty review."}
    status, trans_res = make_request(f"{BASE_URL}/projects/{project_id}/status", method="PATCH", data=trans_payload, headers=headers_student)
    print(f"  Status [{status}]: Project is now -> {trans_res['data']['status']}")

    # Test 4b: Student attempts illegal transition SUBMITTED -> APPROVED (Should fail 400/403)
    print("\n  4b. Testing Illegal Transition SUBMITTED -> APPROVED by Student (Expect Failure)")
    trans_illegal = {"status": "APPROVED"}
    status, err_res = make_request(f"{BASE_URL}/projects/{project_id}/status", method="PATCH", data=trans_illegal, headers=headers_student)
    print(f"  Illegal Transition Result [{status}]: {err_res.get('message') or err_res.get('error')}")

    print("\n--- 5. Faculty Review Workflow ---")

    # Test 5a: Faculty moves SUBMITTED -> UNDER_REVIEW
    print("  5a. Moves SUBMITTED -> UNDER_REVIEW")
    trans_review = {"status": "UNDER_REVIEW", "feedback": "Evaluation started."}
    status, review_res = make_request(f"{BASE_URL}/projects/{project_id}/status", method="PATCH", data=trans_review, headers=headers_faculty)
    print(f"  Status [{status}]: Project is now -> {review_res.get('data', {}).get('status')}")

    # Test 5b: Faculty/Admin approves project UNDER_REVIEW -> APPROVED
    print("\n  5b. Approves project UNDER_REVIEW -> APPROVED")
    trans_approve = {"status": "APPROVED", "feedback": "Excellent methodology and validation."}
    status, approve_res = make_request(f"{BASE_URL}/projects/{project_id}/status", method="PATCH", data=trans_approve, headers=headers_faculty)
    print(f"  Status [{status}]: Project is now -> {approve_res['data']['status']}")

    print("\n--- 6. Public Visitor Verification of Newly Approved Project ---")
    status, public_after = make_request(f"{BASE_URL}/projects")
    print(f"Public Visitor List Status [{status}]: Updated Approved Projects Count = {public_after['data']['totalElements']}")
    for p in public_after['data']['content']:
        print(f"  - [{p['id']}] {p['title']} ({p['academicYear']}) - Status: {p['status']}")

if __name__ == "__main__":
    run_tests()
