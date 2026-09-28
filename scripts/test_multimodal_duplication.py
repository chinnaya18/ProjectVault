import asyncio
import json
import os
import sys

# Ensure ai-service modules are importable
sys.path.insert(0, os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "ai-service"))

from app.services.analysis_service import analysis_service
from app.services.code_similarity_service import code_similarity_service
from app.services.embedding_service import embedding_service

async def run_test():
    print("=" * 70)
    print("TEST CASE: SAME CODE PROJECT BUT DIFFERENT SRS & ATTACHMENTS")
    print("=" * 70)

    # 1. Code Samples (Identical underlying logic with different comments/variable names)
    code_project_a = """
import time
import paho.mqtt.client as mqtt
from fastapi import FastAPI

app = FastAPI()
SOIL_THRESHOLD = 35.0

def read_moisture_sensor(pin: int) -> float:
    # Read analog moisture voltage from ESP32 ADC
    raw_val = 1024 # mock analog reading
    voltage = (raw_val / 4095.0) * 3.3
    moisture_pct = (1.0 - (voltage / 3.3)) * 100.0
    return round(moisture_pct, 2)

@app.get("/api/irrigate")
def trigger_valve(duration_sec: int = 10):
    val = read_moisture_sensor(34)
    if val < SOIL_THRESHOLD:
        print(f"Activating solenoid valve for {duration_sec}s")
        return {"status": "IRRIGATING", "moisture": val}
    return {"status": "OPTIMAL", "moisture": val}
"""

    code_project_b = """
# Advanced Agricultural Hydro-Dynamics Telemetry
import time
import paho.mqtt.client as mqtt_client
from fastapi import FastAPI

app = FastAPI()
HYDRATION_LIMIT = 35.0

def sample_substrate_hydrology(gpio_channel: int) -> float:
    \"\"\"Obtain normalized fluid saturation coefficient.\"\"\"
    digitized_sample = 1024
    electrical_potential = (digitized_sample / 4095.0) * 3.3
    saturation_index = (1.0 - (electrical_potential / 3.3)) * 100.0
    return round(saturation_index, 2)

@app.get("/api/irrigate")
def engage_dispersion_cycle(run_duration: int = 10):
    level = sample_substrate_hydrology(34)
    if level < HYDRATION_LIMIT:
        print(f"Opening hydraulic actuator for {run_duration}s")
        return {"status": "IRRIGATING", "moisture": level}
    return {"status": "OPTIMAL", "moisture": level}
"""

    # 2. Test Code AST and Token Similarity
    print("\n[1] Testing Code AST & Structural Similarity Engine:")
    code_sim = code_similarity_service.compare_code_snippets(code_project_a, code_project_b, language="python")
    print(f"  • Source Code AST Jaccard Similarity: {code_sim * 100:.1f}%")

    # 3. Test Repository URL Normalization & Linkage
    print("\n[2] Testing Git Repository Canonical Linkage:")
    repo_a = "https://github.com/mca-research/smart-agro-irrigation.git"
    repo_b = "git@github.com:mca-research/smart-agro-irrigation/tree/main"
    is_same_repo = code_similarity_service.check_repo_exact_match(repo_a, repo_b)
    print(f"  • Repo A: {repo_a}")
    print(f"  • Repo B: {repo_b}")
    print(f"  • Canonical Match Detected: {is_same_repo} (100% Codebase Identity)")

    # 4. Compare SRS Text Vector Cosine Similarity vs. Codebase Similarity
    print("\n[3] Comparing Disguised SRS Text vs Code Base:")
    title_a = "IoT Precision Drip Irrigation and Soil Moisture Telemetry"
    abstract_a = "An automated agricultural IoT moisture regulation station utilizing soil sensor probes and ESP32 microcontrollers to dispatch irrigation valves."

    title_b = "Autonomous Edge-AI Soil Hydro-Dynamics Controller Framework"
    abstract_b = "A decentralized agronomy telemetry edge system managing localized fluid dispersion cycles through algorithmic moisture threshold feedback loops."

    emb_a = embedding_service.generate_project_embedding(title_a, abstract_a)
    emb_b = embedding_service.generate_project_embedding(title_b, abstract_b)
    text_cosine = embedding_service.cosine_similarity(emb_a, emb_b)

    print(f"  • Text-Only Vector Cosine Similarity: {text_cosine * 100:.1f}% (Appears as moderate overlap due to paraphrasing)")
    print(f"  • Source Code AST Similarity:        {code_sim * 100:.1f}% (Structural code match)")
    print(f"  • Git Repository Linkage:            {'100.0%' if is_same_repo else '0.0%'}")

    # 5. Full Multi-Modal AI Plagiarism & Duplication Scan against PostgreSQL Project #1
    print("\n[4] Running Full Multi-Modal Duplication Scan against ProjectVault Database (Project #1):")
    disguised_title = "Decentralized Aerial Soil Moisture Optimization Framework"
    disguised_abstract = "An algorithmic unmanned aerial telemetry platform collecting multispectral vegetative reflectance metrics to optimize nitrogen irrigation."
    cloned_repo = "git@github.com:mca-research/drone-fleet-agri/tree/main"

    report = await analysis_service.analyze_plagiarism_and_duplication(
        project_id=None,
        title=disguised_title,
        abstract=disguised_abstract,
        document_text=code_project_b,
        repository_url=cloned_repo,
        save_to_db=False
    )

    print("\n" + "=" * 70)
    print("FINAL MULTI-MODAL EVALUATION RESULT (DATABASE SCAN):")
    print("=" * 70)
    print(f"• Overall Duplication Score: {report['duplication_score']}% ({report['report']['duplication_verdict']})")
    print(f"• Text Similarity Score:     {report['report'].get('text_similarity_score')}%")
    print(f"• Code/Repo Match Detected:  {report['report'].get('repo_duplicate_detected')}")
    print(f"• Faculty Recommendation:    {report['report'].get('recommendation_for_faculty')}")
    print("\n• Matched Database Projects:")
    for m in report['report'].get('matched_archived_projects', []):
        print(f"  - Project #{m['project_id']}: {m['title']}")
        print(f"    Match Diagnosis: {m.get('similarity_summary')}")
        print(f"    Composite Score: {m.get('similarity_score') * 100:.1f}%")
    print("=" * 70)

if __name__ == "__main__":
    asyncio.run(run_test())
