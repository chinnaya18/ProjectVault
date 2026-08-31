import time
import requests
import json
import subprocess
import sys
import os

BASE_URL = "http://127.0.0.1:8000"

def test_endpoints():
    print("=" * 60)
    print("TESTING PROJECTVAULT AI SERVICE API ENDPOINTS")
    print("=" * 60)

    # 1. Health Check
    print("\n[1] Testing GET /health...")
    try:
        r = requests.get(f"{BASE_URL}/health", timeout=10)
        print(f"Status Code: {r.status_code}")
        print("Response:", json.dumps(r.json(), indent=2))
        assert r.status_code == 200
        assert r.json()["status"] in ["UP", "DEGRADED"]
        print(">>> Health Check: PASSED")
    except Exception as e:
        print(f">>> Health Check FAILED: {e}")
        return False

    # 2. Sync Embeddings
    print("\n[2] Testing POST /api/v1/ai/sync-embeddings...")
    try:
        r = requests.post(f"{BASE_URL}/api/v1/ai/sync-embeddings", json={"force_refresh": True}, timeout=30)
        print(f"Status Code: {r.status_code}")
        print("Response:", json.dumps(r.json(), indent=2))
        assert r.status_code == 200
        print(">>> Sync Embeddings: PASSED")
    except Exception as e:
        print(f">>> Sync Embeddings FAILED: {e}")
        return False

    # 3. Direct Embedding Generation
    print("\n[3] Testing POST /api/v1/ai/embed...")
    try:
        r = requests.post(f"{BASE_URL}/api/v1/ai/embed", json={"text": "Deep learning agricultural drone telemetry"}, timeout=15)
        print(f"Status Code: {r.status_code}")
        data = r.json()
        print(f"Generated Vector Dimension: {data.get('dimension')}, Model: {data.get('model')}")
        assert r.status_code == 200
        assert data.get("dimension") == 384
        print(">>> Embedding Generation: PASSED")
    except Exception as e:
        print(f">>> Embedding Generation FAILED: {e}")
        return False

    # 4. Semantic Search
    print("\n[4] Testing POST /api/v1/ai/search...")
    search_queries = [
        "plant leaf disease detection using neural networks",
        "smart parking IoT sensors MQTT",
        "blockchain certificate verification"
    ]
    for q in search_queries:
        try:
            r = requests.post(f"{BASE_URL}/api/v1/ai/search", json={"query": q, "limit": 3}, timeout=15)
            print(f"\nQuery: '{q}' -> Status: {r.status_code}")
            data = r.json()
            print(f"Total Results: {data.get('total_results')}, Time: {data.get('execution_time_ms')}ms")
            for res in data.get("results", []):
                print(f"  - [Score {res['similarity_score']:.3f}] #{res['id']} {res['title']} ({res.get('department_name')})")
            assert r.status_code == 200
        except Exception as e:
            print(f">>> Semantic Search FAILED for '{q}': {e}")
            return False
    print(">>> Semantic Search: PASSED")

    # 5. RAG Question Answering
    print("\n[5] Testing POST /api/v1/ai/ask...")
    questions = [
        "What projects are available related to agriculture or plant disease?",
        "Which project uses blockchain technology for certificates?"
    ]
    for q in questions:
        try:
            r = requests.post(f"{BASE_URL}/api/v1/ai/ask", json={"question": q, "limit": 3}, timeout=20)
            print(f"\nQuestion: '{q}' -> Status: {r.status_code}")
            data = r.json()
            print(f"Answer: {data.get('answer')}")
            print(f"Grounded: {data.get('grounded')}, Confidence: {data.get('confidence')}")
            print("Citations:", [c['title'] for c in data.get("referenced_projects", [])])
            assert r.status_code == 200
        except Exception as e:
            print(f">>> RAG QA FAILED for '{q}': {e}")
            return False
    print(">>> RAG Question Answering: PASSED")

    # 6. Project Content Analysis
    print("\n[6] Testing POST /api/v1/ai/analyze...")
    try:
        sample_project = {
            "title": "Quantum-Resistant Cryptographic Microservice Architecture",
            "abstract": "A cloud-native microservice security layer implementing lattice-based post-quantum cryptography algorithms for securing distributed enterprise databases.",
            "tech_stack": ["Python", "FastAPI", "Lattice Cryptography"],
            "save_to_db": False
        }
        r = requests.post(f"{BASE_URL}/api/v1/ai/analyze", json=sample_project, timeout=20)
        print(f"Status Code: {r.status_code}")
        print("Response:", json.dumps(r.json(), indent=2))
        assert r.status_code == 200
        assert "domain" in r.json()
        print(">>> Project Content Analysis: PASSED")
    except Exception as e:
        print(f">>> Project Content Analysis FAILED: {e}")
        return False

    # 7. Alias Endpoints (/api/ai/search, /api/ai/ask, /api/ai/analyze)
    print("\n[7] Testing Alias Endpoints (/api/ai/*)...")
    try:
        r1 = requests.post(f"{BASE_URL}/api/ai/search", json={"query": "IoT", "limit": 2}, timeout=10)
        r2 = requests.post(f"{BASE_URL}/api/ai/ask", json={"question": "Any IoT projects?", "limit": 2}, timeout=10)
        assert r1.status_code == 200
        assert r2.status_code == 200
        print(">>> Alias Endpoints: PASSED")
    except Exception as e:
        print(f">>> Alias Endpoints FAILED: {e}")
        return False

    print("\n" + "=" * 60)
    print("ALL AI SERVICE ENDPOINTS PASSED VERIFICATION!")
    print("=" * 60)
    return True

if __name__ == "__main__":
    test_endpoints()
