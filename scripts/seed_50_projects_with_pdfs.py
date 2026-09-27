import os
import sys
import json
import random
import datetime
import psycopg2
from psycopg2.extras import execute_values

# Add ai-service to path for embedding generator
sys.path.insert(0, "d:/projectvault/ai-service")
try:
    from app.services.embedding_service import embedding_service
    from app.services.vector_service import vector_service
except Exception as e:
    print(f"Warning: could not import embedding/vector services: {e}")
    embedding_service = None
    vector_service = None

from reportlab.lib.pagesizes import letter
from reportlab.platypus import SimpleDocTemplate, Paragraph, Spacer, PageBreak, Table, TableStyle
from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
from reportlab.lib import colors
from reportlab.pdfgen import canvas

DB_URL = "postgresql://postgres:0608@localhost:5432/projectvault"
STORAGE_ROOT = "d:/projectvault/storage/projects"

# MCA Students
STUDENTS = [
    {"id": 23, "name": "Bala", "email": "25mx101@university.edu", "roll": "25MX101"},
    {"id": 24, "name": "Gopi", "email": "25mx102@university.edu", "roll": "25MX102"},
    {"id": 25, "name": "Kaleel", "email": "25mx103@university.edu", "roll": "25MX103"},
    {"id": 26, "name": "Vikram", "email": "25mx104@university.edu", "roll": "25MX104"},
    {"id": 27, "name": "Chinnaya", "email": "25mx105@university.edu", "roll": "25MX105"},
    {"id": 28, "name": "Saravanavel", "email": "25mx106@university.edu", "roll": "25MX106"},
    {"id": 30, "name": "Mowlidharan", "email": "25mx213@university.edu.in", "roll": "25MX213"},
    {"id": 29, "name": "Test Student", "email": "test.student@projectvault.edu", "roll": "25MX999"}
]

# MCA Faculty Guides
FACULTIES = [
    {"id": 20, "name": "Ms. Geetha", "email": "geetha@university.edu"},
    {"id": 21, "name": "Dr. Gayathri", "email": "gayathri@university.edu"},
    {"id": 22, "name": "Dr. Manavalan", "email": "manavalan@university.edu"}
]

