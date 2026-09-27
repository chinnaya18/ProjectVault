import os
import sys
import json
import random
import datetime
import shutil
import psycopg2
from psycopg2.extras import execute_values

# Add ai-service to path for embedding generator
sys.path.insert(0, "d:/projectvault/ai-service")
try:
    from app.services.embedding_service import embedding_service
except Exception as e:
    print(f"Warning: could not import embedding service: {e}")
    embedding_service = None

from reportlab.lib.pagesizes import letter
from reportlab.platypus import SimpleDocTemplate, Paragraph, Spacer, PageBreak, Table, TableStyle
from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
from reportlab.lib import colors

DB_URL = "postgresql://postgres:0608@localhost:5432/projectvault"
STORAGE_ROOT = "d:/projectvault/storage/projects"

# 6 MCA Students (10 projects each = 60 projects)
STUDENTS = [
    {"id": 23, "name": "Bala", "email": "25mx101@university.edu", "roll": "25MX101"},
    {"id": 24, "name": "Gopi", "email": "25mx102@university.edu", "roll": "25MX102"},
    {"id": 25, "name": "Kaleel", "email": "25mx103@university.edu", "roll": "25MX103"},
    {"id": 26, "name": "Vikram", "email": "25mx104@university.edu", "roll": "25MX104"},
    {"id": 27, "name": "Chinnaya", "email": "25mx105@university.edu", "roll": "25MX105"},
    {"id": 28, "name": "Saravanavel", "email": "25mx106@university.edu", "roll": "25MX106"}
]

# 3 MCA Faculty Guides (20 projects assigned to each)
FACULTIES = [
    {"id": 20, "name": "Ms. Geetha", "email": "geetha@university.edu"},
    {"id": 21, "name": "Dr. Gayathri", "email": "gayathri@university.edu"},
    {"id": 22, "name": "Dr. Manavalan", "email": "manavalan@university.edu"}
]

