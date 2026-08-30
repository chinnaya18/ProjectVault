import urllib.request
import json
import time

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

def seed_flow_data():
    print("--- 1. Registering/Updating User Accounts & Roles ---")
    accounts = [
        ("admin@university.edu", "Password@123", "System Admin", None, "ADMIN"),
        ("geetha@university.edu", "Password@123", "Geetha", None, "FACULTY"),
        ("gayathri@university.edu", "Password@123", "Gayathri", None, "FACULTY"),
        ("manavalan@university.edu", "Password@123", "Manavalan", None, "FACULTY"),
        ("25mx101@university.edu", "Password@123", "Bala", "25MX101", "STUDENT"),
        ("25mx102@university.edu", "Password@123", "Gopi", "25MX102", "STUDENT"),
        ("25mx103@university.edu", "Password@123", "Kaleel", "25MX103", "STUDENT"),
    ]

    for email, pwd, name, roll_no, _ in accounts:
        payload = {"email": email, "password": pwd, "name": name, "departmentId": 1}
        if roll_no:
            payload["rollNo"] = roll_no
        status, res = make_request(f"{BASE_URL}/auth/register", method="POST", data=payload)
        print(f"Register {email}: Status [{status}]")

    # Login as Admin
    status, login_res = make_request(f"{BASE_URL}/auth/login", method="POST", data={
        "email": "admin@university.edu", "password": "Password@123"
    })
    admin_token = login_res.get("data", {}).get("accessToken")
    print(f"Admin Login Status: [{status}]")

    if not admin_token:
        print("Failed to obtain Admin token")
        return

    # Update Roles
    status, users_res = make_request(f"{BASE_URL}/users?size=100", token=admin_token)
    users = users_res.get("data", {}).get("content", [])
    user_id_map = {u["email"]: u["id"] for u in users}

    role_map = {email: role for email, _, _, _, role in accounts}
    for email, role in role_map.items():
        uid = user_id_map.get(email)
        if uid:
            r_status, _ = make_request(f"{BASE_URL}/users/{uid}/role", method="PUT", data={"role": role}, token=admin_token)
            print(f"User #{uid} ({email}) set to {role} [Status {r_status}]")

    print("\n--- 2. Seeding Sample Projects for Manual Verification Flow ---")
    geetha_id = user_id_map.get("geetha@university.edu", 2)
    gayathri_id = user_id_map.get("gayathri@university.edu", 3)
    manavalan_id = user_id_map.get("manavalan@university.edu", 4)

    # Login as Student 1 (25mx101)
    status, s1_login = make_request(f"{BASE_URL}/auth/login", method="POST", data={
        "email": "25mx101@university.edu", "password": "Password@123"
    })
    s1_token = s1_login.get("data", {}).get("accessToken")
    s1_id = s1_login.get("data", {}).get("user", {}).get("id")

    # Project 1: Submitted project by Student 1 (Bala) assigned to Prof. Geetha
    if s1_token:
        p1_data = {
            "title": "Autonomous Drone Fleet Management for Smart Agriculture",
            "abstractText": "This capstone project implements real-time autonomous pathfinding, multispectral sensor telemetry processing, and crop yield forecasting using deep neural networks.",
            "academicYear": "2025-2026",
            "semester": 6,
            "projectType": "CAPSTONE",
            "visibility": "PUBLIC",
            "departmentId": 1,
            "repositoryUrl": "https://github.com/university-research/drone-fleet-agri",
            "guideFacultyId": geetha_id
        }
        st, p1_res = make_request(f"{BASE_URL}/projects", method="POST", data=p1_data, token=s1_token)
        p1_id = p1_res.get("data", {}).get("id")
        print(f"Student 1 Created Project #1: Status [{st}] (User #{s1_id})")
        if p1_id:
            # Transition to SUBMITTED
            make_request(f"{BASE_URL}/projects/{p1_id}/status", method="PATCH", data={"status": "SUBMITTED"}, token=s1_token)
            print(f"Project #{p1_id} transitioned to SUBMITTED for Prof. Geetha's review")

    # Login as Student 2 (25mx102)
    status, s2_login = make_request(f"{BASE_URL}/auth/login", method="POST", data={
        "email": "25mx102@university.edu", "password": "Password@123"
    })
    s2_token = s2_login.get("data", {}).get("accessToken")
    s2_id = s2_login.get("data", {}).get("user", {}).get("id")

    # Project 2: Submitted project by Student 2 (Gopi) assigned to Prof. Gayathri
    if s2_token:
        p2_data = {
            "title": "Quantum-Resistant Cryptographic Microservice Architecture",
            "abstractText": "A cloud-native microservice security layer implementing lattice-based post-quantum cryptography algorithms for securing distributed enterprise databases.",
            "academicYear": "2025-2026",
            "semester": 6,
            "projectType": "RESEARCH",
            "visibility": "PUBLIC",
            "departmentId": 1,
            "repositoryUrl": "https://github.com/university-research/quantum-crypto-layer",
            "guideFacultyId": gayathri_id
        }
        st, p2_res = make_request(f"{BASE_URL}/projects", method="POST", data=p2_data, token=s2_token)
        p2_id = p2_res.get("data", {}).get("id")
        print(f"Student 2 Created Project #2: Status [{st}] (User #{s2_id})")
        if p2_id:
            # Transition to APPROVED (Approved project visible in Visitor & Catalog view)
            make_request(f"{BASE_URL}/projects/{p2_id}/status", method="PATCH", data={"status": "SUBMITTED"}, token=s2_token)
            # Login as Prof. Gayathri to approve
            status, g_login = make_request(f"{BASE_URL}/auth/login", method="POST", data={
                "email": "gayathri@university.edu", "password": "Password@123"
            })
            g_token = g_login.get("data", {}).get("accessToken")
            if g_token:
                make_request(f"{BASE_URL}/projects/{p2_id}/status", method="PATCH", data={"status": "UNDER_REVIEW"}, token=g_token)
                make_request(f"{BASE_URL}/projects/{p2_id}/status", method="PATCH", data={"status": "APPROVED"}, token=g_token)
                print(f"Project #{p2_id} Approved by Prof. Gayathri (Visible in Visitor View & Catalog)")

    # Login as Student 3 (25mx103)
    status, s3_login = make_request(f"{BASE_URL}/auth/login", method="POST", data={
        "email": "25mx103@university.edu", "password": "Password@123"
    })
    s3_token = s3_login.get("data", {}).get("accessToken")
    s3_id = s3_login.get("data", {}).get("user", {}).get("id")

    # Project 3: DRAFT project by Student 3 (Kaleel) assigned to Prof. Manavalan
    if s3_token:
        p3_data = {
            "title": "Decentralized Medical Health Records on Consortium Blockchain",
            "abstractText": "This project explores zero-knowledge proofs and smart contracts to ensure patient data privacy and cross-hospital interoperability.",
            "academicYear": "2025-2026",
            "semester": 6,
            "projectType": "CAPSTONE",
            "visibility": "PUBLIC",
            "departmentId": 1,
            "repositoryUrl": "https://github.com/university-research/health-blockchain",
            "guideFacultyId": manavalan_id
        }
        st, p3_res = make_request(f"{BASE_URL}/projects", method="POST", data=p3_data, token=s3_token)
        print(f"Student 3 Created Project #3 (DRAFT): Status [{st}] (User #{s3_id})")

    print("\n--- Seeding Complete! Ready for Manual Flow Verification ---")

if __name__ == "__main__":
    seed_flow_data()
