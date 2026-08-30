import urllib.request
import json

BASE_URL = "http://localhost:8080/api/v1"

def fetch_json(url):
    req = urllib.request.Request(url, headers={"Content-Type": "application/json"})
    with urllib.request.urlopen(req) as resp:
        return json.loads(resp.read().decode("utf-8"))

def verify():
    print("--- 1. Testing Public Projects Catalog Endpoint ---")
    data = fetch_json(f"{BASE_URL}/projects")
    projects = data.get("data", {}).get("content", [])
    print(f"Retrieved {len(projects)} public projects.")
    for p in projects:
        print(f"  Project #{p['id']}: '{p['title'][:40]}...'")
        print(f"    Author: {p.get('createdByUserName')} | RollNo: {p.get('createdByRollNo')}")
        print(f"    Guide:  {p.get('guideFacultyName')}")

    print("\n--- 2. Public Health Status ---")
    health = fetch_json(f"{BASE_URL}/health")
    print(f"Health: {health.get('message')}")

if __name__ == "__main__":
    verify()