PROJECTS_DATA = [
    # --- Student 1: Bala (10 Projects) ---
    {
        "student_idx": 0, "faculty_idx": 0, "status": "APPROVED",
        "title": "Autonomous Drone Fleet Telemetry and Multispectral Crop Yield Forecasting",
        "domain": "Artificial Intelligence & Precision Agriculture",
        "tech_stack": ["PyTorch", "FastAPI", "OpenCV", "ROS2", "PostgreSQL", "React"],
        "keywords": ["Autonomous Drones", "Precision Agriculture", "Multispectral Imaging", "Deep Neural Networks", "Crop Yield Forecasting"],
        "abstract": "This capstone research project implements an end-to-end autonomous UAV flight path optimization system coupled with real-time multispectral sensor telemetry processing. Using custom convolutional neural networks (CNNs) and NDVI vegetation index calibration, the platform accurately forecasts crop yield anomalies, detects early bacterial blight infection, and dispatches automated irrigation alerts to farm management dashboards.",
        "academic_year": "2025-2026", "semester": 6, "type": "CAPSTONE", "repo": "https://github.com/mca-research/drone-fleet-agri"
    },
    {
        "student_idx": 0, "faculty_idx": 0, "status": "APPROVED",
        "title": "Post-Quantum Cryptographic Key Encapsulation for Microservice Architectures",
        "domain": "Cybersecurity & Cryptography",
        "tech_stack": ["Python", "FastAPI", "Kyber-768", "Docker", "Go", "Redis"],
        "keywords": ["Post-Quantum Cryptography", "Lattice-Based", "CRYSTALS-Kyber", "Microservices Security", "Zero Trust"],
        "abstract": "A cloud-native security layer implementing NIST-standardized CRYSTALS-Kyber lattice-based post-quantum key encapsulation mechanisms (KEM) to safeguard inter-microservice remote procedure calls against harvest-now-decrypt-later quantum adversary threats.",
        "academic_year": "2025-2026", "semester": 6, "type": "CAPSTONE", "repo": "https://github.com/mca-research/post-quantum-microservices"
    },
    {
        "student_idx": 0, "faculty_idx": 0, "status": "APPROVED",
        "title": "Distributed Multi-Agent Reinforcement Learning for Urban Traffic Signal Control",
        "domain": "Intelligent Transportation & Reinforcement Learning",
        "tech_stack": ["PyTorch", "SUMO Simulator", "Python", "Ray RLlib", "React", "Kafka"],
        "keywords": ["Multi-Agent RL", "Traffic Optimization", "SUMO Simulation", "Deep Q-Networks", "Smart Cities"],
        "abstract": "An adaptive multi-agent deep Q-learning architecture for coordinating 24 connected intersections in urban arterial networks. Achieves a 34% reduction in peak-hour vehicle wait times and 22% lower idle emissions compared to fixed-time SCATS signal controllers.",
        "academic_year": "2024-2025", "semester": 5, "type": "Major Project", "repo": "https://github.com/mca-research/traffic-marl-sumo"
    },
    {
        "student_idx": 0, "faculty_idx": 0, "status": "APPROVED",
        "title": "Real-Time 3D Pulmonary Nodule Segmentation via Attention UNet and DICOM Pipelines",
        "domain": "Healthcare Informatics & Medical Imaging",
        "tech_stack": ["PyTorch", "MONAI", "FastAPI", "React", "DICOM", "PostgreSQL"],
        "keywords": ["Medical Imaging", "3D UNet", "Pulmonary Nodules", "CT Scans", "Deep Learning"],
        "abstract": "A clinical AI diagnostic assistant performing volumetric 3D segmentation of malignant pulmonary nodules from multi-slice thoracic CT scans. Integrated with hospital PACS servers via DICOMweb standards, achieving a Dice similarity coefficient of 0.894.",
        "academic_year": "2025-2026", "semester": 6, "type": "CAPSTONE", "repo": "https://github.com/mca-research/pulmonary-3dunet"
    },
    {
        "student_idx": 0, "faculty_idx": 0, "status": "APPROVED",
        "title": "Decentralized Academic Credential Verification via Soulbound Tokens on Polygon",
        "domain": "Blockchain & Web3 Technologies",
        "tech_stack": ["Solidity", "Hardhat", "Polygon", "React", "Node.js", "IPFS"],
        "keywords": ["Soulbound Tokens", "Polygon Network", "Academic Credentials", "IPFS", "Smart Contracts"],
        "abstract": "A non-transferable Soulbound Token (SBT) registry smart contract on Polygon PoS for issuing tamper-proof university diplomas and mark sheets. Enables instant zero-fee verification by employers through decentralized IPFS cryptographic hashes.",
        "academic_year": "2024-2025", "semester": 4, "type": "Mini Project", "repo": "https://github.com/mca-research/sbt-academic-credentials"
    },
    {
        "student_idx": 0, "faculty_idx": 0, "status": "APPROVED",
        "title": "Edge-AI Smart Aquaponics Ecosystem with LoRaWAN Sensor Mesh and Closed-Loop Control",
        "domain": "Internet of Things (IoT) & Embedded Systems",
        "tech_stack": ["ESP32", "MicroPython", "LoRaWAN", "FastAPI", "InfluxDB", "Grafana"],
        "keywords": ["Smart Aquaponics", "LoRaWAN", "Edge AI", "Dissolved Oxygen", "Automated Bio-filtration"],
        "abstract": "An automated closed-loop aquaponic monitoring station integrating optical dissolved oxygen, ammonia, and water temperature sensors over a 5km LoRa mesh. An embedded edge microcontroller manages bio-filter aeration and automated fish feeding cycles.",
        "academic_year": "2025-2026", "semester": 6, "type": "CAPSTONE", "repo": "https://github.com/mca-research/lora-aquaponics"
    },
    {
        "student_idx": 0, "faculty_idx": 0, "status": "APPROVED",
        "title": "Automated Source Code Vulnerability Detection via Graph Neural Networks and ASTs",
        "domain": "Software Engineering & AI Security",
        "tech_stack": ["PyTorch Geometric", "Tree-sitter", "Python", "FastAPI", "Docker"],
        "keywords": ["Graph Neural Networks", "Abstract Syntax Trees", "Vulnerability Detection", "CWE-89", "Static Analysis"],
        "abstract": "Transforms C/C++ and Java source code into joint Control Flow Graphs and ASTs to detect buffer overflows, SQL injections, and race conditions using Gated Graph Neural Networks before pull requests are merged.",
        "academic_year": "2024-2025", "semester": 5, "type": "Major Project", "repo": "https://github.com/mca-research/ast-gnn-vuln-detector"
    },
    {
        "student_idx": 0, "faculty_idx": 0, "status": "APPROVED",
        "title": "Multilingual Speech-to-Text Transcription and Clinical Summarization for Tamil & English",
        "domain": "Natural Language Processing (NLP)",
        "tech_stack": ["Whisper", "Transformers", "PyTorch", "FastAPI", "React", "PostgreSQL"],
        "keywords": ["Speech-to-Text", "Multilingual NLP", "Clinical Summarization", "Tamil ASR", "Whisper Fine-tuning"],
        "abstract": "Fine-tunes OpenAI Whisper on code-switched Tamil-English outpatient doctor-patient dialogues. Automatically generates structured SOAP notes (Subjective, Objective, Assessment, Plan) with ICD-10 medical code extraction.",
        "academic_year": "2025-2026", "semester": 6, "type": "CAPSTONE", "repo": "https://github.com/mca-research/tamil-clinical-whisper"
    },
    {
        "student_idx": 0, "faculty_idx": 0, "status": "UNDER_REVIEW",
        "title": "Privacy-Preserving Federated Learning for Distributed Financial Fraud Detection",
        "domain": "Federated Learning & FinTech Security",
        "tech_stack": ["PySyft", "PyTorch", "FastAPI", "Redis", "Docker", "PostgreSQL"],
        "keywords": ["Federated Learning", "Differential Privacy", "Fraud Detection", "Banking Consortia", "Homomorphic Encryption"],
        "abstract": "A collaborative fraud detection protocol enabling multi-bank transaction pattern learning without exposing proprietary customer PII, leveraging Secure Multi-Party Computation and epsilon-differential privacy noise budgets.",
        "academic_year": "2025-2026", "semester": 6, "type": "CAPSTONE", "repo": "https://github.com/mca-research/federated-fraud-syft"
    },
    {
        "student_idx": 0, "faculty_idx": 0, "status": "REJECTED",
        "title": "Basic Online Bookstore with Shopping Cart and Payment Gateway",
        "domain": "Web Engineering",
        "tech_stack": ["PHP", "MySQL", "HTML5", "CSS3", "JavaScript"],
        "keywords": ["E-Commerce", "Bookstore", "PHP", "MySQL", "Shopping Cart"],
        "abstract": "A traditional LAMP stack web application allowing users to browse books, add items to session cart, and make sandbox credit card payments.",
        "academic_year": "2025-2026", "semester": 6, "type": "Mini Project", "repo": "https://github.com/mca-research/basic-bookstore-php"
    },

    # --- Student 2: Gopi (10 Projects) ---
    {
        "student_idx": 1, "faculty_idx": 0, "status": "APPROVED",
        "title": "Serverless Function Cold-Start Mitigation Using Predictive Warm-Up Queues",
        "domain": "Cloud Computing & Distributed Systems",
        "tech_stack": ["AWS Lambda", "Python", "Redis", "Kafka", "FastAPI", "Docker"],
        "keywords": ["Serverless", "Cold Start", "FaaS", "Predictive Caching", "Event-Driven"],
        "abstract": "Implements an intelligent predictive warming daemon for AWS Lambda and OpenFaaS that monitors HTTP ingress traffic distributions and preemptively provisions warm container instances, decreasing P99 latency by 78%.",
        "academic_year": "2024-2025", "semester": 5, "type": "CAPSTONE", "repo": "https://github.com/mca-research/serverless-coldstart-optimizer"
    },
    {
        "student_idx": 1, "faculty_idx": 0, "status": "APPROVED",
        "title": "Automated Retinal Fundus Glaucoma Screening Using Vision Transformers",
        "domain": "Healthcare Informatics & Medical Imaging",
        "tech_stack": ["PyTorch", "Swin Transformer", "FastAPI", "React", "OpenCV"],
        "keywords": ["Vision Transformers", "Glaucoma Detection", "Fundus Photography", "Optic Cup/Disc Ratio"],
        "abstract": "Automates vertical Cup-to-Disc Ratio (vCDR) calculation from digital fundus photography using Swin-Transformer backbones, delivering early-stage primary open-angle glaucoma risk assessments in underserved rural clinics.",
        "academic_year": "2025-2026", "semester": 6, "type": "CAPSTONE", "repo": "https://github.com/mca-research/retinal-glaucoma-vit"
    },
    {
        "student_idx": 1, "faculty_idx": 0, "status": "APPROVED",
        "title": "High-Throughput Geo-Replicated Event Bus with Raft Consensus Engine",
        "domain": "Distributed Systems & Cloud Computing",
        "tech_stack": ["Java", "Spring Boot", "Apache Kafka", "RocksDB", "gRPC"],
        "keywords": ["Distributed Systems", "Raft Consensus", "Geo-Replication", "Fault Tolerance", "Event Bus"],
        "abstract": "A low-latency distributed transaction commit log implementing Raft leader election and multi-region state machine replication with disk-persisted RocksDB storage engines, sustaining 120,000 writes/sec under network partition tests.",
        "academic_year": "2024-2025", "semester": 6, "type": "Major Project", "repo": "https://github.com/mca-research/distributed-raft-event-bus"
    },
    {
        "student_idx": 1, "faculty_idx": 0, "status": "APPROVED",
        "title": "Zero-Knowledge Rollup Aggregator for High-Speed Micro-Transactions on Ethereum",
        "domain": "Blockchain & Cryptography",
        "tech_stack": ["Circom", "SnarkJS", "Solidity", "Node.js", "PostgreSQL"],
        "keywords": ["Zero-Knowledge Proofs", "zk-SNARKs", "Layer 2 Rollups", "Ethereum Scalability"],
        "abstract": "Constructs a recursive zk-SNARK batch prover compressing 500 off-chain asset transfers into a single verifiable cryptographic succinct proof, slashing Ethereum gas verification fees by 94%.",
        "academic_year": "2025-2026", "semester": 6, "type": "CAPSTONE", "repo": "https://github.com/mca-research/zk-rollup-aggregator"
    },
    {
        "student_idx": 1, "faculty_idx": 0, "status": "APPROVED",
        "title": "Intelligent EV Charging Fleet Scheduling with Dynamic Grid Tariff Optimization",
        "domain": "Smart Grids & Renewable Energy Systems",
        "tech_stack": ["Python", "SciPy", "FastAPI", "React", "PostgreSQL", "Docker"],
        "keywords": ["Electric Vehicles", "Smart Charging", "Dynamic Tariffs", "Linear Programming", "Peak Shaving"],
        "abstract": "A mixed-integer linear programming (MILP) scheduler that coordinates commercial electric bus depot charging overnight, factoring in hourly time-of-use tariffs, battery state of health, and grid transformer capacity constraints.",
        "academic_year": "2024-2025", "semester": 5, "type": "Major Project", "repo": "https://github.com/mca-research/ev-fleet-charging-optimizer"
    },
    {
        "student_idx": 1, "faculty_idx": 0, "status": "APPROVED",
        "title": "Neural Machine Translation for Technical Software Documentation in Indic Languages",
        "domain": "Natural Language Processing (NLP)",
        "tech_stack": ["HuggingFace", "PyTorch", "FastAPI", "React", "MarianMT"],
        "keywords": ["Neural Machine Translation", "IndicNLP", "MarianMT", "Technical Glossary", "Tamil Translation"],
        "abstract": "Custom fine-tunes Transformer sequence-to-sequence models with terminology-constrained decoding to translate developer documentation and software errors into Tamil, Hindi, and Telugu without corrupting CLI syntax.",
        "academic_year": "2025-2026", "semester": 6, "type": "CAPSTONE", "repo": "https://github.com/mca-research/indic-doc-translator"
    },
    {
        "student_idx": 1, "faculty_idx": 0, "status": "APPROVED",
        "title": "Host-Based Ransomware Early Warning System via Behavioral I/O Entropy Analysis",
        "domain": "Cybersecurity & Malware Defense",
        "tech_stack": ["C++", "eBPF", "Python", "FastAPI", "Linux Kernel", "PostgreSQL"],
        "keywords": ["Ransomware Detection", "eBPF", "Shannon Entropy", "File System Heuristics", "Kernel Probing"],
        "abstract": "Leverages Linux eBPF kernel tracepoints to monitor high-frequency file modification bursts and compute real-time Shannon entropy shifts, freezing compromised process trees before irreversible encryption occurs.",
        "academic_year": "2025-2026", "semester": 6, "type": "CAPSTONE", "repo": "https://github.com/mca-research/ebpf-ransomware-shield"
    },
    {
        "student_idx": 1, "faculty_idx": 0, "status": "APPROVED",
        "title": "Real-Time Indian Sign Language Gesture Translation via MediaPipe and Temporal Convolutions",
        "domain": "Computer Vision & Accessibility Systems",
        "tech_stack": ["OpenCV", "MediaPipe", "PyTorch", "FastAPI", "React"],
        "keywords": ["Sign Language Recognition", "MediaPipe", "Temporal Convolutional Networks", "Accessibility"],
        "abstract": "Captures 3D skeletal hand landmarks using commodity webcams and classifies 120 dynamic Indian Sign Language phrases into spoken English and Tamil audio with sub-100ms inference latency.",
        "academic_year": "2024-2025", "semester": 4, "type": "Mini Project", "repo": "https://github.com/mca-research/isl-realtime-translator"
    },
    {
        "student_idx": 1, "faculty_idx": 0, "status": "SUBMITTED",
        "title": "Autonomous Indoor Warehouse Navigation via LiDAR SLAM and Dynamic Obstacle Avoidance",
        "domain": "Autonomous Robotics & Embedded AI",
        "tech_stack": ["ROS2", "Cartographer SLAM", "C++", "Python", "Gazebo"],
        "keywords": ["LiDAR SLAM", "ROS2 Navigation2", "Warehouse Robotics", "Path Planning", "Obstacle Avoidance"],
        "abstract": "Deploys 2D LiDAR Cartographer SLAM on differential-drive automated guided vehicles (AGVs) for pallet transportation in crowded fulfillment centers with dynamic pedestrian avoidance.",
        "academic_year": "2025-2026", "semester": 6, "type": "CAPSTONE", "repo": "https://github.com/mca-research/ros2-agv-slam"
    },
    {
        "student_idx": 1, "faculty_idx": 0, "status": "APPROVED",
        "title": "Automated Defect Detection in Semiconductor Wafers via Unsupervised Variational Autoencoders",
        "domain": "Computer Vision & Smart Manufacturing",
        "tech_stack": ["TensorFlow", "FastAPI", "OpenCV", "React", "PostgreSQL"],
        "keywords": ["Semiconductor Inspection", "Variational Autoencoder", "Defect Detection", "Unsupervised Learning"],
        "abstract": "Detects scratch, donut, and edge-ring anomalies in semiconductor silicon wafer scanning electron microscopy (SEM) images using reconstruction loss thresholds in deep convolutional autoencoders.",
        "academic_year": "2025-2026", "semester": 6, "type": "CAPSTONE", "repo": "https://github.com/mca-research/wafer-defect-vae"
    },

    # --- Student 3: Kaleel (10 Projects) ---
    {
        "student_idx": 2, "faculty_idx": 1, "status": "APPROVED",
        "title": "Decentralized Pharmaceutical Supply Chain Provenance Tracking on Hyperledger Fabric",
        "domain": "Blockchain & Enterprise Distributed Systems",
        "tech_stack": ["Hyperledger Fabric", "Go", "Node.js", "Docker", "React", "PostgreSQL"],
        "keywords": ["Hyperledger Fabric", "Pharma Supply Chain", "Counterfeit Drugs", "Chaincode", "Cold Chain"],
        "abstract": "An enterprise permissioned blockchain tracking cold-chain temperature telemetry and serial numbers of prescription oncology medicines from manufacturer to dispensing hospital pharmacies to eradicate counterfeit drug injection.",
        "academic_year": "2025-2026", "semester": 6, "type": "CAPSTONE", "repo": "https://github.com/mca-research/hyperledger-pharma-provenance"
    },
    {
        "student_idx": 2, "faculty_idx": 1, "status": "APPROVED",
        "title": "Bi-Directional Transformer for Legal Contract Clause Extraction and Risk Scoring",
        "domain": "Natural Language Processing (NLP) & LegalTech",
        "tech_stack": ["Legal-BERT", "PyTorch", "FastAPI", "React", "spaCy", "PostgreSQL"],
        "keywords": ["Legal-BERT", "Clause Extraction", "Risk Scoring", "Contract Analysis", "Indemnity Clauses"],
        "abstract": "Extracts non-standard indemnity, termination, and confidentiality clauses from 60-page master services agreements (MSAs) using fine-tuned Legal-BERT with hierarchical attention weights.",
        "academic_year": "2025-2026", "semester": 6, "type": "CAPSTONE", "repo": "https://github.com/mca-research/legal-clause-extractor"
    },
    {
        "student_idx": 2, "faculty_idx": 1, "status": "APPROVED",
        "title": "Edge-Assisted Fall Detection and Vital Signs Anomaly Alert for Geriatric Care",
        "domain": "Internet of Things (IoT) & Ambient Assisted Living",
        "tech_stack": ["Raspberry Pi", "OpenCV", "MQTT", "FastAPI", "React", "Twilio"],
        "keywords": ["Fall Detection", "Geriatric Monitoring", "Edge Vision", "MQTT Telemetry", "Ambient Assisted Living"],
        "abstract": "An unobtrusive ceiling-mounted thermal camera and mmWave radar station that detects abrupt posture collapses and abnormal respiration rates in elderly care facilities without capturing identifiable RGB facial imagery.",
        "academic_year": "2024-2025", "semester": 5, "type": "Major Project", "repo": "https://github.com/mca-research/geriatric-fall-detection"
    },
    {
        "student_idx": 2, "faculty_idx": 1, "status": "APPROVED",
        "title": "AI-Driven Acoustic Leak Detection and Localization in Urban Water Distribution Mains",
        "domain": "Smart Cities & Digital Signal Processing",
        "tech_stack": ["Python", "Librosa", "PyTorch", "FastAPI", "PostgreSQL", "React"],
        "keywords": ["Acoustic Leak Detection", "Hydrophone Sensors", "Wavelet Transform", "Smart Water Grids"],
        "abstract": "Processes hydrophone acoustic noise vibration signals along municipal water mains using Continuous Wavelet Transform (CWT) scalograms and CNNs to locate sub-surface pipe fractures within 1.5 meters accuracy.",
        "academic_year": "2025-2026", "semester": 6, "type": "CAPSTONE", "repo": "https://github.com/mca-research/water-pipe-acoustic-leak"
    },
    {
        "student_idx": 2, "faculty_idx": 1, "status": "APPROVED",
        "title": "Quantum-Resistant Lattice Key Encapsulation in TLS 1.3 Transport Protocols",
        "domain": "Cybersecurity & Cryptography",
        "tech_stack": ["C", "OpenSSL", "Python", "FastAPI", "Wireshark"],
        "keywords": ["Post-Quantum TLS", "NIST Kyber", "Handshake Optimization", "Transport Security"],
        "abstract": "Integrates liboqs post-quantum hybrid key exchange algorithms (X25519 + Kyber-768) into web servers and benchmarks TLS 1.3 handshake packet overhead and TLS termination latency across cellular 5G networks.",
        "academic_year": "2024-2025", "semester": 6, "type": "Major Project", "repo": "https://github.com/mca-research/tls-post-quantum-benchmarks"
    },
    {
        "student_idx": 2, "faculty_idx": 1, "status": "APPROVED",
        "title": "Zero-Downtime Multi-Region Database Synchronization via Kafka CDC Connectors",
        "domain": "Cloud Infrastructure & Database Engineering",
        "tech_stack": ["Debezium", "PostgreSQL", "Apache Kafka", "Docker", "Java Spring Boot"],
        "keywords": ["Change Data Capture", "Debezium", "Multi-Region Sync", "Active-Active Replication"],
        "abstract": "A bi-directional Active-Active database synchronization pipeline handling conflicts with vector clock resolution strategies and Debezium transactional log scraping with sub-second replication delay.",
        "academic_year": "2023-2024", "semester": 6, "type": "CAPSTONE", "repo": "https://github.com/mca-research/cdc-multi-region-database-sync"
    },
    {
        "student_idx": 2, "faculty_idx": 1, "status": "APPROVED",
        "title": "Explainable Deep Learning for Cardiac Arrhythmia Detection via 12-Lead ECG Signals",
        "domain": "Healthcare Informatics & Signal Processing",
        "tech_stack": ["PyTorch", "SHAP", "FastAPI", "React", "NumPy"],
        "keywords": ["ECG Classification", "Cardiac Arrhythmia", "Grad-CAM", "SHAP Interpretability", "Healthcare AI"],
        "abstract": "Classifies 16 rhythmic cardiovascular anomalies from digitized 12-lead electrocardiograms with integrated Grad-CAM and SHAP attribution maps for cardiologists to verify AI clinical reasoning.",
        "academic_year": "2025-2026", "semester": 6, "type": "CAPSTONE", "repo": "https://github.com/mca-research/explainable-ecg-arrhythmia"
    },
    {
        "student_idx": 2, "faculty_idx": 1, "status": "APPROVED",
        "title": "Automated High-Performance Database Query Plan Optimization via Deep Reinforcement Learning",
        "domain": "Database Engineering & Intelligent Systems",
        "tech_stack": ["PostgreSQL", "Python", "PyTorch", "Gymnasium", "Docker"],
        "keywords": ["Query Optimizer", "Join Order Optimization", "Deep RL", "PostgreSQL Engine"],
        "abstract": "Replaces static cost-based join-order enumeration algorithms in relational databases with deep reinforcement learning policies, speeding up complex OLAP analytical queries by 3.2x.",
        "academic_year": "2024-2025", "semester": 5, "type": "Major Project", "repo": "https://github.com/mca-research/rl-db-query-optimizer"
    },
    {
        "student_idx": 2, "faculty_idx": 1, "status": "UNDER_REVIEW",
        "title": "Decentralized Microgrid Peer-to-Peer Solar Energy Trading via Automated Smart Contracts",
        "domain": "Smart Grids & Blockchain",
        "tech_stack": ["Solidity", "Hardhat", "React", "Node.js", "Web3.js"],
        "keywords": ["P2P Energy Trading", "Solar Microgrid", "Smart Contracts", "Double Auction"],
        "abstract": "A decentralized continuous double-auction marketplace enabling prosumers with rooftop solar photovoltaics to trade surplus kilowatt-hours with neighboring residences autonomously.",
        "academic_year": "2025-2026", "semester": 6, "type": "CAPSTONE", "repo": "https://github.com/mca-research/p2p-solar-energy-trading"
    },
    {
        "student_idx": 2, "faculty_idx": 1, "status": "REJECTED",
        "title": "Student Attendance Management System Using Simple Barcode Scanner",
        "domain": "Basic Information Systems",
        "tech_stack": ["Java Swing", "MySQL", "JDBC"],
        "keywords": ["Attendance", "Barcode", "Java Swing", "MySQL"],
        "abstract": "A desktop GUI application that scans barcode strings from student ID cards and stores timestamps in a local MySQL table.",
        "academic_year": "2025-2026", "semester": 6, "type": "Mini Project", "repo": "https://github.com/mca-research/barcode-attendance-swing"
    },

    # --- Student 4: Vikram (10 Projects) ---
    {
        "student_idx": 3, "faculty_idx": 1, "status": "APPROVED",
        "title": "Cloud-Native Microservices Orchestrator with Intelligent Pod Autoscaling",
        "domain": "Cloud Computing & Distributed Systems",
        "tech_stack": ["Kubernetes", "Go", "Prometheus", "Docker", "gRPC", "Envoy"],
        "keywords": ["Kubernetes", "Horizontal Pod Autoscaling", "Cloud-Native", "Microservices", "Telemetry"],
        "abstract": "A Kubernetes custom controller implementing time-series ARIMA and LSTM workload forecast models to horizontally scale microservice replica sets 90 seconds in advance of traffic surges.",
        "academic_year": "2025-2026", "semester": 6, "type": "CAPSTONE", "repo": "https://github.com/mca-research/k8s-predictive-hpa"
    },
    {
        "student_idx": 3, "faculty_idx": 1, "status": "APPROVED",
        "title": "Multimodal Cancer Patient Survival Prognosis Using Clinical Graphs and Genomics",
        "domain": "Bioinformatics & Deep Learning",
        "tech_stack": ["PyTorch", "PyG", "FastAPI", "React", "Biopython", "PostgreSQL"],
        "keywords": ["Bioinformatics", "Graph Neural Networks", "Genomics", "Survival Analysis", "Cox Proportional Hazards"],
        "abstract": "Combines whole-exome sequencing mutation profiles with patient pathology reports and electronic health record history using graph convolutional networks to forecast 5-year overall survival trajectories.",
        "academic_year": "2024-2025", "semester": 6, "type": "CAPSTONE", "repo": "https://github.com/mca-research/gnn-cancer-survival"
    },
    {
        "student_idx": 3, "faculty_idx": 1, "status": "APPROVED",
        "title": "Real-Time Cyber Threat Intelligence Mining from Dark Web Forums via Transformer NER",
        "domain": "Cybersecurity & OSINT",
        "tech_stack": ["Python", "HuggingFace", "FastAPI", "Elasticsearch", "React", "Tor"],
        "keywords": ["Threat Intelligence", "OSINT", "Dark Web", "Named Entity Recognition", "Cybersecurity"],
        "abstract": "An automated threat intelligence scraper and NLP entity extraction engine classifying zero-day vulnerability trading discussions and stolen credential listings from dark web forums into structured STIX/TAXII feeds.",
        "academic_year": "2025-2026", "semester": 6, "type": "CAPSTONE", "repo": "https://github.com/mca-research/darkweb-threat-ner"
    },
    {
        "student_idx": 3, "faculty_idx": 1, "status": "APPROVED",
        "title": "Autonomous Underwater Drone Pathfinding and Coral Bleaching Quantification via Sonar",
        "domain": "Ocean Robotics & Environmental AI",
        "tech_stack": ["PyTorch", "ROS2", "OpenCV", "FastAPI", "React", "PostgreSQL"],
        "keywords": ["Autonomous Underwater Vehicles", "Coral Bleaching", "Side-Scan Sonar", "Marine Ecology"],
        "abstract": "An autonomous underwater vehicle (AUV) firmware implementing side-scan sonar image registration and semantic segmentation to map and quantify coral reef bleaching percentages across shallow lagoon ecosystems.",
        "academic_year": "2024-2025", "semester": 5, "type": "Major Project", "repo": "https://github.com/mca-research/auv-coral-sonar"
    },
    {
        "student_idx": 3, "faculty_idx": 1, "status": "APPROVED",
        "title": "Decentralized Autonomous Zero-Knowledge KYC Verification for Banking Onboarding",
        "domain": "FinTech & Zero-Knowledge Cryptography",
        "tech_stack": ["Circom", "SnarkJS", "Solidity", "React", "Node.js"],
        "keywords": ["Zero-Knowledge KYC", "Circom", "Identity Protection", "FinTech", "zk-SNARKs"],
        "abstract": "Enables new bank customers to prove nationality, age eligibility (>18), and sanction-free status using cryptographic proofs over government biometric digital passports without revealing name, address, or national ID digits.",
        "academic_year": "2025-2026", "semester": 6, "type": "CAPSTONE", "repo": "https://github.com/mca-research/zk-kyc-identity"
    },
    {
        "student_idx": 3, "faculty_idx": 1, "status": "APPROVED",
        "title": "Intelligent Smart Parking Sensor Network with Edge AI Vehicle Localization",
        "domain": "Internet of Things (IoT) & Smart Cities",
        "tech_stack": ["ESP32-CAM", "TensorFlow Lite", "MQTT", "FastAPI", "React", "PostgreSQL"],
        "keywords": ["Smart Parking", "ESP32", "Edge Vision", "MQTT", "Urban Mobility"],
        "abstract": "A low-power smart city parking infrastructure deploying ultra-low cost ESP32-CAM microcontrollers running quantized MobileNet models to broadcast parking slot vacancy states in real time over lightweight MQTT brokers.",
        "academic_year": "2024-2025", "semester": 4, "type": "Mini Project", "repo": "https://github.com/mca-research/smart-parking-edge-ai"
    },
    {
        "student_idx": 3, "faculty_idx": 1, "status": "APPROVED",
        "title": "Automated Legal Document Redaction and PII Anonymization via Contextual Transformers",
        "domain": "Natural Language Processing & Data Privacy",
        "tech_stack": ["spaCy", "Transformers", "Python", "FastAPI", "React"],
        "keywords": ["PII Anonymization", "Legal Redaction", "GDPR Compliance", "Contextual NLP"],
        "abstract": "An enterprise privacy engine identifying and masking sensitive litigant names, financial identifiers, and residential coordinates in court judgements with 99.4% precision prior to open-access public repository release.",
        "academic_year": "2025-2026", "semester": 6, "type": "CAPSTONE", "repo": "https://github.com/mca-research/legal-pii-redactor"
    },
    {
        "student_idx": 3, "faculty_idx": 1, "status": "APPROVED",
        "title": "Automated Multi-Spectral Drone Forest Fire Boundary Segmentation and Spread Simulation",
        "domain": "Disaster Management & Spatial AI",
        "tech_stack": ["PyTorch", "GDAL", "FastAPI", "React", "PostGIS", "Docker"],
        "keywords": ["Wildfire Spread", "Thermal Segmentation", "FARSITE Simulation", "UAV Telemetry"],
        "abstract": "Integrates drone thermal infrared orthomosaics with real-time wind speed vectors to segment active wildfire perimeters and compute forward fire front propagation simulations for emergency fire response units.",
        "academic_year": "2024-2025", "semester": 5, "type": "Major Project", "repo": "https://github.com/mca-research/wildfire-drone-segmentation"
    },
    {
        "student_idx": 3, "faculty_idx": 1, "status": "SUBMITTED",
        "title": "Real-Time AI Micro-Expression Lie Detection from High-Speed Video Streams",
        "domain": "Computer Vision & Affective Computing",
        "tech_stack": ["OpenCV", "PyTorch", "FastAPI", "React"],
        "keywords": ["Micro-Expressions", "Facial Action Units", "Affective Computing", "3D CNN"],
        "abstract": "Detects subtle 40-millisecond involuntary facial muscle twitches around ocular and zygomatic regions from 120fps video streams using 3D spatio-temporal convolutional networks.",
        "academic_year": "2025-2026", "semester": 6, "type": "CAPSTONE", "repo": "https://github.com/mca-research/micro-expression-detection"
    },
    {
        "student_idx": 3, "faculty_idx": 1, "status": "APPROVED",
        "title": "Distributed In-Memory Key-Value Storage with Active-Active Geo-Replication",
        "domain": "Distributed Systems & Cloud Storage",
        "tech_stack": ["Rust", "Tokio", "Raft", "gRPC", "Docker"],
        "keywords": ["Key-Value Store", "Rust Tokio", "Active-Active", "Distributed Hash Tables"],
        "abstract": "A high-performance in-memory key-value cache written in async Rust featuring consistent hashing partition rings, automated node failover rebalancing, and eventual consistency sync mechanisms.",
        "academic_year": "2025-2026", "semester": 6, "type": "CAPSTONE", "repo": "https://github.com/mca-research/rust-async-kv-store"
    },

    # --- Student 5: Chinnaya (10 Projects) ---
    {
        "student_idx": 4, "faculty_idx": 2, "status": "APPROVED",
        "title": "AI-Powered Smart Grid Energy Optimization and Load Shifting with Battery Storage",
        "domain": "Smart Grids & Sustainable Computing",
        "tech_stack": ["Python", "TensorFlow", "FastAPI", "React", "PostgreSQL", "Pandas"],
        "keywords": ["Smart Grid", "Peak Shaving", "Battery Energy Storage", "Load Forecasting", "LSTM"],
        "abstract": "An industrial smart grid management engine that forecasts localized renewable solar generation and shifts commercial chiller loads into battery storage windows to reduce peak utility demand charges by 28%.",
        "academic_year": "2025-2026", "semester": 6, "type": "CAPSTONE", "repo": "https://github.com/mca-research/smart-grid-load-shifting"
    },
    {
        "student_idx": 4, "faculty_idx": 2, "status": "APPROVED",
        "title": "Cross-Chain Decentralized Oracle Aggregator with Verifiable Random Functions",
        "domain": "Blockchain & Cryptographic Oracles",
        "tech_stack": ["Solidity", "Chainlink VRF", "Node.js", "React", "Ethereum"],
        "keywords": ["Decentralized Oracles", "Chainlink VRF", "Cross-Chain", "Smart Contracts", "Price Feeds"],
        "abstract": "Aggregates multi-source financial exchange price feeds across Ethereum and Arbitrum with verifiable random cryptographic node selection, eliminating single-point oracle frontrunning exploits.",
        "academic_year": "2024-2025", "semester": 6, "type": "CAPSTONE", "repo": "https://github.com/mca-research/cross-chain-oracle-aggregator"
    },
    {
        "student_idx": 4, "faculty_idx": 2, "status": "APPROVED",
        "title": "Deep Reinforcement Learning for Autonomous Drone Swarm Search and Rescue Operations",
        "domain": "Robotics & Multi-Agent AI",
        "tech_stack": ["ROS2", "PyTorch", "AirSim", "Python", "FastAPI", "React"],
        "keywords": ["Drone Swarm", "Search and Rescue", "Multi-Agent RL", "Obstacle Avoidance", "AirSim"],
        "abstract": "Simulates collaborative aerial swarm search strategies in collapsed building rubble zones. Achieves 92% victim localization coverage within 15 minutes of drone deployment using decentralized policy gradient algorithms.",
        "academic_year": "2025-2026", "semester": 6, "type": "CAPSTONE", "repo": "https://github.com/mca-research/drone-swarm-search-rescue"
    },
    {
        "student_idx": 4, "faculty_idx": 2, "status": "APPROVED",
        "title": "End-to-End Encrypted Healthcare Teleconsultation and Medical Record Sharing Platform",
        "domain": "Healthcare Informatics & Security",
        "tech_stack": ["React", "WebRTC", "Node.js", "Signal Protocol", "PostgreSQL"],
        "keywords": ["Telemedicine", "WebRTC", "Signal Protocol", "End-to-End Encryption", "HIPAA Compliance"],
        "abstract": "A peer-to-peer WebRTC video consultation suite embedding the Double Ratchet cryptographic protocol for forward-secret medical consultation sessions and patient-consented EHR document exchanges.",
        "academic_year": "2024-2025", "semester": 5, "type": "Major Project", "repo": "https://github.com/mca-research/e2ee-teleconsultation"
    },
    {
        "student_idx": 4, "faculty_idx": 2, "status": "APPROVED",
        "title": "Automated High-Resolution Road Pothole Detection via Mobile Edge Computing & Accelerometers",
        "domain": "Smart Cities & Edge AI",
        "tech_stack": ["Android", "TensorFlow Lite", "FastAPI", "PostGIS", "React", "Mapbox"],
        "keywords": ["Road Surface Monitoring", "Pothole Detection", "Mobile Edge AI", "Accelerometer Fusion", "Smart Cities"],
        "abstract": "Combines smartphone 3-axis accelerometer shock telemetry with windshield camera object detection on municipal buses to dynamically map urban road degradation zones on interactive GIS road repair dashboards.",
        "academic_year": "2024-2025", "semester": 4, "type": "Mini Project", "repo": "https://github.com/mca-research/mobile-pothole-detector"
    },
    {
        "student_idx": 4, "faculty_idx": 2, "status": "APPROVED",
        "title": "Conversational AI Code Assistant with Contextual RAG over Private Git Repositories",
        "domain": "Generative AI & Software Engineering",
        "tech_stack": ["FastAPI", "SentenceTransformers", "pgvector", "React", "PostgreSQL"],
        "keywords": ["RAG", "Code Search", "Generative AI", "pgvector", "Software Engineering"],
        "abstract": "Indexes multi-branch Git source code syntax trees in vector embeddings to provide development teams with contextual code explanation, automated refactoring suggestions, and unit test generation.",
        "academic_year": "2025-2026", "semester": 6, "type": "CAPSTONE", "repo": "https://github.com/mca-research/codebase-rag-assistant"
    },
    {
        "student_idx": 4, "faculty_idx": 2, "status": "APPROVED",
        "title": "Automated Microscopic Blood Cell Classification and Leukaemia Screening System",
        "domain": "Medical Imaging & Healthcare AI",
        "tech_stack": ["PyTorch", "EfficientNet", "FastAPI", "OpenCV", "React"],
        "keywords": ["Hematology", "Leukaemia Detection", "Blood Smear Analysis", "Deep Learning", "WBC Classification"],
        "abstract": "Analyzes peripheral blood smear microscopic slides to classify white blood cell sub-types (lymphocytes, monocytes, blasts) and flags acute lymphoblastic leukaemia morphology with 96.8% sensitivity.",
        "academic_year": "2025-2026", "semester": 6, "type": "CAPSTONE", "repo": "https://github.com/mca-research/leukaemia-blood-cell-ai"
    },
    {
        "student_idx": 4, "faculty_idx": 2, "status": "APPROVED",
        "title": "Privacy-Preserving Contactless Palmprint Biometric Authentication via Gabor Filters",
        "domain": "Biometric Security & Computer Vision",
        "tech_stack": ["Python", "OpenCV", "FastAPI", "React", "PostgreSQL"],
        "keywords": ["Palmprint Authentication", "Gabor Filters", "Biometrics", "Contactless Sensing"],
        "abstract": "A contactless mobile camera biometric verification engine extracting directional principal line textures from user palmprints, generating cancelable biometric templates resistant to database spoofing.",
        "academic_year": "2024-2025", "semester": 5, "type": "Major Project", "repo": "https://github.com/mca-research/palmprint-biometrics"
    },
    {
        "student_idx": 4, "faculty_idx": 2, "status": "UNDER_REVIEW",
        "title": "Zero-Trust Microsegmentation Network Controller with eBPF Packet Filtering",
        "domain": "Cybersecurity & Cloud Infrastructure",
        "tech_stack": ["eBPF", "Go", "C", "FastAPI", "React", "Linux Kernel"],
        "keywords": ["Zero Trust", "Microsegmentation", "eBPF", "Packet Inspection", "Network Security"],
        "abstract": "An identity-based microsegmentation security proxy enforcing dynamic least-privilege egress network policies across Linux container cgroups at the kernel socket layer.",
        "academic_year": "2025-2026", "semester": 6, "type": "CAPSTONE", "repo": "https://github.com/mca-research/ebpf-microsegmentation"
    },
    {
        "student_idx": 4, "faculty_idx": 2, "status": "REJECTED",
        "title": "Online Quiz Application with Timer and Score Leaderboard",
        "domain": "Web Applications",
        "tech_stack": ["JavaScript", "Node.js", "Express", "MongoDB"],
        "keywords": ["Quiz Application", "Timer", "Leaderboard", "JavaScript"],
        "abstract": "A web portal where students can answer multiple-choice questions within 30 seconds and view high scores on a public leaderboard table.",
        "academic_year": "2025-2026", "semester": 6, "type": "Mini Project", "repo": "https://github.com/mca-research/simple-quiz-app"
    },

    # --- Student 6: Saravanavel (10 Projects) ---
    {
        "student_idx": 5, "faculty_idx": 2, "status": "APPROVED",
        "title": "Decentralized Energy Certificate Trading Platform on Polygon PoS",
        "domain": "Blockchain & Green Energy",
        "tech_stack": ["Solidity", "Polygon", "React", "Node.js", "Hardhat"],
        "keywords": ["Renewable Energy", "Green Certificates", "Polygon", "Smart Contracts", "Sustainability"],
        "abstract": "Tokenizes green energy production from commercial wind farms and solar plants into fractional ERC-1155 certificates, preventing double-counting and enabling transparent ESG audit compliance.",
        "academic_year": "2025-2026", "semester": 6, "type": "CAPSTONE", "repo": "https://github.com/mca-research/polygon-green-energy-certs"
    },
    {
        "student_idx": 5, "faculty_idx": 2, "status": "APPROVED",
        "title": "Autonomous Marine Oil Spill Detection via Sentinel-1 SAR Satellite Imagery and Deep CNNs",
        "domain": "Remote Sensing & Environmental AI",
        "tech_stack": ["PyTorch", "GDAL", "FastAPI", "React", "Sentinel API", "PostGIS"],
        "keywords": ["Satellite Imagery", "Oil Spill Detection", "SAR Radar", "Semantic Segmentation", "Ocean Protection"],
        "abstract": "Processes European Space Agency Sentinel-1 Synthetic Aperture Radar (SAR) imagery to detect ocean oil slicks, differentiating genuine hydrocarbon spills from lookalike biogenic slicks.",
        "academic_year": "2024-2025", "semester": 6, "type": "CAPSTONE", "repo": "https://github.com/mca-research/satellite-oil-spill-sar"
    },
    {
        "student_idx": 5, "faculty_idx": 2, "status": "APPROVED",
        "title": "Real-Time Structural Health Monitoring for Bridges via IoT Vibration Mesh & Edge AI",
        "domain": "Civil Informatics & Internet of Things (IoT)",
        "tech_stack": ["ESP32", "MQTT", "FastAPI", "InfluxDB", "React", "Grafana"],
        "keywords": ["Structural Health", "Vibration Analysis", "Bridge Monitoring", "IoT Mesh", "Edge Computing"],
        "abstract": "Deploys tri-axial MEMS accelerometers along suspension bridge pylons to compute modal frequency shifts, alerting structural engineers to micro-fissure resonance decay before catastrophic failure.",
        "academic_year": "2025-2026", "semester": 6, "type": "CAPSTONE", "repo": "https://github.com/mca-research/bridge-vibration-iot"
    },
    {
        "student_idx": 5, "faculty_idx": 2, "status": "APPROVED",
        "title": "Federated Learning for Cross-Hospital Brain Tumor MRI Segmentation (BraTS)",
        "domain": "Healthcare AI & Distributed Machine Learning",
        "tech_stack": ["PySyft", "PyTorch", "FastAPI", "React", "MONAI", "Docker"],
        "keywords": ["Federated Learning", "Brain Tumor", "BraTS Benchmark", "MRI Segmentation", "Data Privacy"],
        "abstract": "Collaborative training of 3D nnU-Net models across multi-institutional hospital MRI cohorts without sharing sensitive neuroimaging files, achieving near-centralized segmentation accuracy (Dice 0.912).",
        "academic_year": "2025-2026", "semester": 6, "type": "CAPSTONE", "repo": "https://github.com/mca-research/federated-brain-tumor-mri"
    },
    {
        "student_idx": 5, "faculty_idx": 2, "status": "APPROVED",
        "title": "Decentralized Identity Verification and Verifiable Credentials for Cross-University Mobility",
        "domain": "Blockchain & Self-Sovereign Identity",
        "tech_stack": ["DID Standards", "Solidity", "React", "Node.js", "IPFS"],
        "keywords": ["Self-Sovereign Identity", "Verifiable Credentials", "W3C DID", "Student Mobility"],
        "abstract": "Implements W3C compliant Decentralized Identifiers (DIDs) allowing transfer students to carry cryptographically verifiable academic transcripts across international partner universities seamlessly.",
        "academic_year": "2024-2025", "semester": 5, "type": "Major Project", "repo": "https://github.com/mca-research/did-university-credentials"
    },
    {
        "student_idx": 5, "faculty_idx": 2, "status": "APPROVED",
        "title": "Automated Real-Time Phishing Website Detection via URL Lexical Analysis & Visual Layout Matching",
        "domain": "Cybersecurity & Web Safety",
        "tech_stack": ["Python", "Playwright", "FastAPI", "Scikit-Learn", "React"],
        "keywords": ["Phishing Detection", "Lexical Analysis", "Visual Matching", "Cybersecurity", "DOM Analysis"],
        "abstract": "A browser protection proxy evaluating suspicious domain age, SSL issuer telemetry, and visual favicon/DOM rendering similarity to detect brand-impersonation phishing portals in sub-200ms.",
        "academic_year": "2024-2025", "semester": 4, "type": "Mini Project", "repo": "https://github.com/mca-research/anti-phishing-visual-shield"
    },
    {
        "student_idx": 5, "faculty_idx": 2, "status": "APPROVED",
        "title": "Automated Plant Leaf Disease Severity Quantification via Mobile Edge Deep Vision",
        "domain": "Computer Vision & Agriculture",
        "tech_stack": ["PyTorch", "TensorFlow Lite", "FastAPI", "React", "OpenCV"],
        "keywords": ["Plant Pathology", "Leaf Disease", "Severity Index", "MobileNet", "Edge Vision"],
        "abstract": "A mobile diagnostic app segmenting necrotic leaf lesion surface percentages on tomato and cassava crops, calculating precise chemical fungicide dosage recommendations directly on edge smartphones.",
        "academic_year": "2025-2026", "semester": 6, "type": "CAPSTONE", "repo": "https://github.com/mca-research/leaf-disease-severity-ai"
    },
    {
        "student_idx": 5, "faculty_idx": 2, "status": "APPROVED",
        "title": "High-Throughput Log Anomaly Detection for Distributed Kubernetes Clusters",
        "domain": "Cloud Infrastructure & AIOps",
        "tech_stack": ["Go", "Python", "Kafka", "Elasticsearch", "FastAPI", "PyTorch"],
        "keywords": ["Log Anomaly Detection", "Kubernetes", "AIOps", "Drain Log Parser", "Transformer"],
        "abstract": "Parses millions of unstructured microservice container log lines into structured semantic template vectors using Drain parsing and transformer sequence models to flag cluster pod failure conditions.",
        "academic_year": "2024-2025", "semester": 5, "type": "Major Project", "repo": "https://github.com/mca-research/k8s-log-anomaly-aiops"
    },
    {
        "student_idx": 5, "faculty_idx": 2, "status": "SUBMITTED",
        "title": "Automated Smart Waste Bin Monitoring and Fleet Route Optimization via Ultrasonic Mesh",
        "domain": "Smart Cities & IoT",
        "tech_stack": ["ESP32", "LoRaWAN", "FastAPI", "React", "PostGIS"],
        "keywords": ["Smart Waste", "LoRaWAN", "Routing Algorithm", "Ultrasonic Sensing", "Municipal GIS"],
        "abstract": "Monitors fill levels across 200 municipal garbage receptacles and recalculates optimal dynamic collection truck itineraries daily, reducing municipal diesel expenditures by 31%.",
        "academic_year": "2025-2026", "semester": 6, "type": "CAPSTONE", "repo": "https://github.com/mca-research/smart-waste-route-optimizer"
    },
    {
        "student_idx": 5, "faculty_idx": 2, "status": "APPROVED",
        "title": "Quantum Random Number Generator Integration for Cryptographic Key Seeding",
        "domain": "Hardware Security & Quantum Computing",
        "tech_stack": ["Python", "FastAPI", "React", "PostgreSQL", "OpenSSL"],
        "keywords": ["QRNG", "Entropy Seeding", "Hardware Security", "Quantum Optics", "NIST SP 800-22"],
        "abstract": "Interfaces optical beam-splitter single-photon quantum entropy sources with enterprise cryptographic keystores, achieving maximum NIST SP 800-22 statistical test suite randomness certification.",
        "academic_year": "2025-2026", "semester": 6, "type": "CAPSTONE", "repo": "https://github.com/mca-research/qrng-entropy-keystore"
    }
]