PROJECT_BLUEPRINTS = [
    # 1. Cloud & Distributed Systems
    {
        "title": "Cloud-Native Microservices Orchestrator with Intelligent Pod Autoscaling",
        "domain": "Cloud Computing & Distributed Systems",
        "tech_stack": ["Kubernetes", "Go", "Prometheus", "Docker", "gRPC", "Envoy"],
        "keywords": ["Kubernetes", "Horizontal Pod Autoscaling", "Cloud-Native", "Microservices", "Telemetry", "Prometheus"],
        "academic_year": "2025-2026", "semester": 6, "type": "Capstone Project",
        "repo": "https://github.com/projectvault/cloud-microservices-autoscaler"
    },
    {
        "title": "Serverless Function Cold-Start Mitigation Using Predictive Warm-Up Queues",
        "domain": "Cloud Computing & Distributed Systems",
        "tech_stack": ["AWS Lambda", "Python", "Redis", "Kafka", "FastAPI"],
        "keywords": ["Serverless", "Cold Start", "FaaS", "Predictive Caching", "Event-Driven", "Redis"],
        "academic_year": "2024-2025", "semester": 5, "type": "Capstone Project",
        "repo": "https://github.com/projectvault/serverless-cold-start-optimizer"
    },
    {
        "title": "High-Throughput Distributed Event Bus with Geo-Replication and Raft Consensus",
        "domain": "Cloud Computing & Distributed Systems",
        "tech_stack": ["Java", "Spring Boot", "Apache Kafka", "Raft", "RocksDB"],
        "keywords": ["Distributed Systems", "Raft Consensus", "Event Bus", "Geo-Replication", "Fault Tolerance"],
        "academic_year": "2024-2025", "semester": 6, "type": "Research Paper",
        "repo": "https://github.com/projectvault/distributed-raft-event-bus"
    },
    {
        "title": "Decentralized Edge API Gateway with Autonomous Traffic Throttling",
        "domain": "Cloud Computing & Distributed Systems",
        "tech_stack": ["Rust", "Actix-Web", "WebAssembly", "NGINX", "PostgreSQL"],
        "keywords": ["API Gateway", "Rate Limiting", "WebAssembly", "Edge Computing", "Reverse Proxy"],
        "academic_year": "2025-2026", "semester": 4, "type": "Mini Project",
        "repo": "https://github.com/projectvault/edge-api-gateway"
    },
    {
        "title": "Zero-Downtime Multi-Cloud Database Synchronization Engine with CDC Pipelines",
        "domain": "Cloud Computing & Distributed Systems",
        "tech_stack": ["Debezium", "PostgreSQL", "Kafka", "Docker", "Python"],
        "keywords": ["Change Data Capture", "Multi-Cloud", "Database Sync", "PostgreSQL", "Data Replication"],
        "academic_year": "2023-2024", "semester": 6, "type": "Capstone Project",
        "repo": "https://github.com/projectvault/zero-downtime-cdc-sync"
    },

    # 2. AI & Deep Learning in Healthcare
    {
        "title": "Deep Learning Diagnostic Classifier for Multi-Class Pulmonary CT Scans",
        "domain": "Healthcare AI & Medical Imaging",
        "tech_stack": ["PyTorch", "TorchVision", "EfficientNet", "FastAPI", "OpenCV"],
        "keywords": ["Medical Imaging", "Pulmonary Scans", "Deep Learning", "Convolutional Neural Networks", "Healthcare"],
        "academic_year": "2025-2026", "semester": 6, "type": "Capstone Project",
        "repo": "https://github.com/projectvault/pulmonary-ct-classifier"
    },
    {
        "title": "Multimodal Cancer Patient Survival Prognosis Using Clinical Graphs and Genomics",
        "domain": "Healthcare AI & Medical Imaging",
        "tech_stack": ["PyTorch Geometric", "BioPython", "Scikit-Learn", "FastAPI", "React"],
        "keywords": ["Graph Neural Networks", "Genomics", "Survival Analysis", "Multimodal AI", "Oncology"],
        "academic_year": "2024-2025", "semester": 6, "type": "Research Paper",
        "repo": "https://github.com/projectvault/genomic-survival-prognosis"
    },
    {
        "title": "Automated Diabetic Retinopathy Grading System with Explainable Heatmaps",
        "domain": "Healthcare AI & Medical Imaging",
        "tech_stack": ["TensorFlow", "Grad-CAM", "Flask", "Python", "NumPy"],
        "keywords": ["Diabetic Retinopathy", "Grad-CAM", "Explainable AI", "Fundus Photography", "Computer Vision"],
        "academic_year": "2025-2026", "semester": 5, "type": "Capstone Project",
        "repo": "https://github.com/projectvault/diabetic-retinopathy-grading"
    },
    {
        "title": "ECG Arrhythmia Detection via Temporal Convolutional Networks and Telemetry",
        "domain": "Healthcare AI & Medical Imaging",
        "tech_stack": ["PyTorch", "TCN", "SciPy", "MQTT", "InfluxDB"],
        "keywords": ["ECG Signal", "Arrhythmia", "Temporal Convolutional Networks", "Wearable Health", "Telemetry"],
        "academic_year": "2024-2025", "semester": 4, "type": "Mini Project",
        "repo": "https://github.com/projectvault/ecg-arrhythmia-tcn"
    },
    {
        "title": "Clinical Dialogue Summarization and ICD-10 Code Extraction Agent",
        "domain": "Healthcare AI & Medical Imaging",
        "tech_stack": ["HuggingFace", "Transformers", "spaCy", "FastAPI", "PostgreSQL"],
        "keywords": ["Clinical NLP", "ICD-10", "Medical Summarization", "Transformers", "EHR Systems"],
        "academic_year": "2025-2026", "semester": 6, "type": "Capstone Project",
        "repo": "https://github.com/projectvault/clinical-ehr-summarizer"
    },

    # 3. Cybersecurity, Zero-Trust & Cryptography
    {
        "title": "Zero-Trust Identity and Access Management Framework with Continuous Risk Scoring",
        "domain": "Cybersecurity & Identity Governance",
        "tech_stack": ["Spring Boot", "OIDC", "OAuth2", "Keycloak", "PostgreSQL", "Redis"],
        "keywords": ["Zero-Trust", "IAM", "Risk-Based Authentication", "OAuth2", "Session Anomaly", "Security"],
        "academic_year": "2025-2026", "semester": 6, "type": "Capstone Project",
        "repo": "https://github.com/projectvault/zero-trust-iam-framework"
    },
    {
        "title": "Post-Quantum Cryptographic Key Exchange Implementation for TLS Protocols",
        "domain": "Cybersecurity & Identity Governance",
        "tech_stack": ["C++", "OpenSSL", "Kyber", "Python", "Wireshark"],
        "keywords": ["Post-Quantum", "Kyber", "Lattice Cryptography", "TLS 1.3", "Key Exchange"],
        "academic_year": "2024-2025", "semester": 6, "type": "Research Paper",
        "repo": "https://github.com/projectvault/pqc-kyber-tls"
    },
    {
        "title": "Heuristic Ransomware Early-Warning Detection via Kernel File-System Entropy",
        "domain": "Cybersecurity & Identity Governance",
        "tech_stack": ["C#", "eBPF", "Python", "SQLite", "Windows API"],
        "keywords": ["Ransomware Detection", "Shannon Entropy", "Kernel Monitoring", "Cyber Defense", "EDR"],
        "academic_year": "2025-2026", "semester": 5, "type": "Capstone Project",
        "repo": "https://github.com/projectvault/ransomware-entropy-guard"
    },
    {
        "title": "Automated Web Application Vulnerability Scanner and Remediation Generator",
        "domain": "Cybersecurity & Identity Governance",
        "tech_stack": ["Python", "Playwright", "OWASP ZAP API", "FastAPI", "Docker"],
        "keywords": ["Vulnerability Scanner", "OWASP Top 10", "DAST", "Automated Remediation", "Security"],
        "academic_year": "2024-2025", "semester": 4, "type": "Mini Project",
        "repo": "https://github.com/projectvault/web-vulnerability-scanner"
    },
    {
        "title": "Blockchain-Enabled Hardware Security Token Attestation and Firmware Verification",
        "domain": "Cybersecurity & Identity Governance",
        "tech_stack": ["Solidity", "Rust", "Ethereum", "Web3.py", "Hardware Root of Trust"],
        "keywords": ["Hardware Attestation", "Smart Contracts", "Firmware Integrity", "Supply Chain", "Blockchain"],
        "academic_year": "2023-2024", "semester": 6, "type": "Capstone Project",
        "repo": "https://github.com/projectvault/hardware-firmware-attestation"
    },

    # 4. Computer Vision & Multimodal AI
    {
        "title": "Autonomous Agricultural Drone Fleet Telemetry and Crop Stress Mapping",
        "domain": "Computer Vision & Robotics",
        "tech_stack": ["YOLOv8", "ROS2", "Python", "OpenCV", "MQTT", "PostGIS"],
        "keywords": ["Precision Agriculture", "Drone Fleet", "YOLOv8", "NDVI Mapping", "Robotics Telemetry"],
        "academic_year": "2025-2026", "semester": 6, "type": "Capstone Project",
        "repo": "https://github.com/projectvault/drone-crop-stress-mapping"
    },
    {
        "title": "Real-Time Campus Crowd Density Estimation and Anomaly Detection via Edge Vision",
        "domain": "Computer Vision & Robotics",
        "tech_stack": ["NVIDIA DeepStream", "TensorRT", "YOLOv9", "Kafka", "React"],
        "keywords": ["Crowd Analysis", "Edge AI", "NVIDIA Jetson", "Anomaly Detection", "Surveillance"],
        "academic_year": "2024-2025", "semester": 6, "type": "Capstone Project",
        "repo": "https://github.com/projectvault/crowd-density-edge-vision"
    },
    {
        "title": "Multimodal Continuous Indian Sign Language Translation to Natural Speech",
        "domain": "Computer Vision & Robotics",
        "tech_stack": ["MediaPipe", "LSTM", "PyTorch", "gTTS", "Flutter"],
        "keywords": ["Sign Language Recognition", "MediaPipe", "Gesture Tracking", "Accessibility", "Multimodal"],
        "academic_year": "2025-2026", "semester": 5, "type": "Research Paper",
        "repo": "https://github.com/projectvault/sign-language-translator"
    },
    {
        "title": "Automated Traffic Violation Identification Using DeepSORT and License Plate OCR",
        "domain": "Computer Vision & Robotics",
        "tech_stack": ["OpenCV", "DeepSORT", "EasyOCR", "Python", "FastAPI"],
        "keywords": ["Traffic Enforcement", "ALPR", "Vehicle Tracking", "Speed Estimation", "Computer Vision"],
        "academic_year": "2024-2025", "semester": 4, "type": "Mini Project",
        "repo": "https://github.com/projectvault/traffic-violation-ocr"
    },
    {
        "title": "Underwater Marine Plastic Waste Detection and Geo-Tagging Rover System",
        "domain": "Computer Vision & Robotics",
        "tech_stack": ["PyTorch", "Faster R-CNN", "Raspberry Pi", "OpenCV", "GPS"],
        "keywords": ["Marine Environmental Monitoring", "Underwater Robotics", "Object Detection", "Ocean Cleanup"],
        "academic_year": "2023-2024", "semester": 6, "type": "Capstone Project",
        "repo": "https://github.com/projectvault/underwater-rover-plastic-detector"
    },

    # 5. Natural Language Processing & Large Language Models
    {
        "title": "Context-Grounded Retrieval Augmented Generation for Enterprise Legal Contracts",
        "domain": "Natural Language Processing & LLMs",
        "tech_stack": ["LangChain", "SentenceTransformers", "ChromaDB", "Python", "FastAPI"],
        "keywords": ["RAG", "Legal Tech", "Dense Vector Retrieval", "Clause Extraction", "Compliance"],
        "academic_year": "2025-2026", "semester": 6, "type": "Capstone Project",
        "repo": "https://github.com/projectvault/legal-contract-rag-assistant"
    },
    {
        "title": "Self-Correcting Multi-Agent Code Generation and Test Synthesis Pipeline",
        "domain": "Natural Language Processing & LLMs",
        "tech_stack": ["CrewAI", "Python", "Ollama", "PyTest", "Docker"],
        "keywords": ["Multi-Agent AI", "Autonomous Code Generation", "Unit Test Synthesis", "DevOps LLM"],
        "academic_year": "2024-2025", "semester": 6, "type": "Research Paper",
        "repo": "https://github.com/projectvault/multi-agent-code-synthesizer"
    },
    {
        "title": "Domain-Specific Academic Plagiarism and Paraphrase Detector Using Dual Encoders",
        "domain": "Natural Language Processing & LLMs",
        "tech_stack": ["BERT", "RoBERTa", "PyTorch", "FastAPI", "React"],
        "keywords": ["Paraphrase Detection", "Academic Integrity", "Semantic Textual Similarity", "Dual Encoders"],
        "academic_year": "2025-2026", "semester": 5, "type": "Capstone Project",
        "repo": "https://github.com/projectvault/academic-paraphrase-detector"
    },
    {
        "title": "Low-Resource Indic Dialect Machine Translation with Byte-Pair Encoding",
        "domain": "Natural Language Processing & LLMs",
        "tech_stack": ["Fairseq", "HuggingFace", "Python", "Streamlit", "PyTorch"],
        "keywords": ["Machine Translation", "Indic NLP", "Low-Resource Languages", "Seq2Seq", "Transformers"],
        "academic_year": "2024-2025", "semester": 4, "type": "Mini Project",
        "repo": "https://github.com/projectvault/indic-dialect-translation"
    },
    {
        "title": "Federated Multi-Tenant Customer Sentiment Analyzer with Differential Privacy",
        "domain": "Natural Language Processing & LLMs",
        "tech_stack": ["PySyft", "PyTorch", "BERT", "Flask", "Docker"],
        "keywords": ["Federated Learning", "Differential Privacy", "Sentiment Analysis", "Privacy-Preserving AI"],
        "academic_year": "2023-2024", "semester": 6, "type": "Capstone Project",
        "repo": "https://github.com/projectvault/federated-sentiment-privacy"
    },

    # 6. FinTech, Blockchain & Web3
    {
        "title": "Decentralized Micro-Lending Platform with Machine Learning Credit Scoring",
        "domain": "FinTech & Decentralized Systems",
        "tech_stack": ["Solidity", "Ethereum", "XGBoost", "Node.js", "Web3.js", "MongoDB"],
        "keywords": ["DeFi", "Smart Contracts", "Credit Scoring", "Micro-Finance", "Decentralized Apps"],
        "academic_year": "2025-2026", "semester": 6, "type": "Capstone Project",
        "repo": "https://github.com/projectvault/defi-credit-scoring-protocol"
    },
    {
        "title": "Real-Time Flash Loan Attack Detection Engine on Ethereum Virtual Machine",
        "domain": "FinTech & Decentralized Systems",
        "tech_stack": ["Hardhat", "Python", "Ethers.js", "Graph Protocol", "PostgreSQL"],
        "keywords": ["Flash Loan Attacks", "EVM Forensics", "DeFi Security", "Transaction Tracing", "Blockchain"],
        "academic_year": "2024-2025", "semester": 6, "type": "Research Paper",
        "repo": "https://github.com/projectvault/flash-loan-attack-monitor"
    },
    {
        "title": "Cross-Border Remittance Settlement Network Using Algorithmic Stablecoins",
        "domain": "FinTech & Decentralized Systems",
        "tech_stack": ["Polygon", "Solidity", "React", "TypeScript", "Chainlink Oracles"],
        "keywords": ["Stablecoins", "Cross-Border Payments", "Chainlink", "Polygon L2", "Settlement Network"],
        "academic_year": "2025-2026", "semester": 5, "type": "Capstone Project",
        "repo": "https://github.com/projectvault/cross-border-stablecoin-network"
    },
    {
        "title": "Cryptocurrency Fraud Investigation Tool with Temporal Graph Embeddings",
        "domain": "FinTech & Decentralized Systems",
        "tech_stack": ["NetworkX", "PyTorch Geometric", "FastAPI", "Neo4j", "React"],
        "keywords": ["Blockchain Analytics", "Anti-Money Laundering", "Graph Neural Networks", "Crypto Forensics"],
        "academic_year": "2024-2025", "semester": 4, "type": "Mini Project",
        "repo": "https://github.com/projectvault/crypto-aml-graph-tracker"
    },
    {
        "title": "Decentralized Carbon Credit Tokenization and Double-Spending Verification",
        "domain": "FinTech & Decentralized Systems",
        "tech_stack": ["Solidity", "IPFS", "Next.js", "Ethereum", "IoT Sensors"],
        "keywords": ["Carbon Credits", "Green Tech", "Tokenization", "NFTs", "Sustainability"],
        "academic_year": "2023-2024", "semester": 6, "type": "Capstone Project",
        "repo": "https://github.com/projectvault/carbon-credit-token-exchange"
    },

    # 7. Internet of Things & Smart Campus
    {
        "title": "Campus-Wide Smart Energy Grid Telemetry and Peak Load Forecasting System",
        "domain": "IoT & Smart Infrastructure",
        "tech_stack": ["ESP32", "MQTT", "InfluxDB", "Grafana", "Prophet", "Python"],
        "keywords": ["Smart Grid", "Energy Management", "Time-Series Forecasting", "MQTT", "IoT Infrastructure"],
        "academic_year": "2025-2026", "semester": 6, "type": "Capstone Project",
        "repo": "https://github.com/projectvault/smart-campus-energy-grid"
    },
    {
        "title": "LoRaWAN-Based Environmental Quality and Air Pollution Real-Time Monitoring",
        "domain": "IoT & Smart Infrastructure",
        "tech_stack": ["LoRaWAN", "The Things Network", "Node-RED", "PostgreSQL", "React"],
        "keywords": ["Air Quality Index", "LoRaWAN", "Environmental Sensors", "Long-Range IoT", "Smart Cities"],
        "academic_year": "2024-2025", "semester": 6, "type": "Capstone Project",
        "repo": "https://github.com/projectvault/lorawan-air-quality-monitor"
    },
    {
        "title": "Smart Water Distribution Network with Acoustic Acoustic Leak Detection",
        "domain": "IoT & Smart Infrastructure",
        "tech_stack": ["Arduino", "Raspberry Pi", "Signal Processing", "MQTT", "FastAPI"],
        "keywords": ["Water Conservation", "Acoustic Sensors", "Leak Detection", "Smart Water Network"],
        "academic_year": "2025-2026", "semester": 5, "type": "Mini Project",
        "repo": "https://github.com/projectvault/smart-water-leak-detection"
    },
    {
        "title": "Intelligent Multi-Story Parking Allocation with Edge License Tagging",
        "domain": "IoT & Smart Infrastructure",
        "tech_stack": ["Ultrasonic Sensors", "OpenCV", "Node.js", "WebSocket", "Tailwind CSS"],
        "keywords": ["Smart Parking", "Edge IoT", "Real-Time Reservation", "Occupancy Sensors"],
        "academic_year": "2024-2025", "semester": 4, "type": "Mini Project",
        "repo": "https://github.com/projectvault/smart-parking-management"
    },
    {
        "title": "Asset Tracking and RFID Laboratory Inventory Automation with Bluetooth Beacons",
        "domain": "IoT & Smart Infrastructure",
        "tech_stack": ["BLE Beacons", "RFID", "Spring Boot", "React", "MySQL"],
        "keywords": ["Asset Tracking", "RFID", "BLE Indoor Positioning", "Inventory Management"],
        "academic_year": "2023-2024", "semester": 6, "type": "Capstone Project",
        "repo": "https://github.com/projectvault/rfid-lab-inventory-tracker"
    },

    # 8. DevOps, SRE & Software Engineering
    {
        "title": "GitOps CI/CD Automation Pipeline with Security Policy Verification and Rollbacks",
        "domain": "DevOps & Software Reliability",
        "tech_stack": ["ArgoCD", "Kubernetes", "Helm", "GitHub Actions", "OPA Gatekeeper"],
        "keywords": ["GitOps", "ArgoCD", "Kubernetes", "Policy-as-Code", "Automated Canary Deployments"],
        "academic_year": "2025-2026", "semester": 6, "type": "Capstone Project",
        "repo": "https://github.com/projectvault/gitops-automated-canary-pipeline"
    },
    {
        "title": "Distributed Tracing and Observability Visualizer for Heterogeneous Microservices",
        "domain": "DevOps & Software Reliability",
        "tech_stack": ["OpenTelemetry", "Jaeger", "ClickHouse", "Go", "React"],
        "keywords": ["Distributed Tracing", "OpenTelemetry", "Observability", "APM", "Microservices SLA"],
        "academic_year": "2024-2025", "semester": 6, "type": "Research Paper",
        "repo": "https://github.com/projectvault/opentelemetry-trace-analyzer"
    },
    {
        "title": "Chaos Engineering Orchestration Framework for Resilient Cloud Infrastructures",
        "domain": "DevOps & Software Reliability",
        "tech_stack": ["Chaos Mesh", "Kubernetes", "Python", "Grafana", "Docker"],
        "keywords": ["Chaos Engineering", "Fault Injection", "System Resilience", "Disaster Recovery"],
        "academic_year": "2025-2026", "semester": 5, "type": "Capstone Project",
        "repo": "https://github.com/projectvault/cloud-chaos-engineering-runner"
    },
    {
        "title": "Static Code Vulnerability Analysis Bot with Automated Pull Request Commenting",
        "domain": "DevOps & Software Reliability",
        "tech_stack": ["Semgrep", "GitHub Apps API", "Node.js", "Docker", "PostgreSQL"],
        "keywords": ["SAST", "Code Security", "GitHub Bot", "Shift-Left Security", "Developer Tooling"],
        "academic_year": "2024-2025", "semester": 4, "type": "Mini Project",
        "repo": "https://github.com/projectvault/sast-code-review-bot"
    },
    {
        "title": "Automated Database Migration and Canary Schema Rollout Orchestrator",
        "domain": "DevOps & Software Reliability",
        "tech_stack": ["Flyway", "Liquibase", "Java", "PostgreSQL", "Spring Boot"],
        "keywords": ["Database Migration", "Zero-Downtime Schema Changes", "Canary Releases", "CI/CD"],
        "academic_year": "2023-2024", "semester": 6, "type": "Capstone Project",
        "repo": "https://github.com/projectvault/database-schema-canary-rollout"
    },

    # 9. Big Data & Real-Time Stream Analytics
    {
        "title": "Real-Time Financial Transaction Anomaly Detection Using Apache Flink and Kafka",
        "domain": "Big Data & Stream Processing",
        "tech_stack": ["Apache Flink", "Apache Kafka", "Java", "Elasticsearch", "Kibana"],
        "keywords": ["Stream Analytics", "Apache Flink", "CEP", "Financial Fraud", "Complex Event Processing"],
        "academic_year": "2025-2026", "semester": 6, "type": "Capstone Project",
        "repo": "https://github.com/projectvault/flink-fraud-stream-detection"
    },
    {
        "title": "Distributed Web Crawler and Real-Time Sentiment Index for Stock Market Trends",
        "domain": "Big Data & Stream Processing",
        "tech_stack": ["Scrapy", "Apache Spark", "Kafka", "FinBERT", "Cassandra"],
        "keywords": ["Web Scraping", "Apache Spark", "Sentiment Analysis", "Financial Markets", "Big Data"],
        "academic_year": "2024-2025", "semester": 6, "type": "Research Paper",
        "repo": "https://github.com/projectvault/stock-sentiment-spark-streamer"
    },
    {
        "title": "Predictive Industrial Equipment Failure System Using Spark Streaming and Sensors",
        "domain": "Big Data & Stream Processing",
        "tech_stack": ["Apache Spark", "Python", "Scikit-Learn", "HDFS", "Grafana"],
        "keywords": ["Predictive Maintenance", "Industrial IoT", "Spark Streaming", "Machine Learning"],
        "academic_year": "2025-2026", "semester": 5, "type": "Capstone Project",
        "repo": "https://github.com/projectvault/predictive-maintenance-streaming"
    },
    {
        "title": "Serverless Log Analytics and Automated Alerting Pipeline on Elastic Cloud",
        "domain": "Big Data & Stream Processing",
        "tech_stack": ["Elasticsearch", "Logstash", "Kibana", "AWS SQS", "Python"],
        "keywords": ["Log Analytics", "ELK Stack", "Alerting Engine", "SIEM", "Cloud Monitoring"],
        "academic_year": "2024-2025", "semester": 4, "type": "Mini Project",
        "repo": "https://github.com/projectvault/elk-log-analytics-pipeline"
    },
    {
        "title": "Geo-Distributed Clickstream Analytics Engine for High-Concurrency E-Commerce",
        "domain": "Big Data & Stream Processing",
        "tech_stack": ["ClickHouse", "Kafka", "Go", "Redis", "Next.js"],
        "keywords": ["Clickstream", "ClickHouse", "Real-Time OLAP", "E-Commerce", "High Concurrency"],
        "academic_year": "2023-2024", "semester": 6, "type": "Capstone Project",
        "repo": "https://github.com/projectvault/clickstream-realtime-olap"
    },

    # 10. Bioinformatics, Genomics & Computational Biology
    {
        "title": "High-Performance GPU-Accelerated DNA Sequence Alignment with Smith-Waterman",
        "domain": "Bioinformatics & Computational Biology",
        "tech_stack": ["CUDA", "C++", "Python", "BioPython", "OpenMP"],
        "keywords": ["DNA Alignment", "Smith-Waterman", "GPU Acceleration", "Bioinformatics", "Genomics"],
        "academic_year": "2025-2026", "semester": 6, "type": "Capstone Project",
        "repo": "https://github.com/projectvault/gpu-dna-sequence-alignment"
    },
    {
        "title": "Deep Learning Protein Structure Secondary Prediction from Amino Acid Sequences",
        "domain": "Bioinformatics & Computational Biology",
        "tech_stack": ["PyTorch", "ESM-2", "BioPython", "Flask", "Tailwind CSS"],
        "keywords": ["Protein Folding", "Transformer Models", "Secondary Structure", "Computational Biology"],
        "academic_year": "2024-2025", "semester": 6, "type": "Research Paper",
        "repo": "https://github.com/projectvault/protein-secondary-structure-ai"
    },
    {
        "title": "Phylogenetic Tree Construction and Mutation Tracking for Viral Pathogens",
        "domain": "Bioinformatics & Computational Biology",
        "tech_stack": ["Python", "BioPython", "D3.js", "FastAPI", "SQLite"],
        "keywords": ["Phylogenetics", "Viral Mutations", "Epidemiology", "Sequence Analysis", "Data Visualization"],
        "academic_year": "2025-2026", "semester": 5, "type": "Capstone Project",
        "repo": "https://github.com/projectvault/pathogen-phylogenetic-tracker"
    },
    {
        "title": "Drug-Target Interaction Prediction Engine Using Graph Neural Networks",
        "domain": "Bioinformatics & Computational Biology",
        "tech_stack": ["RDKit", "PyTorch Geometric", "Python", "FastAPI", "PostgreSQL"],
        "keywords": ["Drug Discovery", "Molecular Graphs", "Graph Neural Networks", "Pharmacology"],
        "academic_year": "2024-2025", "semester": 4, "type": "Mini Project",
        "repo": "https://github.com/projectvault/drug-target-interaction-gnn"
    },
    {
        "title": "Metagenomic Taxonomic Profiler for Environmental Soil Microbiome Samples",
        "domain": "Bioinformatics & Computational Biology",
        "tech_stack": ["Kraken2", "Python", "R", "Shiny", "Docker"],
        "keywords": ["Metagenomics", "Taxonomic Profiling", "Soil Microbiome", "Next-Gen Sequencing"],
        "academic_year": "2023-2024", "semester": 6, "type": "Capstone Project",
        "repo": "https://github.com/projectvault/metagenomic-soil-profiler"
    }
]

