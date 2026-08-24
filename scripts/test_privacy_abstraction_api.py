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
    status, res = make_request(f"{BASE_URL}/auth/login", method="POST", data={"email": email, "password": password})
    if status == 200 and res.get("success"):
        return res["data"]["accessToken"]
    return None

def test_privacy():
    print("=========================================================================")
    print("      RUNNING DATA PRIVACY & ROLE ABSTRACTION TEST SUITE                ")
    print("=========================================================================")

    # 1. Visitor Privacy Check
    print("\n--- 1. Testing Visitor Data Abstraction ---")
    st, res = make_request(f"{BASE_URL}/projects")
    visitor_items = res.get("data", {}).get("content", [])
    print(f"Visitor catalog projects count = {len(visitor_items)}")
    for p in visitor_items:
        print(f"  [Visible] #{p['id']} - {p['title']} ({p['status']})")
        assert p['status'] == 'APPROVED', f"PRIVACY VIOLATION: Non-approved project #{p['id']} leaked to Visitor!"

    st, res = make_request(f"{BASE_URL}/projects/1")
    print(f"Visitor direct access to Submitted Project #1 -> Status [{st}] (Expect 403 Forbidden)")
    assert st == 403, f"PRIVACY VIOLATION: Visitor accessed submitted project #1! Status: {st}"

    st, res = make_request(f"{BASE_URL}/projects/3")
    print(f"Visitor direct access to Draft Project #3 -> Status [{st}] (Expect 403 Forbidden)")
    assert st == 403, f"PRIVACY VIOLATION: Visitor accessed draft project #3! Status: {st}"

    # 2. Student 1 Privacy Check (25mx101@university.edu)
    print("\n--- 2. Testing Student 1 Data Abstraction (25mx101@university.edu) ---")
    s1_token = login("25mx101@university.edu", "Password@123")
    assert s1_token is not None, "Failed to authenticate Student 1"

    st, res = make_request(f"{BASE_URL}/projects", token=s1_token)
    s1_projects = res.get("data", {}).get("content", [])
    print(f"Student 1 retrieved projects count = {len(s1_projects)}")
    s1_ids = [p['id'] for p in s1_projects]
    print(f"Student 1 visible project IDs: {s1_ids}")
    assert 3 not in s1_ids, "PRIVACY VIOLATION: Student 3's DRAFT project #3 leaked to Student 1!"

    st, res = make_request(f"{BASE_URL}/projects/1", token=s1_token)
    print(f"Student 1 direct access to Own Submitted Project #1 -> Status [{st}] (Expect 200 OK)")
    assert st == 200, "Student 1 should be able to view their own submitted project"

    st, res = make_request(f"{BASE_URL}/projects/3", token=s1_token)
    print(f"Student 1 direct access to Peer's Draft Project #3 -> Status [{st}] (Expect 403 Forbidden)")
    assert st == 403, f"PRIVACY VIOLATION: Student 1 accessed Peer's draft project #3! Status: {st}"

    # 3. Faculty Guide Privacy Check (geetha@university.edu)
    print("\n--- 3. Testing Faculty Guide Data Abstraction (geetha@university.edu) ---")
    g_token = login("geetha@university.edu", "Password@123")
    assert g_token is not None, "Failed to authenticate Prof. Geetha"

    st, res = make_request(f"{BASE_URL}/projects/1", token=g_token)
    print(f"Prof. Geetha direct access to Guided Project #1 -> Status [{st}] (Expect 200 OK)")
    assert st == 200, "Prof. Geetha should be able to view project #1 assigned to her"

    st, res = make_request(f"{BASE_URL}/projects/3", token=g_token)
    print(f"Prof. Geetha direct access to Un-guided Draft Project #3 -> Status [{st}] (Expect 403 Forbidden)")
    assert st == 403, f"PRIVACY VIOLATION: Prof. Geetha accessed unassigned draft project #3! Status: {st}"

    # 4. Cross-Faculty Evaluation Restriction Check (gayathri@university.edu)
    print("\n--- 4. Testing Cross-Faculty Evaluation Restrictions ---")
    gayathri_token = login("gayathri@university.edu", "Password@123")
    assert gayathri_token is not None, "Failed to authenticate Prof. Gayathri"

    st, res = make_request(f"{BASE_URL}/projects/1/status", method="PATCH", data={"status": "UNDER_REVIEW"}, token=gayathri_token)
    print(f"Prof. Gayathri attempting to transition Prof. Geetha's Project #1 -> Status [{st}] (Expect 403 Forbidden)")
    assert st == 403, f"PRIVACY VIOLATION: Prof. Gayathri evaluated project #1 assigned to Prof. Geetha! Status: {st}"

    # 5. Admin Governance Check (admin@university.edu)
    print("\n--- 5. Testing Admin Governance Access ---")
    admin_token = login("admin@university.edu", "Password@123")
    assert admin_token is not None, "Failed to authenticate Admin"

    st, res = make_request(f"{BASE_URL}/projects/3", token=admin_token)
    print(f"Admin direct access to Draft Project #3 -> Status [{st}] (Expect 200 OK)")
    assert st == 200, "Admin must maintain governance access to all projects"

    print("\n=========================================================================")
    print("  ALL PRIVACY & ROLE ABSTRACTION ASSERTIONS PASSED SUCCESSFULLY (100%)   ")
    print("=========================================================================")

if __name__ == "__main__":
    test_privacy()