def generate_pdf_document(file_path, project_title, doc_type, project_data, student_name, faculty_name):
    os.makedirs(os.path.dirname(file_path), exist_ok=True)
    doc = SimpleDocTemplate(file_path, pagesize=letter, rightMargin=45, leftMargin=45, topMargin=45, bottomMargin=45)
    styles = getSampleStyleSheet()

    # Custom styles
    title_style = ParagraphStyle(
        'DocTitle',
        parent=styles['Heading1'],
        fontName='Helvetica-Bold',
        fontSize=18,
        leading=22,
        textColor=colors.HexColor('#1E1B4B'),
        spaceAfter=12
    )
    subtitle_style = ParagraphStyle(
        'DocSubtitle',
        parent=styles['Normal'],
        fontName='Helvetica-Bold',
        fontSize=11,
        leading=14,
        textColor=colors.HexColor('#4338CA'),
        spaceAfter=16
    )
    heading_style = ParagraphStyle(
        'SectionHeading',
        parent=styles['Heading2'],
        fontName='Helvetica-Bold',
        fontSize=13,
        leading=16,
        textColor=colors.HexColor('#1E293B'),
        spaceBefore=14,
        spaceAfter=6
    )
    body_style = ParagraphStyle(
        'BodyDark',
        parent=styles['Normal'],
        fontName='Helvetica',
        fontSize=9.5,
        leading=13.5,
        textColor=colors.HexColor('#334155'),
        spaceAfter=8
    )

    story = []

    # Header Card
    story.append(Paragraph(f"PROJECTVAULT ACADEMIC REPOSITORY — DEPARTMENT OF COMPUTER APPLICATIONS (MCA)", subtitle_style))
    story.append(Paragraph(project_title, title_style))
    story.append(Spacer(1, 4))

    # Metadata Table
    meta_data = [
        [Paragraph("<b>Author / Student:</b>", body_style), Paragraph(student_name, body_style),
         Paragraph("<b>Academic Year:</b>", body_style), Paragraph(project_data.get('academic_year', '2025-2026'), body_style)],
        [Paragraph("<b>Faculty Guide:</b>", body_style), Paragraph(faculty_name, body_style),
         Paragraph("<b>Semester / Type:</b>", body_style), Paragraph(f"Sem {project_data.get('semester', 6)} • {project_data.get('type', 'CAPSTONE')}", body_style)],
        [Paragraph("<b>Domain:</b>", body_style), Paragraph(project_data.get('domain', 'Computer Science'), body_style),
         Paragraph("<b>Document Type:</b>", body_style), Paragraph(doc_type, body_style)]
    ]
    t = Table(meta_data, colWidths=[100, 160, 100, 160])
    t.setStyle(TableStyle([
        ('BACKGROUND', (0,0), (-1,-1), colors.HexColor('#F8FAFC')),
        ('BOX', (0,0), (-1,-1), 1, colors.HexColor('#E2E8F0')),
        ('INNERGRID', (0,0), (-1,-1), 0.5, colors.HexColor('#E2E8F0')),
        ('TOPPADDING', (0,0), (-1,-1), 5),
        ('BOTTOMPADDING', (0,0), (-1,-1), 5),
    ]))
    story.append(t)
    story.append(Spacer(1, 14))

    if doc_type == "Software Requirements Specification (SRS)":
        story.append(Paragraph("1. Executive Summary & Problem Formulation", heading_style))
        story.append(Paragraph(f"This project addresses critical challenges in {project_data.get('domain')}. {project_data.get('abstract')}", body_style))
        story.append(Paragraph("Traditional approaches suffer from latency bottlenecks, lack of end-to-end automation, and scaling constraints under high-concurrency production workloads. This system delivers an integrated architecture designed for robustness, auditability, and measurable performance improvements.", body_style))

        story.append(Paragraph("2. Functional Requirements", heading_style))
        story.append(Paragraph("<b>FR-1 Data Ingestion & Validation:</b> The platform ingests telemetry and raw input streams through authenticated REST and gRPC endpoints, applying strict JSON schema validation and zero-loss buffer buffering.", body_style))
        story.append(Paragraph("<b>FR-2 Algorithmic Core Processing:</b> Implements optimized computational pipelines leveraging " + ", ".join(project_data.get('tech_stack', [])) + " for low-latency batch and real-time event inference.", body_style))
        story.append(Paragraph("<b>FR-3 Administrative Dashboard & State Management:</b> Provides role-based access control (RBAC) interfaces for students, faculty guides, and university administrators with persistent workflow audit trails.", body_style))

        story.append(Paragraph("3. Non-Functional Requirements & Security Standards", heading_style))
        story.append(Paragraph("• <b>Latency:</b> P99 response time below 250ms under peak 500 requests/sec synthetic workload tests.<br/>• <b>Reliability:</b> Automated failover with 99.9% uptime SLA and PostgreSQL WAL replication.<br/>• <b>Security:</b> TLS 1.3 encryption in transit, AES-256 at rest, and JWT role-based claims verification.", body_style))

        story.append(Paragraph("4. Technical Stack & Architecture", heading_style))
        story.append(Paragraph("The software architecture combines modern frameworks: " + ", ".join(project_data.get('tech_stack', [])) + " with containerized Docker deployment and PostgreSQL persistence.", body_style))

    else: # Project Synopsis
        story.append(Paragraph("1. Project Abstract & Objectives", heading_style))
        story.append(Paragraph(project_data.get('abstract'), body_style))

        story.append(Paragraph("2. Proposed Methodology & Algorithmic Design", heading_style))
        story.append(Paragraph("The proposed system is structured into four sequential phases: (1) Data preprocessing and feature extraction, (2) Model training and baseline benchmarking, (3) System integration with RESTful microservice layers, and (4) Comprehensive end-to-end verification.", body_style))

        story.append(Paragraph("3. Key Technologies & Implementations", heading_style))
        story.append(Paragraph("Implemented using: " + ", ".join(project_data.get('tech_stack', [])) + ". Repository source code is maintained at: " + project_data.get('repo', 'https://github.com/projectvault/project'), body_style))

        story.append(Paragraph("4. Experimental Results & Verification", heading_style))
        story.append(Paragraph("Empirical evaluation demonstrated statistically significant improvements over baseline models, achieving superior accuracy, reduced execution overhead, and successful verification under university guidelines.", body_style))

    doc.build(story)
    return os.path.getsize(file_path)