class NumberedCanvas(canvas.Canvas):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)
        self._saved_page_states = []

    def showPage(self):
        self._saved_page_states.append(dict(self.__dict__))
        self._startPage()

    def save(self):
        num_pages = len(self._saved_page_states)
        for state in self._saved_page_states:
            self.__dict__.update(state)
            self.draw_page_decorations(num_pages)
            super().showPage()
        super().save()

    def draw_page_decorations(self, page_count):
        self.saveState()
        self.setStrokeColor(colors.HexColor("#CBD5E1"))
        self.setLineWidth(0.5)
        # Header line (pages 2-5)
        if self._pageNumber > 1:
            self.line(40, 755, 572, 755)
            self.setFont("Helvetica", 8)
            self.setFillColor(colors.HexColor("#64748B"))
            self.drawString(40, 760, "PROJECTVAULT — MASTER OF COMPUTER APPLICATIONS ACADEMIC REPOSITORY")
            self.drawRightString(572, 760, "OFFICIAL CAPSTONE DOCUMENT")
        
        # Footer
        self.line(40, 45, 572, 45)
        self.setFont("Helvetica", 8)
        self.setFillColor(colors.HexColor("#64748B"))
        self.drawString(40, 32, "Confidential Academic Record • ProjectVault Digital Archive")
        self.drawRightString(572, 32, f"Page {self._pageNumber} of {page_count}")
        self.restoreState()

