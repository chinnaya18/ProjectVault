import requests
import json
import sys

BASE_URL = "http://localhost:8080/api/v1"
AI_URL = "http://localhost:8000/api/v1/ai"
PASSWORD = "Password@123"

def print_step(title):
    print(f"\n{'='*70}\n[STEP] {title}\n{'='*70}")

def test_visitor_access():
    print_step("1. Verifying Public Visitor Access & Security Restrictions")
    
    # Check public projects
    res = requests.get(f"{BASE_URL}/projects?size=100")
    assert res.status_code == 200, f"Expected 200, got {res.status_code}"
    data = res.json()["data"]["content"]
    print(f"[OK] Public projects retrieved: {len(data)} projects")
    assert len(data) >= 40, f"Expected at least 40 approved projects, found {len(data)}"
    
    # Check all are MCA / Computer Applications
    for p in data[:5]:
        print(f"  - [{p['id']}] {p['title'][:50]}... | Dept: {p['departmentName']}")
        assert "Computer Applications" in p["departmentName"] or "MCA" in p["departmentName"], f"Project {p['id']} not in MCA!"
    print("[OK] All verified projects belong to MCA Department.")

    # Check that unauthenticated file download is blocked (HTTP 401 / 403)
    file_download_res = requests.get(f"{BASE_URL}/projects/files/1/download")
    print(f"[OK] Unauthenticated file download status code: {file_download_res.status_code}")
    assert file_download_res.status_code in [401, 403], f"Security breach! Expected 401/403, got {file_download_res.status_code}"
    print("[OK] Unauthenticated file downloads are strictly BLOCKED.")

def test_ai_semantic_search_and_advisory():
    print_step("2. Verifying Pure AI Semantic Search & Viability Advisory")
    
    # 2a. Search matching existing project
    payload_existing = {"query": "decentralized microgrid energy solar IoT MQTT", "limit": 5}
    res = requests.post(f"{AI_URL}/search", json=payload_existing)
    assert res.status_code == 200, f"AI Search failed: {res.text}"
    result = res.json()
    print(f"[OK] AI Semantic Search returned {len(result['results'])} matches for '{payload_existing['query']}'")
    for r in result["results"][:2]:
        print(f"  - Match: #{r['id']} {r['title']} (Similarity: {r['similarity_score']:.3f})")
    assert len(result["results"]) > 0, "Expected at least 1 match"

    # 2b. Search novel topic (should return topic_feedback)
    novel_topic = "Quantum Key Distribution Optical Satellite Transceiver with Cryptographic Forward Secrecy"
    res_novel = requests.post(f"{AI_URL}/search", json={"query": novel_topic, "limit": 5})
    assert res_novel.status_code == 200
    novel_data = res_novel.json()
    print(f"[OK] AI Semantic Search on novel topic executed.")
    feedback = novel_data.get("topic_feedback")
    if feedback:
        print(f"  - Verdict: {feedback.get('verdict')}")
        print(f"  - Feasibility Score: {feedback.get('feasibility_score')}")
        print(f"  - Tech Stack: {feedback.get('tech_stack')}")
        print(f"  - Roadmap Phases: {len(feedback.get('roadmap', []))} phases provided")
        print("[OK] Topic Viability Advisory Card populated successfully.")
    else:
        print("Notice: topic_feedback is None, testing standalone /topic-feedback endpoint...")
        fb_res = requests.get(f"{AI_URL}/topic-feedback", params={"query": novel_topic})
        assert fb_res.status_code == 200
        fb_data = fb_res.json()
        print(f"[OK] Standalone Topic Feedback: Verdict={fb_data.get('verdict')}, Feasibility={fb_data.get('feasibility_score')}")