def seed_database():
    print("=" * 60)
    print("SEEDING 60 AUTHENTIC MCA CAPSTONE PROJECTS")
    print("=" * 60)

    conn = psycopg2.connect(DB_URL)
    conn.autocommit = True
    cur = conn.cursor()

    # 1. Clean old project data
    print("\n[1] Truncating old project tables and cleaning storage...")
    cur.execute("""
        TRUNCATE TABLE project_files, project_keywords, project_members, project_workflow_history, ai_analyses, project_embeddings, projects RESTART IDENTITY CASCADE;
    """)

    if os.path.exists(STORAGE_ROOT):
        shutil.rmtree(STORAGE_ROOT)
    os.makedirs(STORAGE_ROOT, exist_ok=True)
    print(">>> Tables truncated and storage directory reset.")

    # 2. Insert 60 Projects
    print("\n[2] Inserting 60 projects with workflow history and PDF attachments...")

    now = datetime.datetime.now()

    for idx, p in enumerate(PROJECTS_DATA, start=1):
        student = STUDENTS[p["student_idx"]]
        faculty = FACULTIES[p["faculty_idx"]]
        status = p["status"]
        visibility = "PUBLIC" if status == "APPROVED" else "DEPARTMENT_ONLY"

        # Plagiarism / Duplication scores (only populated for evaluation)
        if status in ["SUBMITTED", "UNDER_REVIEW"]:
            plag_score = round(random.uniform(2.5, 14.8), 1)
            dup_score = round(random.uniform(5.0, 22.5), 1)
        elif status == "REJECTED":
            plag_score = round(random.uniform(62.0, 88.5), 1)
            dup_score = round(random.uniform(75.0, 94.0), 1)
        else:
            plag_score = round(random.uniform(1.0, 9.5), 1)
            dup_score = round(random.uniform(3.0, 18.0), 1)

        # Insert project
        cur.execute("""
            INSERT INTO projects (
                title, abstract, academic_year, semester, project_type,
                status, visibility, department_id, created_by_user_id,
                guide_faculty_id, repository_url, plagiarism_score, duplication_score,
                plagiarism_status, created_at, updated_at
            ) VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s)
            RETURNING id;
        """, (
            p["title"], p["abstract"], p["academic_year"], p["semester"], p["type"],
            status, visibility, 1, student["id"],
            faculty["id"], p["repo"], plag_score, dup_score,
            "COMPLETED", now - datetime.timedelta(days=random.randint(15, 60)), now
        ))
        project_id = cur.fetchone()[0]

        # Insert project member
        cur.execute("""
            INSERT INTO project_members (project_id, user_id, member_role, created_at)
            VALUES (%s, %s, %s, %s);
        """, (project_id, student["id"], "Project Lead & Developer", now))

        # Insert workflow history
        # 1. Submission
        cur.execute("""
            INSERT INTO project_workflow_history (project_id, from_status, to_status, changed_by_user_id, remarks, created_at)
            VALUES (%s, %s, %s, %s, %s, %s);
        """, (project_id, "DRAFT", "SUBMITTED", student["id"], "Project proposal and SRS documents submitted for faculty review.", now - datetime.timedelta(days=20)))

        # 2. Review / Approval
        if status in ["UNDER_REVIEW", "APPROVED", "REJECTED"]:
            cur.execute("""
                INSERT INTO project_workflow_history (project_id, from_status, to_status, changed_by_user_id, remarks, created_at)
                VALUES (%s, %s, %s, %s, %s, %s);
            """, (project_id, "SUBMITTED", "UNDER_REVIEW", faculty["id"], "Originality assessment completed. Under faculty evaluation.", now - datetime.timedelta(days=12)))

        if status == "APPROVED":
            cur.execute("""
                INSERT INTO project_workflow_history (project_id, from_status, to_status, changed_by_user_id, remarks, created_at)
                VALUES (%s, %s, %s, %s, %s, %s);
            """, (project_id, "UNDER_REVIEW", "APPROVED", faculty["id"], "Project verified, originality checked, and approved for official publication.", now - datetime.timedelta(days=5)))
        elif status == "REJECTED":
            cur.execute("""
                INSERT INTO project_workflow_history (project_id, from_status, to_status, changed_by_user_id, remarks, created_at)
                VALUES (%s, %s, %s, %s, %s, %s);
            """, (project_id, "UNDER_REVIEW", "REJECTED", faculty["id"], "Submission lacks sufficient technical depth and exhibits high overlap with existing coursework.", now - datetime.timedelta(days=3)))

        # Generate 2 authentic PDF files
        proj_dir = os.path.join(STORAGE_ROOT, str(project_id))
        srs_filename = f"{p['title'][:30].strip().replace(' ', '_')}_SRS.pdf"
        srs_path = os.path.join(proj_dir, srs_filename)
        srs_size = generate_pdf_document(srs_path, p["title"], "Software Requirements Specification (SRS)", p, student["name"], faculty["name"])

        syn_filename = f"{p['title'][:30].strip().replace(' ', '_')}_Synopsis.pdf"
        syn_path = os.path.join(proj_dir, syn_filename)
        syn_size = generate_pdf_document(syn_path, p["title"], "Project Synopsis Report", p, student["name"], faculty["name"])

        # Insert project_files
        cur.execute("""
            INSERT INTO project_files (
                project_id, file_name, file_type, file_size,
                storage_path, storage_type, file_path, uploaded_by_user_id,
                created_at, uploaded_at
            ) VALUES (%s, %s, %s, %s, %s, 'LOCAL', %s, %s, %s, %s);
        """, (
            project_id, srs_filename, "application/pdf", srs_size,
            srs_path, srs_path, student["id"], now, now
        ))

        cur.execute("""
            INSERT INTO project_files (
                project_id, file_name, file_type, file_size,
                storage_path, storage_type, file_path, uploaded_by_user_id,
                created_at, uploaded_at
            ) VALUES (%s, %s, %s, %s, %s, 'LOCAL', %s, %s, %s, %s);
        """, (
            project_id, syn_filename, "application/pdf", syn_size,
            syn_path, syn_path, student["id"], now, now
        ))

        # Insert AI Analysis
        cur.execute("""
            INSERT INTO ai_analyses (
                project_id, summary, domain, extracted_keywords, tech_stack,
                problem_statement, ai_status, created_at
            ) VALUES (%s, %s, %s, %s, %s, %s, %s, %s);
        """, (
            project_id, p["abstract"][:300], p["domain"],
            p["keywords"], p["tech_stack"],
            f"Addressing challenges in {p['domain']} through {p['title']}.",
            "COMPLETED", now
        ))

        if idx % 10 == 0:
            print(f"  - Seeded {idx}/60 projects with documents and workflow...")

    print(">>> All 60 projects seeded successfully.")

    # 3. Compute Embeddings via SentenceTransformer or VectorService
    print("\n[3] Generating 384-dimensional vector embeddings for all 60 projects...")
    cur.execute("SELECT COUNT(*) FROM projects;")
    proj_cnt = cur.fetchone()[0]
    print(f">>> Found {proj_cnt} projects in database.")

    if embedding_service:
        cur.execute("SELECT id, title, abstract FROM projects ORDER BY id ASC;")
        all_projs = cur.fetchall()
        for pid, title, abstract in all_projs:
            text_to_embed = f"{title}. {abstract}"
            vec = embedding_service.generate_embedding(text_to_embed)
            
            # Format vector as PostgreSQL literal
            vec_str = "[" + ",".join(f"{x:.6f}" for x in vec) + "]"
            
            try:
                cur.execute("""
                    INSERT INTO project_embeddings (project_id, embedding_vector, model_version, updated_at)
                    VALUES (%s, %s::vector, 'sentence-transformers/all-MiniLM-L6-v2', CURRENT_TIMESTAMP)
                    ON CONFLICT (project_id) DO UPDATE SET embedding_vector = EXCLUDED.embedding_vector, updated_at = CURRENT_TIMESTAMP;
                """, (pid, vec_str))
            except Exception:
                cur.execute("""
                    INSERT INTO project_embeddings (project_id, embedding_vector, model_version, updated_at)
                    VALUES (%s, %s, 'sentence-transformers/all-MiniLM-L6-v2', CURRENT_TIMESTAMP)
                    ON CONFLICT (project_id) DO UPDATE SET embedding_vector = EXCLUDED.embedding_vector, updated_at = CURRENT_TIMESTAMP;
                """, (pid, vec))

        print(f">>> Generated and saved embeddings for {len(all_projs)} projects.")
    else:
        print(">>> SentenceTransformer not loaded directly. Syncing via AI microservice endpoint...")
        import urllib.request
        try:
            req = urllib.request.Request("http://localhost:8000/api/v1/ai/sync-embeddings", data=b'{"force_refresh": true}', headers={"Content-Type": "application/json"})
            with urllib.request.urlopen(req) as resp:
                print(">>> AI microservice sync:", resp.read().decode())
        except Exception as e:
            print(">>> Microservice sync note:", e)

    cur.close()
    conn.close()
    print("\n" + "=" * 60)
    print("SEEDING COMPLETE: 60 PROJECTS READY ACROSS 6 STUDENTS & 3 FACULTIES")
    print("=" * 60)

if __name__ == "__main__":
    seed_database()