def generate_5page_pdf(filepath, project_data, author, guide, co_members):
    os.makedirs(os.path.dirname(filepath), exist_ok=True)
    doc = SimpleDocTemplate(
        filepath,
        pagesize=letter,
        leftMargin=40,
        rightMargin=40,
        topMargin=50,
        bottomMargin=55
    )

    styles = getSampleStyleSheet()
    
    title_style = ParagraphStyle(
        'DocTitle',
        parent=styles['Heading1'],
        fontName='Helvetica-Bold',
        fontSize=18,
        leading=22,
        textColor=colors.HexColor('#0F172A'),
        alignment=1, # Center
        spaceAfter=15
    )
    
    subtitle_style = ParagraphStyle(
        'DocSub',
        fontName='Helvetica-Bold',
        fontSize=11,
        leading=15,
        textColor=colors.HexColor('#4338CA'),
        alignment=1,
        spaceAfter=15
    )

    h1_style = ParagraphStyle(
        'ChapterH1',
        parent=styles['Heading2'],
        fontName='Helvetica-Bold',
        fontSize=14,
        leading=18,
        textColor=colors.HexColor('#1E293B'),
        spaceBefore=10,
        spaceAfter=10,
        borderPadding=(0, 0, 4, 0),
        borderColor=colors.HexColor('#4F46E5'),
        borderWidth=1
    )

    h2_style = ParagraphStyle(
        'SubH2',
        parent=styles['Heading3'],
        fontName='Helvetica-Bold',
        fontSize=11,
        leading=15,
        textColor=colors.HexColor('#334155'),
        spaceBefore=8,
        spaceAfter=4
    )

    body_style = ParagraphStyle(
        'BodyDark',
        parent=styles['Normal'],
        fontName='Helvetica',
        fontSize=9.5,
        leading=14,
        textColor=colors.HexColor('#334155'),
        spaceAfter=8
    )

    callout_style = ParagraphStyle(
        'Callout',
        parent=styles['Normal'],
        fontName='Helvetica-Oblique',
        fontSize=9,
        leading=13,
        textColor=colors.HexColor('#1E1B4B'),
        backColor=colors.HexColor('#EEF2FF'),
        borderColor=colors.HexColor('#C7D2FE'),
        borderWidth=1,
        borderPadding=8,
        spaceAfter=10,
        borderRadius=4
    )

    story = []

    # ==================== PAGE 1: TITLE & COVER ====================
    story.append(Spacer(1, 15))
    story.append(Paragraph("DEPARTMENT OF COMPUTER APPLICATIONS (MCA)", subtitle_style))
    story.append(Paragraph(project_data['title'], title_style))
    story.append(Spacer(1, 10))

    meta_table_data = [
        [Paragraph("<b>Academic Year:</b>", body_style), Paragraph(project_data['academic_year'], body_style),
         Paragraph("<b>Semester:</b>", body_style), Paragraph(f"Semester {project_data['semester']}", body_style)],
        [Paragraph("<b>Project Type:</b>", body_style), Paragraph(project_data['type'], body_style),
         Paragraph("<b>Department:</b>", body_style), Paragraph("Computer Applications (MCA)", body_style)],
        [Paragraph("<b>Primary Author:</b>", body_style), Paragraph(f"{author['name']} ({author['roll']})", body_style),
         Paragraph("<b>Designated Guide:</b>", body_style), Paragraph(f"{guide['name']} (Faculty Guide)", body_style)],
        [Paragraph("<b>Repository:</b>", body_style), Paragraph(project_data['repo'], body_style),
         Paragraph("<b>Domain:</b>", body_style), Paragraph(project_data['domain'], body_style)]
    ]
    t = Table(meta_table_data, colWidths=[90, 170, 100, 172])
    t.setStyle(TableStyle([
        ('BACKGROUND', (0,0), (-1,-1), colors.HexColor('#F8FAFC')),
        ('BOX', (0,0), (-1,-1), 1, colors.HexColor('#E2E8F0')),
        ('INNERGRID', (0,0), (-1,-1), 0.5, colors.HexColor('#E2E8F0')),
        ('VALIGN', (0,0), (-1,-1), 'MIDDLE'),
        ('TOPPADDING', (0,0), (-1,-1), 5),
        ('BOTTOMPADDING', (0,0), (-1,-1), 5),
    ]))
    story.append(t)
    story.append(Spacer(1, 20))

    story.append(Paragraph("EXECUTIVE ABSTRACT", h2_style))
    story.append(Paragraph(project_data['abstract'], body_style))
    story.append(Spacer(1, 10))

    keywords_str = ", ".join(project_data['keywords'])
    tech_str = ", ".join(project_data['tech_stack'])
    story.append(Paragraph(f"<b>Index Terms / Keywords:</b> {keywords_str}", body_style))
    story.append(Paragraph(f"<b>Technology Stack:</b> {tech_str}", body_style))
    
    co_str = ", ".join([f"{m['name']} ({m['roll']})" for m in co_members]) if co_members else "Individual Capstone Project"
    story.append(Paragraph(f"<b>Collaborating Team Members:</b> {co_str}", body_style))
    story.append(PageBreak())

    # ==================== PAGE 2: CHAPTER 1 ====================
    story.append(Paragraph("CHAPTER 1: INTRODUCTION & PROBLEM DEFINITION", h1_style))
    story.append(Paragraph("1.1 Background and Context", h2_style))
    story.append(Paragraph(
        f"In modern enterprise computing within the discipline of {project_data['domain']}, scalable architectures and robust algorithms "
        f"have become critical determinants of reliability. The initiative '{project_data['title']}' addresses foundational operational "
        f"bottlenecks by harmonizing modern paradigms with resilient data structures. As organizations transition towards automated pipelines, "
        f"the need for verifiable computing platforms is paramount.", body_style
    ))
    story.append(Paragraph("1.2 Problem Statement", h2_style))
    story.append(Paragraph(project_data['problem_statement'], callout_style))
    
    story.append(Paragraph("1.3 Project Motivation", h2_style))
    story.append(Paragraph(
        "Contemporary industry deployments encounter persistent challenges relating to throughput saturation, security surface vulnerabilities, "
        "and prohibitive latencies during distributed execution. Conventional heuristic solutions frequently fail to maintain performance guarantees "
        "under dynamic workloads, precipitating service degradation and cascading failures across microservice boundaries.", body_style
    ))

    story.append(Paragraph("1.4 Core Objectives", h2_style))
    story.append(Paragraph("• Design and implement a fault-tolerant software system utilizing modern frameworks.", body_style))
    story.append(Paragraph(f"• Integrate {tech_str} to establish low-latency query handling and state consistency.", body_style))
    story.append(Paragraph("• Develop automated continuous integration validation suites with automated regression analysis.", body_style))
    story.append(Paragraph("• Demonstrate empirically a minimum 35% efficiency advancement over baseline benchmarks.", body_style))
    
    story.append(Paragraph("1.5 Scope and Operational Boundaries", h2_style))
    story.append(Paragraph(
        f"The scope of this investigation spans algorithmic formulation, distributed prototype synthesis, and integration with academic "
        f"repository registries. Boundary conditions encompass network latency variances, transaction serialization isolation levels, "
        f"and hardware profiling under constrained memory profiles.", body_style
    ))
    story.append(PageBreak())

    # ==================== PAGE 3: CHAPTER 2 ====================
    story.append(Paragraph("CHAPTER 2: LITERATURE SURVEY & RESEARCH Gaps", h1_style))
    story.append(Paragraph("2.1 Review of Related Methodologies", h2_style))
    story.append(Paragraph(
        f"Academic literature in {project_data['domain']} has historically emphasized monolithic structures and reactive scaling heuristics. "
        f"Seminal studies by Smith et al. (2022) established baseline throughput limits, yet failed to account for heterogeneous network partitioning. "
        f"Subsequent investigations by Kumar & Lee (2024) demonstrated the viability of containerized workloads, but introduced substantial CPU "
        f"overhead during high-cardinality state synchronization.", body_style
    ))
    
    lit_table = [
        [Paragraph("<b>Study / Authors</b>", body_style), Paragraph("<b>Methodology</b>", body_style), Paragraph("<b>Observed Limitations</b>", body_style)],
        [Paragraph("Venkatesh et al. (2023)", body_style), Paragraph("Static Threshold Heuristics", body_style), Paragraph("High false-positive trigger rates under bursty load.", body_style)],
        [Paragraph("Harrison & Gupta (2024)", body_style), Paragraph("Centralized Coordinator Node", body_style), Paragraph("Single point of failure and bottleneck under scaling.", body_style)],
        [Paragraph("Chen & Tanaka (2025)", body_style), Paragraph("Pure Rule-Based Engine", body_style), Paragraph("Inability to adapt to novel edge anomalies.", body_style)]
    ]
    lt = Table(lit_table, colWidths=[130, 160, 242])
    lt.setStyle(TableStyle([
        ('BACKGROUND', (0,0), (-1,0), colors.HexColor('#E2E8F0')),
        ('BOX', (0,0), (-1,-1), 1, colors.HexColor('#CBD5E1')),
        ('INNERGRID', (0,0), (-1,-1), 0.5, colors.HexColor('#E2E8F0')),
        ('VALIGN', (0,0), (-1,-1), 'MIDDLE'),
        ('TOPPADDING', (0,0), (-1,-1), 4),
        ('BOTTOMPADDING', (0,0), (-1,-1), 4),
    ]))
    story.append(lt)
    story.append(Spacer(1, 10))

    story.append(Paragraph("2.2 Identified Research Gaps", h2_style))
    story.append(Paragraph(
        "A rigorous synthesis of published literature reveals three fundamental deficiencies: (1) Absence of localized telemetry ingestion "
        "capable of sub-millisecond evaluation; (2) Inadequate cryptographic verification of payload payloads in flight; and (3) Inelastic "
        "coupling between persistence layers and application dispatch engines.", body_style
    ))

    story.append(Paragraph("2.3 Proposed Scientific Novelty", h2_style))
    story.append(Paragraph(
        f"This capstone project overcomes documented shortcomings by synthesizing an asynchronous event topology coupled with "
        f"predictive resource governors. By leveraging {project_data['tech_stack'][0]} alongside {project_data['tech_stack'][1]}, "
        f"the architecture achieves provable determinism and optimal resource utilization.", body_style
    ))
    story.append(PageBreak())

    # ==================== PAGE 4: CHAPTER 3 ====================
    story.append(Paragraph("CHAPTER 3: SYSTEM ARCHITECTURE & METHODOLOGY", h1_style))
    story.append(Paragraph("3.1 Architectural Decomposition", h2_style))
    story.append(Paragraph(
        f"The architectural topology is structured into three discrete decoupling tiers: (i) Ingestion & Gateway Layer; "
        f"(ii) Neural / Algorithmic Core Engine; and (iii) Immutable Persistence & Audit Layer. All inter-component transactions "
        f"are routed via authenticated transport channels adhering to zero-trust security postures.", body_style
    ))

    story.append(Paragraph("3.2 Technical Stack Specifications", h2_style))
    tech_table = [
        [Paragraph("<b>Component Layer</b>", body_style), Paragraph("<b>Assigned Technology</b>", body_style), Paragraph("<b>Functional Responsibility</b>", body_style)],
        [Paragraph("Backend Core", body_style), Paragraph(project_data['tech_stack'][0], body_style), Paragraph("Business logic orchestration and lifecycle state validation.", body_style)],
        [Paragraph("Data Engine", body_style), Paragraph(project_data['tech_stack'][1], body_style), Paragraph("Low-latency stream manipulation and indexed persistence.", body_style)],
        [Paragraph("Security & Auth", body_style), Paragraph("OAuth2 / JWT + SHA-256", body_style), Paragraph("Cryptographic signature validation and role enforcement.", body_style)],
        [Paragraph("Telemetry / AI", body_style), Paragraph(project_data['tech_stack'][2] if len(project_data['tech_stack']) > 2 else "SentenceTransformers", body_style), Paragraph("Continuous telemetry capture and similarity verification.", body_style)]
    ]
    tt = Table(tech_table, colWidths=[120, 160, 252])
    tt.setStyle(TableStyle([
        ('BACKGROUND', (0,0), (-1,0), colors.HexColor('#EEF2FF')),
        ('BOX', (0,0), (-1,-1), 1, colors.HexColor('#C7D2FE')),
        ('INNERGRID', (0,0), (-1,-1), 0.5, colors.HexColor('#E0E7FF')),
        ('VALIGN', (0,0), (-1,-1), 'MIDDLE'),
        ('TOPPADDING', (0,0), (-1,-1), 4),
        ('BOTTOMPADDING', (0,0), (-1,-1), 4),
    ]))
    story.append(tt)
    story.append(Spacer(1, 10))

    story.append(Paragraph("3.3 Data Pipeline & Ingestion Flow", h2_style))
    story.append(Paragraph(
        "Payloads received via secure REST/gRPC endpoints undergo structural schema validation and normalization before ingestion. "
        "Upon successful verification, transactions are written to temporary memory queues while asynchronous persistence workers "
        "commit state changes into PostgreSQL with WAL logging. Embeddings are generated in parallel to prevent worker starvation.", body_style
    ))

    story.append(Paragraph("3.4 Database Schema & Indexing Strategy", h2_style))
    story.append(Paragraph(
        "To ensure sub-50ms query response times under high concurrency, indexes are created using HNSW (Hierarchical Navigable Small World) "
        "cosine distance operators on vector tables, alongside B-Tree composite indices across project lifecycle state keys.", body_style
    ))
    story.append(PageBreak())

    # ==================== PAGE 5: CHAPTER 4 ====================
    story.append(Paragraph("CHAPTER 4: EXPERIMENTAL RESULTS & CONCLUSION", h1_style))
    story.append(Paragraph("4.1 Experimental Setup & Evaluation Metrics", h2_style))
    story.append(Paragraph(
        "System evaluation was executed across 50 simulated client nodes generating sustained concurrent request volumes. "
        "Performance benchmarks were evaluated across four core criteria: End-to-End Latency (ms), Query Throughput (QPS), "
        "Memory Footprint (MB), and Algorithmic Classification Accuracy (%).", body_style
    ))

    results_table = [
        [Paragraph("<b>Evaluation Metric</b>", body_style), Paragraph("<b>Baseline Implementation</b>", body_style), Paragraph("<b>Proposed Solution</b>", body_style), Paragraph("<b>Improvement</b>", body_style)],
        [Paragraph("Average Response Latency", body_style), Paragraph("142.6 ms", body_style), Paragraph("28.4 ms", body_style), Paragraph("+80.1% Faster", body_style)],
        [Paragraph("Peak Query Throughput", body_style), Paragraph("850 req/sec", body_style), Paragraph("3,420 req/sec", body_style), Paragraph("+302.3% Higher", body_style)],
        [Paragraph("Resource Utilization", body_style), Paragraph("78.4% CPU Peak", body_style), Paragraph("34.1% CPU Peak", body_style), Paragraph("+44.3% Efficient", body_style)],
        [Paragraph("F1-Accuracy Score", body_style), Paragraph("84.2%", body_style), Paragraph("96.8%", body_style), Paragraph("+12.6% Accuracy", body_style)]
    ]
    rt = Table(results_table, colWidths=[150, 120, 130, 132])
    rt.setStyle(TableStyle([
        ('BACKGROUND', (0,0), (-1,0), colors.HexColor('#ECFDF5')),
        ('BOX', (0,0), (-1,-1), 1, colors.HexColor('#A7F3D0')),
        ('INNERGRID', (0,0), (-1,-1), 0.5, colors.HexColor('#D1FAE5')),
        ('VALIGN', (0,0), (-1,-1), 'MIDDLE'),
        ('TOPPADDING', (0,0), (-1,-1), 4),
        ('BOTTOMPADDING', (0,0), (-1,-1), 4),
    ]))
    story.append(rt)
    story.append(Spacer(1, 10))

    story.append(Paragraph("4.2 Academic & Societal Impact in MCA", h2_style))
    story.append(Paragraph(
        f"The deployment of this framework advances research across {project_data['domain']} by establishing an open, reproducible, "
        f"and production-hardened codebase. Students, researchers, and enterprise developers can leverage this architecture to reduce time-to-market "
        f"for critical academic computing utilities.", body_style
    ))

    story.append(Paragraph("4.3 Conclusion & Future Enhancements", h2_style))
    story.append(Paragraph(
        f"This academic project has successfully realized all objectives set forth in the MCA curriculum specifications. Future iterations "
        f"will investigate distributed zero-knowledge proofs for cross-organization auditing and dynamic hardware offloading via WebGPU.", body_style
    ))

    story.append(Paragraph("4.4 Selected References & Citations", h2_style))
    story.append(Paragraph("1. Vaswani et al., 'Attention Is All You Need', NeurIPS Conference Proceedings, 2017.", body_style))
    story.append(Paragraph("2. Zaharia et al., 'Apache Spark: A Unified Engine for Big Data Processing', Communications of the ACM, 2016.", body_style))
    story.append(Paragraph("3. He et al., 'Deep Residual Learning for Image Recognition', IEEE CVPR, 2016.", body_style))

    doc.build(story, canvasmaker=NumberedCanvas)
    return os.path.getsize(filepath)

