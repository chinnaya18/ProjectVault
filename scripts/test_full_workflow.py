import urllib.request
import json

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

def test_workflow():
    print("=== STARTING END-TO-END WORKFLOW TEST ===")

    # 1. Login as Student
    status, res = req(f"{BASE_URL}/auth/login", method="POST", data={
        "email": "25mx101@university.edu", "password": "Password@123"
    })
    assert status == 200, f"Student login failed: {res}"
    student_token = res["data"]["accessToken"]
    student_id = res["data"]["user"]["id"]
    print(f"[OK] Step 1: Student Logged In (User #{student_id})")

    # 2. Get Department ID
    status, depts_res = req(f"{BASE_URL}/departments", token=student_token)
    dept_id = depts_res["data"]["content"][0]["id"]
    dept_name = depts_res["data"]["content"][0]["name"]
    print(f"[OK] Step 2: Retrieved Department '{dept_name}' (ID #{dept_id})")

    # 3. Student Creates Project Draft
    project_payload = {
        "title": "Autonomous Drone Navigation via Deep Reinforcement Learning",
        "abstractText": "This project presents a real-time autonomous pathfinding system for indoor UAVs using deep Q-learning, obstacle avoidance LiDAR arrays, and ROS2.",
        "academicYear": "2025-2026",
        "semester": 4,
        "projectType": "Major Project",
        "visibility": "PUBLIC",
        "departmentId": dept_id,
        "repositoryUrl": "https://github.com/mca-students/uav-navigation-rl",
        "guideFacultyId": 2, # Geetha
        "members": [{"userId": student_id, "memberRole": "Project Lead / Author"}]
    }
    status, proj_res = req(f"{BASE_URL}/projects", method="POST", data=project_payload, token=student_token)
    assert status == 201, f"Project creation failed: {proj_res}"
    proj_id = proj_res["data"]["id"]
    print(f"[OK] Step 3: Student Created Project Draft #{proj_id}: '{proj_res['data']['title']}' [Status: {proj_res['data']['status']}]")

    # 4. Student Submits Project for Faculty Review
    status, submit_res = req(f"{BASE_URL}/projects/{proj_id}/status", method="PATCH", data={"status": "SUBMITTED"}, token=student_token)
    assert status == 200, f"Submit failed: {submit_res}"
    print(f"[OK] Step 4: Student Submitted Project #{proj_id} for Faculty Review [Status: {submit_res['data']['status']}]")

    # 5. Login as Faculty
    status, fac_res = req(f"{BASE_URL}/auth/login", method="POST", data={
        "email": "geetha@university.edu", "password": "Password@123"
    })
    assert status == 200, f"Faculty login failed: {fac_res}"
    faculty_token = fac_res["data"]["accessToken"]
    print(f"[OK] Step 5: Faculty Logged In (Geetha)")

    # 6. Faculty Reviews and Approves Project
    status, review_res = req(f"{BASE_URL}/projects/{proj_id}/status", method="PATCH", data={"status": "UNDER_REVIEW"}, token=faculty_token)
    assert status == 200, f"Review failed: {review_res}"
    print(f"[OK] Step 6a: Faculty Moved Project #{proj_id} to [Status: UNDER_REVIEW]")

    status, approve_res = req(f"{BASE_URL}/projects/{proj_id}/status", method="PATCH", data={"status": "APPROVED"}, token=faculty_token)
    assert status == 200, f"Approval failed: {approve_res}"
    print(f"[OK] Step 6b: Faculty APPROVED Project #{proj_id}! [Status: APPROVED]")

    # 7. Visitor Public Catalog Check (Unauthenticated)
    status, pub_res = req(f"{BASE_URL}/projects")
    assert status == 200
    pub_projects = pub_res["data"]["content"]
    assert len(pub_projects) >= 1, "Approved project should be visible in public catalog!"
    print(f"[OK] Step 7: Public Visitor Catalog correctly displays {len(pub_projects)} approved project: '{pub_projects[0]['title']}'")

    # 8. Admin User Management Check
    status, admin_res = req(f"{BASE_URL}/auth/login", method="POST", data={
        "email": "admin@university.edu", "password": "Password@123"
    })
    assert status == 200
    admin_token = admin_res["data"]["accessToken"]

    status, users_res = req(f"{BASE_URL}/users?size=10", token=admin_token)
    assert status == 200
    user_count = len(users_res["data"]["content"])
    print(f"[OK] Step 8: System Admin retrieved {user_count} registered users from User Management Directory.")

    print("\n=== ALL WORKFLOW STAGES VERIFIED SUCCESSFULLY! ===")

if __name__ == "__main__":
    test_workflow()
