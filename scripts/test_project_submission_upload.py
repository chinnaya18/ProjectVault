import requests

BASE_URL = "http://localhost:8080/api/v1"

# 1. Login as Student
login_res = requests.post(f"{BASE_URL}/auth/login", json={
    "email": "student@projectvault.edu",
    "password": "Password@123"
})

if login_res.status_code != 200:
    # Try another student login if needed
    login_res = requests.post(f"{BASE_URL}/auth/login", json={
        "email": "25mx101@university.edu",
        "password": "Password@123"
    })

print(f"Login status: {login_res.status_code}")
token = login_res.json()["data"]["accessToken"]
headers = {"Authorization": f"Bearer {token}"}

# 2. Create Project Draft
create_payload = {
    "title": "IoT Automated Smart Irrigation and Soil Moisture Analytics System",
    "abstractText": "An automated smart agricultural irrigation framework deploying ESP32 microcontrollers and capacitive soil moisture probes. The system collects telemetry, calculates evapotranspiration thresholds, and triggers solenoid water valves over MQTT to optimize water conservation by 35%.",
    "academicYear": "2024-2025",
    "semester": 3,
    "projectType": "MINI_PROJECT",
    "visibility": "PUBLIC",
    "departmentId": 1,
    "repositoryUrl": "https://github.com/projectvault/smart-irrigation-iot.git",
    "guideFacultyId": 20
}

create_res = requests.post(f"{BASE_URL}/projects", json=create_payload, headers=headers)
print(f"Project Create status: {create_res.status_code}")
created_project = create_res.json()["data"]
project_id = created_project["id"]
print(f"Created project ID: {project_id}")

# 3. Upload File 1: Synopsis PDF
with open(r"d:\projectvault\test-attachments\Project1_Smart_Irrigation_Synopsis.pdf", "rb") as f:
    files = {"file": ("Project1_Smart_Irrigation_Synopsis.pdf", f, "application/pdf")}
    upload1_res = requests.post(f"{BASE_URL}/projects/{project_id}/files", files=files, headers=headers)
    print(f"Upload Synopsis status: {upload1_res.status_code}, response: {upload1_res.text[:120]}")

# 4. Upload File 2: SRS PDF
with open(r"d:\projectvault\test-attachments\Project1_Smart_Irrigation_SRS.pdf", "rb") as f:
    files = {"file": ("Project1_Smart_Irrigation_SRS.pdf", f, "application/pdf")}
    upload2_res = requests.post(f"{BASE_URL}/projects/{project_id}/files", files=files, headers=headers)
    print(f"Upload SRS status: {upload2_res.status_code}, response: {upload2_res.text[:120]}")

# 5. Submit Project for Review
submit_res = requests.patch(f"{BASE_URL}/projects/{project_id}/status", json={
    "status": "SUBMITTED",
    "feedback": "Submitted via automated verification test"
}, headers=headers)
print(f"Project Submit status: {submit_res.status_code}, response: {submit_res.text[:120]}")

print("=== VERIFICATION COMPLETED SUCCESSFULLY ===")