def seed():
    print("==================================================")
    print("SEEDING 50 COMPREHENSIVE MCA PROJECTS WITH 5-PAGE PDFS")
    print("==================================================")

    conn = psycopg2.connect(DB_URL)
    cur = conn.cursor()

    # Clear existing projects
    print("\n[Step 1] Truncating old project tables...")
    cur.execute("""
        TRUNCATE TABLE project_files, project_members, project_workflow_history, 
                       ai_analyses, project_embeddings, projects RESTART IDENTITY CASCADE;
    """)
    conn.commit()
    print(">>> Tables truncated cleanly.")

    # Status distribution: 40 APPROVED, 5 SUBMITTED, 5 DRAFT
    statuses = ["APPROVED"] * 40 + ["SUBMITTED"] * 5 + ["DRAFT"] * 5
    random.seed(42) # Consistent reproduction

    created_projects = []

    print("\n[Step 2] Inserting 50 MCA Projects with all fields...")

    for idx, bp in enumerate(PROJECT_BLUEPRINTS):
        proj_status = statuses[idx]
        author = STUDENTS[idx % len(STUDENTS)]
        guide = FACULTIES[idx % len(FACULTIES)]
        
        # Co-members (1 to 2 other students)
        available_students = [s for s in STUDENTS if s['id'] != author['id']]
        num_co = random.choice([0, 1, 2])
        co_members = random.sample(available_students, num_co)

        # Build comprehensive 300+ word abstract
        abstract = (
            f"This academic project presents '{bp['title']}', developed within the Master of Computer Applications (MCA) "
            f"program for the academic period {bp['academic_year']} (Semester {bp['semester']}). The research operates within "
            f"the critical domain of {bp['domain']}, addressing foundational scalability, fault-tolerance, and automated governance challenges. "
            f"Modern digital ecosystems increasingly demand resilient, self-healing platforms capable of handling high-velocity data streams "
            f"under strict security postures. To overcome documented limitations in legacy implementations, this work introduces an end-to-end "
            f"system architecture constructed upon {', '.join(bp['tech_stack'][:3])}. The methodology incorporates automated ingestion "
            f"pipelines, strict lifecycle state machines, and fine-grained cryptographic validation. Empirical evaluation against baseline "
            f"industrial benchmarks demonstrates significant operational gains, achieving an average latency reduction of 80.1% and a threefold "
            f"increase in sustained throughput. The system adheres to institutional open-science standards, providing verifiable source code "
            f"and standardized deployment manifests for ongoing academic exploration."
        )
        bp['abstract'] = abstract
        bp['problem_statement'] = (
            f"Investigating and resolving throughput bottlenecks, state desynchronization, and security vulnerabilities "
            f"in {bp['domain']} through the development of {bp['title']}."
        )

        plag_score = round(random.uniform(3.2, 11.5), 1)
        dup_score = round(random.uniform(2.1, 13.8), 1)
        plag_report = json.dumps({
            "plagiarism_score": plag_score,
            "duplication_score": dup_score,
            "plagiarism_verdict": "CLEAN",
            "summary_explanation": f"Automated audit verified original student implementation with valid references to {bp['tech_stack'][0]}.",
            "valid_citations_detected": [
                {"citation_text": f"Source reference: {bp['repo']}", "source_type": "GIT_REPOSITORY", "status": "EXCLUDED_FROM_PLAGIARISM"},
                {"citation_text": "IEEE & ACM Academic Bibliography References Cited in Chapter 4", "source_type": "RESEARCH_LITERATURE", "status": "EXCLUDED_FROM_PLAGIARISM"}
            ],
            "uncited_matches": [],
            "matched_archived_projects": [],
            "recommendation_for_faculty": "Verified original capstone work. Recommended for official academic approval."
        })

        created_at = datetime.datetime(2025, 8, 1, 10, 0) + datetime.timedelta(days=idx, hours=idx*2)

        insert_proj_sql = """
            INSERT INTO projects (
                title, abstract, academic_year, semester, project_type,
                status, visibility, department_id, created_by_user_id,
                guide_faculty_id, repository_url, plagiarism_score,
                duplication_score, plagiarism_report, plagiarism_status,
                created_at, updated_at
            )
            VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s)
            RETURNING id;
        """
        cur.execute(insert_proj_sql, (
            bp['title'],
            abstract,
            bp['academic_year'],
            bp['semester'],
            bp['type'],
            proj_status,
            "PUBLIC",
            1, # MCA Department ID
            author['id'],
            guide['id'],
            bp['repo'],
            plag_score if proj_status != "DRAFT" else None,
            dup_score if proj_status != "DRAFT" else None,
            plag_report if proj_status != "DRAFT" else None,
            "COMPLETED" if proj_status != "DRAFT" else "NOT_SCANNED",
            created_at,
            created_at + datetime.timedelta(hours=2)
        ))
        project_id = cur.fetchone()[0]

        # 1. Project Members
        # Author as Lead
        cur.execute("""
            INSERT INTO project_members (project_id, user_id, member_role)
            VALUES (%s, %s, %s);
        """, (project_id, author['id'], "Project Lead / Author"))
        
        # Co-members
        roles_pool = ["Core Backend Developer", "ML Research Engineer", "System Architect", "DevOps Contributor"]
        for cm_idx, cm in enumerate(co_members):
            cur.execute("""
                INSERT INTO project_members (project_id, user_id, member_role)
                VALUES (%s, %s, %s);
            """, (project_id, cm['id'], roles_pool[cm_idx % len(roles_pool)]))

        # 2. Workflow History
        # DRAFT created
        cur.execute("""
            INSERT INTO project_workflow_history (project_id, from_status, to_status, changed_by_user_id, remarks, created_at)
            VALUES (%s, %s, %s, %s, %s, %s);
        """, (project_id, "DRAFT", "DRAFT", author['id'], "Initial project draft registered.", created_at))

        if proj_status in ["SUBMITTED", "APPROVED"]:
            sub_time = created_at + datetime.timedelta(hours=1)
            cur.execute("""
                INSERT INTO project_workflow_history (project_id, from_status, to_status, changed_by_user_id, remarks, created_at)
                VALUES (%s, %s, %s, %s, %s, %s);
            """, (project_id, "DRAFT", "SUBMITTED", author['id'], "Submitted for Faculty Guide review.", sub_time))

        if proj_status == "APPROVED":
            rev_time = created_at + datetime.timedelta(hours=2)
            cur.execute("""
                INSERT INTO project_workflow_history (project_id, from_status, to_status, changed_by_user_id, remarks, created_at)
                VALUES (%s, %s, %s, %s, %s, %s);
            """, (project_id, "SUBMITTED", "UNDER_REVIEW", guide['id'], "Commenced technical evaluation and code audit.", rev_time))

            app_time = created_at + datetime.timedelta(hours=3)
            cur.execute("""
                INSERT INTO project_workflow_history (project_id, from_status, to_status, changed_by_user_id, remarks, created_at)
                VALUES (%s, %s, %s, %s, %s, %s);
            """, (project_id, "UNDER_REVIEW", "APPROVED", guide['id'], "Outstanding technical execution and documentation. Approved for public repository.", app_time))

        # 3. Generate 5-Page PDF Document
        clean_filename = f"Project_{project_id}_Academic_Documentation.pdf"
        proj_dir = os.path.join(STORAGE_ROOT, str(project_id))
        pdf_path = os.path.join(proj_dir, clean_filename)
        
        file_size = generate_5page_pdf(pdf_path, bp, author, guide, co_members)

        # 4. Insert into project_files
        cur.execute("""
            INSERT INTO project_files (
                project_id, file_name, file_type, file_size,
                storage_path, storage_type, file_path, uploaded_by_user_id,
                created_at, uploaded_at
            )
            VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s);
        """, (
            project_id,
            clean_filename,
            "application/pdf",
            file_size,
            pdf_path,
            "LOCAL",
            pdf_path,
            author['id'],
            created_at,
            created_at
        ))

        # 5. Insert AI Analysis
        cur.execute("""
            INSERT INTO ai_analyses (
                project_id, summary, domain, extracted_keywords,
                tech_stack, problem_statement, ai_status, updated_at
            )
            VALUES (%s, %s, %s, %s, %s, %s, %s, CURRENT_TIMESTAMP)
            ON CONFLICT (project_id) DO NOTHING;
        """, (
            project_id,
            abstract[:350] + "...",
            bp['domain'],
            bp['keywords'],
            bp['tech_stack'],
            bp['problem_statement'],
            "COMPLETED"
        ))

        # 6. Generate 384-dim SentenceTransformer Embedding
        if embedding_service and vector_service:
            try:
                emb_vector = embedding_service.generate_project_embedding(
                    title=bp['title'],
                    abstract=abstract,
                    tech_stack=bp['tech_stack'],
                    domain=bp['domain'],
                    keywords=bp['keywords']
                )
                vector_service.upsert_embedding(project_id, emb_vector)
            except Exception as emb_err:
                print(f"Embedding generation error for project #{project_id}: {emb_err}")

        created_projects.append((project_id, bp['title'], proj_status))
        if (idx + 1) % 10 == 0 or idx == len(PROJECT_BLUEPRINTS) - 1:
            conn.commit()
            print(f"  Processed {idx + 1}/50 projects (Latest: #{project_id} - {bp['title'][:40]}...)")

    conn.commit()
    cur.close()
    conn.close()

    print("\n==================================================")
    print("SUCCESSFULLY SEEDED 50 MCA PROJECTS WITH 5-PAGE PDFS!")
    print(f"Total Projects Created: {len(created_projects)}")
    print(f"Status Breakdown: 40 APPROVED, 5 SUBMITTED, 5 DRAFT")
    print("All files stored under: d:/projectvault/storage/projects/<id>/")
    print("==================================================")

if __name__ == "__main__":
    seed()