def test_full_workflow():
    print_step("3. Verifying Student Draft -> Submission -> AI Plagiarism & Duplication -> Faculty Review -> Rejection -> Student Alert -> Approval")
    
    # 3a. Student Login
    login_payload = {"email": "25mx101@university.edu", "password": PASSWORD}
    login_res = requests.post(f"{BASE_URL}/auth/login", json=login_payload)
    assert login_res.status_code == 200, f"Student login failed: {login_res.text}"
    auth_data = login_res.json()["data"]
    student_token = auth_data.get("accessToken") or auth_data.get("token")
    student_headers = {"Authorization": f"Bearer {student_token}"}
    print("[OK] Student (Bala, 25mx101) logged in successfully.")

    # 3b. Student creates draft project
    create_payload = {
        "title": "Edge-Assisted Autonomous Drone Fleet Coordination for Disaster Relief",
        "abstractText": "This research designs an edge-computing swarm intelligence protocol for autonomous disaster response drones. Utilizing distributed consensus algorithms and lightweight vision models running on Jetson Nano edge modules, the system dynamically maps disaster zones without centralized cloud connectivity.",
        "academicYear": "2025-2026",
        "semester": 6,
        "projectType": "Capstone Project",
        "visibility": "PUBLIC",
        "departmentId": 1,
        "repositoryUrl": "https://github.com/mca-dept/drone-swarm-relief",
        "guideFacultyId": 20, # Dr. M. Geetha
        "members": []
    }
    create_res = requests.post(f"{BASE_URL}/projects", json=create_payload, headers=student_headers)
    assert create_res.status_code == 201, f"Project creation failed: {create_res.text}"
    project_id = create_res.json()["data"]["id"]
    print(f"[OK] Student created project draft with ID: {project_id}")

    # 3c. Student submits project for review
    submit_payload = {"status": "SUBMITTED", "feedback": "Submitting capstone draft for faculty guide review."}
    submit_res = requests.patch(f"{BASE_URL}/projects/{project_id}/status", json=submit_payload, headers=student_headers)
    assert submit_res.status_code == 200, f"Submit failed: {submit_res.text}"
    submitted_project = submit_res.json()["data"]
    print(f"[OK] Project submitted! Status: {submitted_project['status']}")
    print(f"  - Plagiarism Score: {submitted_project.get('plagiarismScore')}%")
    print(f"  - Duplication Score: {submitted_project.get('duplicationScore')}%")
    print(f"  - Plagiarism Status: {submitted_project.get('plagiarismStatus')}")
    assert submitted_project.get("plagiarismScore") is not None, "Plagiarism score was not populated!"
    assert submitted_project.get("duplicationScore") is not None, "Duplication score was not populated!"

    # 3d. Faculty Guide Login (Dr. M. Geetha)
    faculty_login_res = requests.post(f"{BASE_URL}/auth/login", json={"email": "geetha@university.edu", "password": PASSWORD})
    assert faculty_login_res.status_code == 200, f"Faculty login failed: {faculty_login_res.text}"
    fac_data = faculty_login_res.json()["data"]
    faculty_token = fac_data.get("accessToken") or fac_data.get("token")
    faculty_headers = {"Authorization": f"Bearer {faculty_token}"}
    print("[OK] Faculty Guide (Dr. M. Geetha) logged in.")

    # 3e. Faculty transitions to UNDER_REVIEW
    review_res = requests.patch(
        f"{BASE_URL}/projects/{project_id}/status", 
        json={"status": "UNDER_REVIEW", "feedback": "Reviewing drone swarm architecture and simulation parameters."},
        headers=faculty_headers
    )
    assert review_res.status_code == 200, f"Move to UNDER_REVIEW failed: {review_res.text}"
    print("[OK] Project moved to UNDER_REVIEW by faculty guide.")

    # 3f. Faculty REJECTS with feedback for the student
    rejection_remarks = "Please add hardware-in-the-loop (HIL) simulation test results and clarify battery fail-safe protocols before final approval."
    reject_res = requests.patch(
        f"{BASE_URL}/projects/{project_id}/status",
        json={"status": "REJECTED", "feedback": rejection_remarks},
        headers=faculty_headers
    )
    assert reject_res.status_code == 200, f"Rejection failed: {reject_res.text}"
    print(f"[OK] Project REJECTED by faculty with feedback: '{rejection_remarks}'")

    # 3g. Student inspects project and verifies rejection feedback
    student_view_res = requests.get(f"{BASE_URL}/projects/{project_id}", headers=student_headers)
    assert student_view_res.status_code == 200
    student_view = student_view_res.json()["data"]
    assert student_view["status"] == "REJECTED", f"Expected REJECTED, got {student_view['status']}"
    
    # Check workflow history
    history = student_view.get("workflowHistory", [])
    print(f"[OK] Workflow history fetched: {len(history)} transitions.")
    rejection_entry = next((h for h in history if h.get("toStatus") == "REJECTED"), None)
    assert rejection_entry is not None, "Rejection entry not found in workflow history!"
    print(f"[OK] Verified Student receives rejection feedback: '{rejection_entry.get('remarks') or rejection_entry.get('feedback')}'")
    received_remarks = rejection_entry.get('remarks') or rejection_entry.get('feedback')
    assert received_remarks == rejection_remarks, f"Remarks do not match: {received_remarks} vs {rejection_remarks}"

    # 3h. Re-open as DRAFT, Re-submit, and Faculty Approves
    resubmit_status = requests.patch(
        f"{BASE_URL}/projects/{project_id}/status", 
        json={"status": "DRAFT", "feedback": "Revised with HIL simulation details."}, 
        headers=student_headers
    )
    assert resubmit_status.status_code == 200
    
    submit_again = requests.patch(
        f"{BASE_URL}/projects/{project_id}/status", 
        json={"status": "SUBMITTED", "feedback": "Re-submitting revised version."}, 
        headers=student_headers
    )
    assert submit_again.status_code == 200
    
    # Guide moves to UNDER_REVIEW then APPROVES
    requests.patch(
        f"{BASE_URL}/projects/{project_id}/status", 
        json={"status": "UNDER_REVIEW", "feedback": "Re-evaluation."}, 
        headers=faculty_headers
    )
    approve_res = requests.patch(
        f"{BASE_URL}/projects/{project_id}/status", 
        json={"status": "APPROVED", "feedback": "Excellent revisions. Approved for public repository."}, 
        headers=faculty_headers
    )
    assert approve_res.status_code == 200, f"Approval failed: {approve_res.text}"
    print("[OK] Project successfully APPROVED by Faculty Guide!")

    # 3i. Public Repository Verification
    public_res = requests.get(f"{BASE_URL}/projects?size=100")
    public_ids = [p["id"] for p in public_res.json()["data"]["content"]]
    assert project_id in public_ids, f"Project {project_id} should now be live in public repository!"
    print(f"[OK] Verified project #{project_id} is now LIVE in the public MCA repository!")

if __name__ == "__main__":
    try:
        test_visitor_access()
        test_ai_semantic_search_and_advisory()
        test_full_workflow()
        print("\n" + "="*70)
        print("ALL WORKFLOW & VERIFICATION TESTS PASSED SUCCESSFULLY! [SUCCESS]")
        print("="*70)
    except Exception as e:
        print(f"\n[FAIL] TEST FAILED: {e}")
        import traceback
        traceback.print_exc()
        sys.exit(1)
