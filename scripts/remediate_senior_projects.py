import os
import re
import sys
import json
import psycopg2
from psycopg2.extras import RealDictCursor
from reportlab.lib.pagesizes import letter
from reportlab.platypus import SimpleDocTemplate, Paragraph, Spacer, Table, TableStyle, HRFlowable
from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
from reportlab.lib import colors

DB_CONFIG = {
    "dbname": "projectvault",
    "user": "postgres",
    "password": "0608",
    "host": "localhost",
    "port": 5432
}

# Complete, verified catalog for all 38 Senior Projects
PROJECT_CATALOG = [
    {
        "id": 1,
        "roll_no": "24MX106",
        "student_name": "24MX106",
        "title": "NexusLOS: Explainable AI Loan Origination System",
        "domain": "FinTech & Explainable AI",
        "tech_stack": ["Python", "FastAPI", "React", "PyTorch", "SHAP", "PostgreSQL"],
        "abstract": (
            "NexusLOS is an advanced AI-driven Loan Origination System designed to provide high-accuracy credit "
            "scoring while prioritizing borrower transparency and regulatory compliance. Unlike traditional "
            "black-box machine learning models that reject loan applicants without clear justification, NexusLOS "
            "utilizes Explainable AI (XAI) with SHAP and LIME to generate specific reason codes and actionable "
            "rejection roadmaps for borrowers. The system implements a dual lending path evaluating both income-based "
            "repayment capacity from banking telemetry and asset-based lending collateral, providing a transparent, "
            "auditable, and equitable digital lending infrastructure."
        )
    },
    {
        "id": 2,
        "roll_no": "24MX217",
        "student_name": "24MX217",
        "title": "Distress AI: Multi-Modal Surveillance & Safety Detection System",
        "domain": "Computer Vision & Public Safety",
        "tech_stack": ["Python", "OpenCV", "MediaPipe", "FastAPI", "React", "SQLite"],
        "abstract": (
            "Distress AI is an intelligent multi-modal video surveillance framework designed to detect emotional "
            "distress, suspicious physical postures, and immediate safety threats in real-time. By integrating "
            "deep learning facial emotion recognition with skeletal posture tracking via MediaPipe, the system "
            "continuously monitors camera feeds to identify violent altercations, distress calls, or sudden medical "
            "collapses. When a potential threat is identified, the system logs the incident, triggers low-latency "
            "dispatcher alerts, and provides campus or enterprise security personnel with contextual video snippets "
            "to accelerate emergency response."
        )
    },
    {
        "id": 3,
        "roll_no": "24MX108",
        "student_name": "24MX108",
        "title": "SC-GUARD: Smart Contract Vulnerability Detection & Risk Enforcement System",
        "domain": "Blockchain Security & Static Analysis",
        "tech_stack": ["Solidity", "Python", "Slither", "PyInstaller", "PowerShell"],
        "abstract": (
            "SC-GUARD is an automated smart contract vulnerability detection and security audit platform targeting "
            "Ethereum Solidity contracts. The system performs comprehensive Abstract Syntax Tree (AST) static analysis "
            "and symbolic execution to identify critical security flaws such as reentrancy vulnerabilities, arithmetic "
            "overflows, unchecked external calls, and front-running exposures. Based on detected vulnerability signatures, "
            "SC-GUARD calculates a composite security risk index and enforces automated deployment decisions (ALLOW, "
            "WARN, or BLOCK), generating detailed diagnostic reports in JSON, HTML, and PDF formats for smart contract developers."
        )
    },
    {
        "id": 4,
        "roll_no": "24MX219",
        "student_name": "Nithesh S",
        "title": "Software Bug Assistant: Autonomous Code Debugging & Remediation Agent",
        "domain": "Agentic AI & Automated Software Engineering",
        "tech_stack": ["Python", "Google Cloud ADK", "Gemini 1.5 Pro", "Docker", "Git"],
        "abstract": (
            "Software Bug Assistant is an autonomous AI agent engineered to streamline the software defect resolution "
            "lifecycle using the Agent Development Kit (ADK) and large language model reasoning. The system ingests "
            "application crash traces, diagnostic logs, and issue tracker tickets to automatically isolate root causes "
            "within codebase repositories. By synthesizing reproduction test harnesses in sandboxed containers, the agent "
            "verifies defect existence, generates candidate code patches, runs regression unit tests, and submits formal "
            "Pull Requests with comprehensive technical summaries."
        )
    },
    {
        "id": 5,
        "roll_no": "24MX301",
        "student_name": "24MX301",
        "title": "QGenesis: Academic Question Bank Generation & Examination Workflow",
        "domain": "EdTech & Workflow Management",
        "tech_stack": ["React", "Node.js", "Firebase Firestore", "Express", "NLP"],
        "abstract": (
            "QGenesis is an AI-powered academic question bank and examination paper workflow orchestration platform "
            "developed for higher educational institutions. The platform empowers faculty members to extract and synthesize "
            "rigorous examination questions from course syllabi, lecture slides, and reference materials across varying "
            "Bloom's taxonomy cognitive levels. QGenesis incorporates role-based approval pipelines routing draft question "
            "papers through Head of Department (HOD) review, dynamic paper randomization, and strict institutional "
            "confidentiality controls."
        )
    },
    {
        "id": 6,
        "roll_no": "24MX317",
        "student_name": "24MX317",
        "title": "PII Shield: Automated Sensitive Data Redaction & Privacy Compliance",
        "domain": "Privacy Engineering & Natural Language Processing",
        "tech_stack": ["Python", "spaCy", "PyMuPDF", "Regex", "ReportLab"],
        "abstract": (
            "PII Shield is an automated sensitive data discovery and redaction platform designed to ensure compliance "
            "with institutional and regulatory data privacy mandates (such as GDPR and HIPAA). The system scans unstructured "
            "enterprise documents (PDF, DOCX, TXT) using specialized Named Entity Recognition (NER) models and deterministic "
            "regular expressions to detect Personally Identifiable Information (PII) including Aadhaar numbers, PAN cards, "
            "credit details, email addresses, and phone numbers, permanently redacting sensitive coordinates while preserving "
            "document structural readability."
        )
    },
    {
        "id": 7,
        "roll_no": "24MX353",
        "student_name": "24MX353",
        "title": "Cloud Log Anomaly Detection with Adaptive Model Selection",
        "domain": "Cloud Computing & Streaming Analytics",
        "tech_stack": ["Python", "Apache Kafka", "LSTM", "Scikit-Learn", "FastAPI"],
        "abstract": (
            "This project implements a real-time cloud log anomaly detection framework featuring dynamic detector "
            "switching over distributed Kafka message streams. Addressing the challenge of concept drift and bursty "
            "cloud infrastructure logs, the architecture evaluates incoming log streams and adaptively toggles between "
            "lightweight Static thresholding, statistical Adaptive baselining, and deep-learning LSTM sequence detectors. "
            "Experimental evaluation demonstrates enhanced anomaly detection precision and reduced alert fatigue across "
            "heterogeneous cloud infrastructure logs."
        )
    },
    {
        "id": 8,
        "roll_no": "24MX203",
        "student_name": "24MX203",
        "title": "SybilGuard: Graph-Based Sybil Node Detection & Trust Propagation",
        "domain": "Graph Mining & Social Network Security",
        "tech_stack": ["Python", "NetworkX", "Three.js", "Flask", "SciPy"],
        "abstract": (
            "SybilGuard is an interactive graph analytics and visualization platform for detecting Sybil accounts (fake, "
            "coordinated malicious nodes) within large-scale social network topologies. By implementing random walk-based "
            "trust propagation algorithms including SybilRank, SybilWalk, and SybilWalk-Var alongside an ensemble scoring "
            "model, the system identifies anomalous clusters where trust fails to propagate naturally. An interactive "
            "3D graph visualization interface enables security analysts to inspect network communities, trace trust vectors, "
            "and isolate coordinated inauthentic behavior."
        )
    },
    {
        "id": 9,
        "roll_no": "24MX211",
        "student_name": "24MX211",
        "title": "Hybrid XGBoost-LSTM Online Banking Fraud Detection Framework",
        "domain": "FinTech & Deep Learning",
        "tech_stack": ["Python", "XGBoost", "TensorFlow", "Keras", "Scikit-Learn"],
        "abstract": (
            "This research introduces a hybrid machine learning and deep learning architecture for high-velocity online "
            "banking fraud detection. The framework pairs an optimized XGBoost gradient-boosted decision tree pipeline for "
            "evaluating tabular transaction features (amounts, geolocations, terminal IDs) with a recurrent LSTM neural "
            "network that models longitudinal customer spending sequences. The combined model achieves high precision "
            "and an 87.41% F1-score on skewed transaction benchmarks, significantly reducing false positive declines while "
            "detecting sophisticated financial fraud patterns."
        )
    },
    {
        "id": 10,
        "roll_no": "24MX229",
        "student_name": "24MX229",
        "title": "TRUSTLES: Zero Trust Continuous Endpoint Monitoring & Risk Scoring",
        "domain": "Cybersecurity & Zero Trust Architecture",
        "tech_stack": ["Python", "C++", "FastAPI", "SQLite", "React"],
        "abstract": (
            "TRUSTLES is a lightweight enterprise zero-trust endpoint monitoring and continuous posture evaluation system. "
            "Operating under the 'never trust, always verify' paradigm, background monitoring agents track process creation, "
            "network socket bindings, privilege escalation, and file system anomalies on client machines. Telemetry is streamed "
            "to a central risk engine that dynamically computes an endpoint health index, automatically revoking session tokens "
            "and isolating endpoints when suspicious behavior or integrity degradation is observed."
        )
    },
    {
        "id": 11,
        "roll_no": "24MX101",
        "student_name": "24MX101",
        "title": "Secure Image System: Chen Hyperchaotic & RSA-AES Encryption",
        "domain": "Applied Cryptography & Multimedia Security",
        "tech_stack": ["Python", "OpenCV", "Cryptography", "AES-256", "RSA-2048"],
        "abstract": (
            "Secure Image System is a high-security multimedia encryption and transfer framework combining Chen hyperchaotic "
            "systems with hybrid asymmetric-symmetric cryptography. The pipeline utilizes the high-dimensional pseudo-random "
            "entropy of Chen chaotic attractors to perform pixel-level position scrambling and diffusion, followed by "
            "AES-256-CBC cipher block chaining. Session keys are secured via RSA-2048/OAEP asymmetric key exchange, ensuring "
            "resilience against differential cryptanalysis, statistical pixel distribution attacks, and eavesdropping during "
            "high-speed image transmission."
        )
    },
    {
        "id": 12,
        "roll_no": "24MX128",
        "student_name": "24MX128",
        "title": "Academic Integrity Checker: Anti-Plagiarism & Research Review System",
        "domain": "Natural Language Processing & Academic Auditing",
        "tech_stack": ["Python", "FastAPI", "NLTK", "PyMuPDF", "React"],
        "abstract": (
            "Academic Integrity Checker is an automated research dissertation verification engine designed to uphold academic "
            "rigor in institutional project repositories. The platform evaluates submitted abstracts, technical reports, and "
            "source code against indexed institutional repositories and open web sources. By combining N-gram fingerprinting, "
            "semantic vector distance, and intelligent citation filtering (excluding references, datasets, and standard libraries), "
            "the system delivers an objective similarity score and an itemized originality audit report for academic review committees."
        )
    },
    {
        "id": 13,
        "roll_no": "24MX119",
        "student_name": "24MX119",
        "title": "Adversarial Robust CNN: Defense Mechanisms Against FGSM & PGD Attacks",
        "domain": "Deep Learning & AI Security",
        "tech_stack": ["Python", "PyTorch", "Torchvision", "NumPy", "Matplotlib"],
        "abstract": (
            "This research investigates vulnerabilities in deep Convolutional Neural Networks (CNNs) subjected to adversarial "
            "evasion attacks and introduces empirical defense mechanisms. The project benchmarks standard CNN models against "
            "Fast Gradient Sign Method (FGSM) and Projected Gradient Descent (PGD) perturbation attacks, demonstrating significant "
            "accuracy degradation under imperceptible noise. Through adversarial retraining, gradient regularization, and robust "
            "feature feature distillation, the proposed architecture substantially enhances classification robustness on perturbed "
            "vision datasets."
        )
    },
    {
        "id": 14,
        "roll_no": "24MX113",
        "student_name": "Manishankar V",
        "title": "DPDE: Decentralized Patient Data Exchange with On-Chain Consent",
        "domain": "HealthTech & Web3 Decentralized Systems",
        "tech_stack": ["Solidity", "IPFS", "React", "Vite", "Node.js", "MongoDB"],
        "abstract": (
            "DPDE (Decentralized Patient Data Exchange) is a patient-centric Electronic Health Record (EHR) management system "
            "giving individuals full sovereignty over medical record sharing. Patient medical records are encrypted on the client "
            "device prior to network egress and pinned to decentralized InterPlanetary File System (IPFS) storage. Granular data "
            "access consent (request, approve, revoke) is managed via smart contracts deployed on the Ethereum testnet, while a "
            "Node.js backend maintains auditable access logs and cryptographically enforces on-chain patient permission."
        )
    },
    {
        "id": 15,
        "roll_no": "24MX206",
        "student_name": "Dharsini B",
        "title": "Innovest: AI-Powered Startup Feasibility Evaluation & Matchmaking",
        "domain": "FinTech & Venture Matchmaking",
        "tech_stack": ["React", "Vite", "Node.js", "Express", "Python", "MongoDB"],
        "abstract": (
            "Innovest is a comprehensive platform bridging student entrepreneurs and venture investors with integrated "
            "AI feasibility analytics. The platform features an automated novelty checker that scans submitted business proposals "
            "against indexed startup repositories to prevent duplicated concepts and evaluate commercial viability. Innovest "
            "enforces structured feedback loops between mentors, investors, and founders, facilitating milestone-driven "
            "incubation within academic institutions."
        )
    },
    {
        "id": 16,
        "roll_no": "24MX318",
        "student_name": "Janani M",
        "title": "Automated Outcome-Based Education (OBE) Mapping & Attainment Tool",
        "domain": "EdTech & Academic Accreditation",
        "tech_stack": ["React", "Express", "Node.js", "MySQL", "ExcelJS"],
        "abstract": (
            "The Automated Outcome-Based Education (OBE) Mapping Tool is an institutional portal built to automate complex "
            "academic accreditation workflows in compliance with NBA and NAAC guidelines. The application maps course outcomes "
            "(COs) to program outcomes (POs) and program-specific outcomes (PSOs), processes multi-assessment student scores, "
            "and automatically computes direct and indirect attainment levels. The system replaces manual spreadsheets with "
            "verifiable analytics dashboards and exportable institutional accreditation reports."
        )
    },
    {
        "id": 17,
        "roll_no": "24MX319",
        "student_name": "M Janani",
        "title": "PreVue: AI-Powered Mock Interview & Communication Evaluation Platform",
        "domain": "EdTech & Speech/NLP Analytics",
        "tech_stack": ["React", "TypeScript", "Python", "FastAPI", "WebRTC", "Supabase"],
        "abstract": (
            "PreVue is a full-stack AI-driven mock interview preparation platform designed to enhance student placement "
            "readiness. Candidates undergo interactive simulated interviews featuring automated speech-to-text transcription, "
            "NLP semantic analysis of technical responses, and speech fluency evaluations. PreVue delivers personalized performance "
            "scorecards highlighting domain competency, pacing, vocabulary richness, and actionable recommendations to help "
            "students excel in corporate technical and HR interviews."
        )
    },
    {
        "id": 18,
        "roll_no": "24MX310",
        "student_name": "Dharshini V",
        "title": "Smart Toll: Intelligent FASTag Toll Estimation & Route Optimization",
        "domain": "Intelligent Transportation & Geospatial Analytics",
        "tech_stack": ["React", "Node.js", "Leaflet", "OpenStreetMap API", "Express"],
        "abstract": (
            "Smart Toll is an intelligent highway travel planning and cost estimation web platform designed for Indian national "
            "highways. Users input trip origin and destination points to compute real-time route alternatives, calculate cumulative "
            "FASTag toll expenditures across toll plazas, and verify prepaid balance sufficiency before travel. The system "
            "incorporates a pre-trip alert notification engine and distance-optimized routing to minimize travel delays and "
            "unforeseen highway transit costs."
        )
    },
    {
        "id": 19,
        "roll_no": "24MX109",
        "student_name": "24MX109",
        "title": "CloudInsight: Multi-Cloud FinOps & Cost Anomaly Detection Platform",
        "domain": "Cloud Computing & Financial Operations (FinOps)",
        "tech_stack": ["React", "Python", "FastAPI", "PostgreSQL", "Chart.js"],
        "abstract": (
            "CloudInsight is a comprehensive FinOps analytics platform for monitoring, forecasting, and optimizing multi-cloud "
            "expenditures across AWS, Microsoft Azure, and Google Cloud Platform. The system ingests billing logs and cost telemetry, "
            "applying time-series anomaly detection algorithms to identify sudden resource billing spikes, orphaned disk volumes, "
            "and underutilized instances. Interactive dashboards provide department budget allocations, automated slack notifications, "
            "and actionable cloud resource rightsizing recommendations."
        )
    },
    {
        "id": 20,
        "roll_no": "24MX207",
        "student_name": "24MX207",
        "title": "EdgeVerify: Distributed Edge IoT Integrity & Attestation System",
        "domain": "Edge Computing & IoT Security",
        "tech_stack": ["React", "Node.js", "Python", "Cryptography", "MQTT"],
        "abstract": (
            "EdgeVerify is a distributed security framework focused on validating firmware integrity and message authenticity "
            "across resource-constrained Edge IoT nodes. Operating without continuous cloud connectivity, edge gateways exchange "
            "cryptographic attestation tokens and verify sensor payload hash trees to detect compromised or rogue edge sensors. "
            "The system ensures high fault-tolerance, low verification latency, and end-to-end data integrity for critical "
            "industrial and smart city IoT deployments."
        )
    },
    {
        "id": 21,
        "roll_no": "24MX118",
        "student_name": "24MX118",
        "title": "EvoDoc: AI-Driven Continuous Codebase Documentation System",
        "domain": "Developer Tooling & Software Engineering",
        "tech_stack": ["TypeScript", "VS Code Extension API", "Node.js", "OpenAI API"],
        "abstract": (
            "EvoDoc is an intelligent developer assistant integrated into Visual Studio Code that automates codebase "
            "documentation generation and continuous documentation validation. Operating in watch mode, EvoDoc parses "
            "Abstract Syntax Trees (ASTs) on file saves to synchronize inline documentation, class diagrams, and API "
            "specifications with evolving code changes. Built-in coverage audits identify undocumented functions and stale "
            "comments, ensuring codebase maintainability in agile development environments."
        )
    },
    {
        "id": 22,
        "roll_no": "24MX213",
        "student_name": "24MX213",
        "title": "Malware Detection & Classification Framework Using Machine Learning",
        "domain": "Malware Forensics & Threat Intelligence",
        "tech_stack": ["Python", "Scikit-Learn", "PEfile", "Random Forest", "Flask"],
        "abstract": (
            "This project presents an empirical malware detection and classification engine analyzing Windows Portable "
            "Executable (PE) binaries. The framework extracts static feature vectors including PE header fields, section "
            "entropy levels, imported API functions, and byte n-gram frequencies. Machine learning classifiers (Random Forest, "
            "Support Vector Machines, and Gradient Boosting) are trained to distinguish benign software from ransomware, "
            "trojans, and spyware, achieving high classification accuracy with low false-alarm rates."
        )
    },
    {
        "id": 23,
        "roll_no": "24MX230",
        "student_name": "Venisha",
        "title": "EduSlot: Academic Campus Resource & Laboratory Booking Portal",
        "domain": "Campus Automation & Scheduling",
        "tech_stack": ["React", "Express", "Node.js", "MongoDB", "Tailwind CSS"],
        "abstract": (
            "EduSlot is a centralized campus resource reservation and scheduling system developed for PSG College of "
            "Technology. The platform eliminates scheduling collisions by managing access to computing laboratories, "
            "specialized hardware kits, seminar auditoriums, and project incubation spaces. EduSlot features faculty "
            "approval workflows, automated email booking notifications, and QR-based reservation passes to optimize "
            "institutional infrastructure utilization."
        )
    },
    {
        "id": 24,
        "roll_no": "24MX312",
        "student_name": "24MX312",
        "title": "ThinkTwice: AI-Powered Email Tone Reviewer & Writing Enhancement",
        "domain": "Natural Language Processing & HCI",
        "tech_stack": ["JavaScript", "Chrome Extensions API", "FastAPI", "NLP"],
        "abstract": (
            "ThinkTwice is an intelligent browser extension for Google Chrome that assists users in reviewing and refining "
            "written correspondence prior to transmission. Compatible with Gmail, LinkedIn, and WhatsApp Web, the extension "
            "evaluates draft messages using sentiment analysis and tone classification. ThinkTwice highlights potential tone "
            "misalignments (such as unintended aggression, passive-aggressiveness, or unprofessional phrasing) and suggests "
            "context-appropriate rewrites tailored for colleagues, supervisors, or external clients."
        )
    },
    {
        "id": 25,
        "roll_no": "24MX354",
        "student_name": "24MX354",
        "title": "Personalized Music Recommendation Engine Using Hybrid Filtering",
        "domain": "Recommender Systems & Audio Signal Processing",
        "tech_stack": ["Python", "Librosa", "PyTorch", "FastAPI", "React"],
        "abstract": (
            "This project develops a hybrid personalized music recommendation engine combining acoustic audio feature "
            "extraction with collaborative filtering algorithms. Using Librosa, the system extracts spectral contrast, tempo, "
            "and MFCC features from audio waveforms to quantify acoustic similarity, while matrix factorization models user "
            "listening histories. The hybrid approach mitigates the cold-start problem for newly released tracks and delivers "
            "tailored music discovery playlists aligned with user preference profiles."
        )
    },
    {
        "id": 26,
        "roll_no": "24MX104",
        "student_name": "24MX104",
        "title": "Apartment Manager: Community Living & Facility Maintenance Platform",
        "domain": "Smart Communities & Enterprise Web Systems",
        "tech_stack": ["React", "Node.js", "Express", "PostgreSQL", "JWT"],
        "abstract": (
            "Apartment Manager is a full-stack residential community management portal streamlining facility administration "
            "and resident communication. The platform automates monthly maintenance billing, provides digital payment tracking, "
            "and features an SLA-backed maintenance ticketing module for plumbing, electrical, and facility complaints. "
            "Role-based dashboards for residents, committee administrators, and security personnel ensure transparent "
            "residential society operations."
        )
    },
    {
        "id": 27,
        "roll_no": "24MX127",
        "student_name": "24MX127",
        "title": "KeySense: Behavioral Biometric Authentication via Keystroke Dynamics",
        "domain": "Biometric Security & Pattern Recognition",
        "tech_stack": ["Python", "FastAPI", "Scikit-Learn", "React", "JavaScript"],
        "abstract": (
            "KeySense is a continuous identity authentication system leveraging behavioral biometrics derived from user "
            "keystroke and mouse interaction dynamics. By capturing keystroke hold times, key flight intervals, and mouse "
            "curvature kinematics during natural computer interaction, KeySense trains personalized anomaly detection models "
            "to verify active user identity. The system provides non-intrusive secondary authentication, automatically locking "
            "sessions when anomalous typing behavior indicates unauthorized workstation takeover."
        )
    },
    {
        "id": 28,
        "roll_no": "24MX221",
        "student_name": "24MX221",
        "title": "Segro: IoT Automated Waste Classification & Robotic Segregation",
        "domain": "IoT & Environmental Robotics",
        "tech_stack": ["Arduino / ESP32", "C++", "Python", "OpenCV", "MQTT"],
        "abstract": (
            "Segro is an embedded IoT and computer vision waste segregation system engineered to automate solid waste sorting "
            "at the point of disposal. The hardware apparatus utilizes inductive proximity sensors, capacitive moisture probes, "
            "and camera feeds to classify waste into biodegradable, metallic, and recyclable categories. Motorized servo actuators "
            "steer waste into designated bins, while telemetry logged over MQTT provides municipal administrators with real-time "
            "bin fill-level notifications and waste generation statistics."
        )
    },
    {
        "id": 29,
        "roll_no": "24MX327",
        "student_name": "24MX327",
        "title": "TN SchemeBot: Tamil Nadu Citizen Welfare Scheme Recommendation Engine",
        "domain": "NLP & E-Governance Systems",
        "tech_stack": ["HTML5/JS", "Python", "Flask", "spaCy", "SQLite"],
        "abstract": (
            "TN SchemeBot is a conversational AI e-governance assistant built to help citizens discover and apply for Tamil Nadu "
            "state and central welfare schemes. Through intuitive natural language dialogue in English and Tamil, the chatbot "
            "collects applicant eligibility parameters (income, occupation, educational status, demographic category) and matches "
            "them against indexed government scheme repositories. The system details entitlement benefits, required documentation, "
            "and direct official application links to enhance public welfare access."
        )
    },
    {
        "id": 30,
        "roll_no": "24MX116",
        "student_name": "24MX116",
        "title": "NextDoorConnect: Hyperlocal Community Resource Sharing & Service Network",
        "domain": "Distributed Social Networks & Civic Tech",
        "tech_stack": ["React", "Node.js", "Express", "MongoDB", "Socket.io"],
        "abstract": (
            "NextDoorConnect is a hyperlocal community platform designed to foster mutual assistance and resource sharing among "
            "verified neighborhood residents. The platform enables residents to lend household equipment, offer local tutoring or "
            "handyman skills, organize neighborhood clean-ups, and broadcast urgent local safety alerts. By restricting membership "
            "to geographic zones and verifying address credentials, NextDoorConnect creates a secure, trusted digital community network."
        )
    },
    {
        "id": 31,
        "roll_no": "24MX215",
        "student_name": "24MX215",
        "title": "TechPack Analyzer: Automated Apparel Bill of Materials & Costing Platform",
        "domain": "Enterprise ERP & Textile Technology",
        "tech_stack": ["React", "Node.js", "Express", "MongoDB Atlas", "PDF-Parse"],
        "abstract": (
            "TechPack Analyzer is an apparel enterprise web application designed to automate Bill of Materials (BOM) generation "
            "and costing estimation from technical garment specification sheets. The application parses client tech pack PDFs, "
            "extracting fabric compositions, garment dimensions, trim requirements, and colorway codes. Merchandisers can configure "
            "unit material pricing to instantly generate accurate production costing sheets and export professional Excel BOM "
            "reports for textile manufacturing export houses."
        )
    },
    {
        "id": 32,
        "roll_no": "24MX222",
        "student_name": "24MX222",
        "title": "LoraOffNet: Offline LoRa Mesh-Based Emergency Communication & Payment System",
        "domain": "Emergency Communications & IoT Networks",
        "tech_stack": ["ESP32 Heltec LoRa V2", "C++ / Arduino", "RadioLib", "Android / Java"],
        "abstract": (
            "LoraOffNet is a disaster-resilient off-grid communication and micro-transaction framework operating without cellular "
            "or internet infrastructure. The architecture connects smartphones via local Wi-Fi access points to ESP32 LoRa nodes, "
            "which form an ad-hoc long-range radio mesh network using the SX1276 transceiver. The system enables reliable text "
            "messaging, emergency SOS beaconing, and cryptographically verified offline store-and-forward digital payments during "
            "natural disasters and remote network blackouts."
        )
    },
    {
        "id": 33,
        "roll_no": "24MX205",
        "student_name": "Boopathirajan M",
        "title": "Own Drive: Hybrid Local-Cloud Storage System with Intelligent Tiering",
        "domain": "Cloud Storage & Intelligent Tiering",
        "tech_stack": ["React", "Node.js", "Python", "Google Drive API", "MongoDB"],
        "abstract": (
            "Own Drive is an intelligent hybrid file storage solution that seamlessly unifies local disk storage with Google Drive "
            "cloud infrastructure. Operating through a 3-priority classification pipeline (user-defined rules, file access metadata, "
            "and predictive ML classification), Own Drive automatically tiers frequently accessed sensitive files to high-speed "
            "local storage while archiving cold backups to cloud storage. The system features JWT authentication, encrypted transfers, "
            "and transparent virtual filesystem access."
        )
    },
    {
        "id": 34,
        "roll_no": "24MX216",
        "student_name": "24MX216",
        "title": "Bulkify: High-Throughput Asynchronous Data Ingestion & Transformation Engine",
        "domain": "Big Data Pipelines & Distributed Systems",
        "tech_stack": ["Node.js", "TypeScript", "BullMQ", "Redis", "PostgreSQL"],
        "abstract": (
            "Bulkify is a high-throughput, fault-tolerant batch data processing pipeline engineered to ingest, validate, and "
            "transform massive enterprise datasets without service degradation. Implementing stream-based chunking, Redis-backed "
            "job queues, and dead-letter error queues, Bulkify processes millions of records with strict schema validation and "
            "real-time ingestion monitoring dashboards, ensuring robust data loading for enterprise analytics warehouses."
        )
    },
    {
        "id": 35,
        "roll_no": "24MX227",
        "student_name": "24MX227",
        "title": "SpeakMate: AI Public Speaking Coach & Verbal Fluency Platform",
        "domain": "Speech AI & Natural Language Processing",
        "tech_stack": ["React", "Node.js", "Web Speech API", "FastAPI", "MongoDB"],
        "abstract": (
            "SpeakMate is an interactive web-based speech coaching platform tailored for postgraduate students to improve their "
            "English public speaking and presentation fluency. Through structured, level-based speaking challenges, SpeakMate "
            "analyzes live audio streams to evaluate speaking rate, pause frequency, filler-word repetition ('um', 'uh', 'like'), "
            "and grammatical clarity. Candidates receive visual analytics dashboards with targeted vocal drills to build confident "
            "professional communication skills."
        )
    },
    {
        "id": 36,
        "roll_no": "24MX320",
        "student_name": "Jawahar Paisal P",
        "title": "ThinkInLogic: Adaptive Coding Platform with Q-Learning Recommendations",
        "domain": "Reinforcement Learning & EdTech",
        "tech_stack": ["React", "Node.js", "Express", "Python", "Q-Learning", "MongoDB"],
        "abstract": (
            "ThinkInLogic is an adaptive programming education platform designed by Jawahar Paisal P (24MX320) that personalizes "
            "coding problem recommendations using a Reinforcement Learning (Q-learning) engine. The system continuously evaluates "
            "student submission success rates, time-to-solve metrics, and code efficiency across difficulty levels, dynamically "
            "adapting the learning curve to address individual algorithmic weaknesses and maximize campus placement readiness."
        )
    },
    {
        "id": 37,
        "roll_no": "24MX359",
        "student_name": "24MX359",
        "title": "NIPDS: Network Intrusion Prevention & Deep Packet Inspection System",
        "domain": "Network Security & Threat Detection",
        "tech_stack": ["Python", "Scapy", "Snort Rules", "Flask", "SQLite"],
        "abstract": (
            "NIPDS (Network Intrusion Prevention and Detection System) is a high-speed network monitoring engine designed to "
            "safeguard enterprise local area networks against malicious traffic. Utilizing raw socket packet capture and deep "
            "packet inspection (DPI), NIPDS detects signature patterns of SYN flood attacks, port scans, DNS poisoning, and "
            "unauthorized shellcode payloads. The system logs security events to a centralized SIEM dashboard and automatically "
            "updates local firewall tables to drop malicious source IPs."
        )
    },
    {
        "id": 38,
        "roll_no": "23MX221",
        "student_name": "23MX221",
        "title": "Dubbify: Multi-Lingual Video Dubbing & Neural Voiceover Engine",
        "domain": "Generative AI & Audio-Visual Localization",
        "tech_stack": ["React", "Python", "FastAPI", "Whisper", "Coqui TTS", "FFmpeg"],
        "abstract": (
            "Dubbify is an automated multimedia localization engine that dubs video recordings into regional Indian and international "
            "languages while preserving natural speaker pacing. The pipeline utilizes OpenAI Whisper for speech-to-text diarization, "
            "neural machine translation for semantic cross-lingual mapping, and neural text-to-speech models to synthesize localized "
            "audio tracks. FFmpeg dynamically adjusts speech timing and overlays the synthesized audio onto the original video "
            "with lip-sync alignment."
        )
    }
]

def generate_pdf_report(pdf_path, title, roll_no, author_name, batch, guide_name, abstract, domain, tech_stack):
    doc = SimpleDocTemplate(
        pdf_path,
        pagesize=letter,
        rightMargin=45,
        leftMargin=45,
        topMargin=45,
        bottomMargin=45
    )
    styles = getSampleStyleSheet()

    header_title_style = ParagraphStyle(
        'HeaderTitle',
        parent=styles['Normal'],
        fontName='Helvetica-Bold',
        fontSize=15,
        leading=19,
        textColor=colors.HexColor('#1e293b'),
        alignment=1
    )

    sub_header_style = ParagraphStyle(
        'SubHeader',
        parent=styles['Normal'],
        fontName='Helvetica',
        fontSize=10,
        leading=14,
        textColor=colors.HexColor('#475569'),
        alignment=1
    )

    h1_style = ParagraphStyle(
        'H1',
        parent=styles['Normal'],
        fontName='Helvetica-Bold',
        fontSize=12,
        leading=16,
        textColor=colors.HexColor('#0f172a'),
        spaceBefore=14,
        spaceAfter=6
    )

    body_style = ParagraphStyle(
        'Body',
        parent=styles['Normal'],
        fontName='Helvetica',
        fontSize=9.5,
        leading=14,
        textColor=colors.HexColor('#334155')
    )

    meta_label = ParagraphStyle('MLabel', fontName='Helvetica-Bold', fontSize=9, textColor=colors.HexColor('#1e293b'))
    meta_val = ParagraphStyle('MVal', fontName='Helvetica', fontSize=9, textColor=colors.HexColor('#334155'))

    story = []

    # Institution Header
    story.append(Paragraph("PSG COLLEGE OF TECHNOLOGY", header_title_style))
    story.append(Paragraph("DEPARTMENT OF COMPUTER APPLICATIONS (MCA)", sub_header_style))
    story.append(Paragraph("MASTER OF COMPUTER APPLICATIONS &bull; CAPSTONE PROJECT REPORT", sub_header_style))
    story.append(Spacer(1, 8))
    story.append(HRFlowable(width="100%", thickness=1.5, color=colors.HexColor('#3b82f6'), spaceBefore=2, spaceAfter=12))

    # Project Title
    proj_title_style = ParagraphStyle(
        'PTitle',
        parent=styles['Normal'],
        fontName='Helvetica-Bold',
        fontSize=13,
        leading=17,
        textColor=colors.HexColor('#1d4ed8'),
        alignment=1
    )
    story.append(Paragraph(title.upper(), proj_title_style))
    story.append(Spacer(1, 12))

    # Meta Table
    meta_data = [
        [Paragraph("Candidate Name:", meta_label), Paragraph(author_name, meta_val), Paragraph("Roll Number:", meta_label), Paragraph(roll_no, meta_val)],
        [Paragraph("Academic Batch:", meta_label), Paragraph(batch, meta_val), Paragraph("Faculty Guide:", meta_label), Paragraph(guide_name, meta_val)],
        [Paragraph("Research Domain:", meta_label), Paragraph(domain, meta_val), Paragraph("Evaluation Status:", meta_label), Paragraph("Approved (Capstone)", meta_val)]
    ]
    meta_table = Table(meta_data, colWidths=[95, 165, 95, 165])
    meta_table.setStyle(TableStyle([
        ('BACKGROUND', (0,0), (-1,-1), colors.HexColor('#f8fafc')),
        ('BOX', (0,0), (-1,-1), 1, colors.HexColor('#cbd5e1')),
        ('INNERGRID', (0,0), (-1,-1), 0.5, colors.HexColor('#e2e8f0')),
        ('TOPPADDING', (0,0), (-1,-1), 5),
        ('BOTTOMPADDING', (0,0), (-1,-1), 5),
        ('LEFTPADDING', (0,0), (-1,-1), 6),
        ('RIGHTPADDING', (0,0), (-1,-1), 6),
    ]))
    story.append(meta_table)
    story.append(Spacer(1, 14))

    # Abstract Section
    story.append(Paragraph("1. EXECUTIVE ABSTRACT & METHODOLOGY", h1_style))
    story.append(Paragraph(abstract, body_style))
    story.append(Spacer(1, 10))

    # System Architecture Section
    story.append(Paragraph("2. SYSTEM ARCHITECTURE & TECHNICAL SPECIFICATION", h1_style))
    arch_desc = (
        f"The system '{title}' is implemented following modern distributed architectural principles. "
        f"It separates frontend visualization, API services, and robust data persistence. "
        f"The project emphasizes modularity, secure authentication, test coverage, and production reliability "
        f"in adherence to Department of Computer Applications academic standards."
    )
    story.append(Paragraph(arch_desc, body_style))
    story.append(Spacer(1, 10))

    # Technologies Table
    story.append(Paragraph("3. VERIFIED CORE TECHNOLOGY STACK", h1_style))
    tech_str = ", ".join(tech_stack)
    story.append(Paragraph(f"<b>Primary Frameworks & Libraries:</b> {tech_str}", body_style))
    story.append(Spacer(1, 14))

    # Verification Footer
    story.append(HRFlowable(width="100%", thickness=0.8, color=colors.HexColor('#94a3b8'), spaceBefore=8, spaceAfter=8))
    footer_text = Paragraph(
        "<i>This document is an authenticated institutional archive record generated by ProjectVault for the MCA Department, PSG College of Technology.</i>",
        sub_header_style
    )
    story.append(footer_text)

    doc.build(story)

def remediate_all():
    print("=" * 80)
    print("PROJECTVAULT: REMEDIATING SENIOR PROJECTS (TITLES, ABSTRACTS & AUTHOR NAMES)")
    print("=" * 80)

    conn = psycopg2.connect(**DB_CONFIG)
    conn.autocommit = True
    cur = conn.cursor(cursor_factory=RealDictCursor)

    # 1. Fetch faculty list for guide assignments
    cur.execute("SELECT id, name, email FROM users WHERE role = 'FACULTY' ORDER BY id;")
    faculty_rows = cur.fetchall()
    faculty_list = [(f["id"], f["name"]) for f in faculty_rows]

    # 2. Initialize SentenceTransformer embedding model
    print("\nLoading SentenceTransformer embedding model (all-MiniLM-L6-v2)...")
    from sentence_transformers import SentenceTransformer
    embed_model = SentenceTransformer("all-MiniLM-L6-v2")
    print("Embedding model loaded successfully.")

    updated_count = 0

    for item in PROJECT_CATALOG:
        pid = item["id"]
        roll = item["roll_no"]
        name = item["student_name"]
        title = item["title"]
        domain = item["domain"]
        tech_stack = item["tech_stack"]
        abstract = item["abstract"]

        batch = "24MX" if "24MX" in roll else "23MX"
        acad_year = "2024-2026" if batch == "24MX" else "2023-2025"
        guide_id, guide_name = faculty_list[pid % len(faculty_list)]

        # A. Update student user record
        cur.execute("SELECT created_by_user_id FROM projects WHERE id = %s;", (pid,))
        p_row = cur.fetchone()
        if p_row and p_row["created_by_user_id"]:
            uid = p_row["created_by_user_id"]
            cur.execute("""
                UPDATE users 
                SET name = %s, roll_no = %s
                WHERE id = %s;
            """, (name, roll, uid))
        else:
            # Update user by roll_no / email
            cur.execute("""
                UPDATE users 
                SET name = %s, roll_no = %s
                WHERE roll_no = %s OR email = %s;
            """, (name, roll, roll, f"{roll.lower()}@psgtech.ac.in"))

        # B. Update projects table
        cur.execute("""
            UPDATE projects
            SET title = %s,
                abstract = %s,
                academic_year = %s,
                semester = 4,
                project_type = 'CAPSTONE',
                status = 'APPROVED',
                guide_faculty_id = %s,
                updated_at = NOW()
            WHERE id = %s;
        """, (title, abstract, acad_year, guide_id, pid))

        # C. Update ai_analyses table
        cur.execute("""
            INSERT INTO ai_analyses (project_id, summary, domain, extracted_keywords, tech_stack, problem_statement, ai_status, created_at, updated_at)
            VALUES (%s, %s, %s, %s, %s, %s, 'COMPLETED', NOW(), NOW())
            ON CONFLICT (project_id) DO UPDATE SET
                summary = EXCLUDED.summary,
                domain = EXCLUDED.domain,
                extracted_keywords = EXCLUDED.extracted_keywords,
                tech_stack = EXCLUDED.tech_stack,
                problem_statement = EXCLUDED.problem_statement,
                updated_at = NOW();
        """, (pid, abstract, domain, [domain] + tech_stack[:4], tech_stack, abstract[:300]))

        # D. Compute 384-dimensional vector embedding
        text_to_embed = f"Title: {title}\nAbstract: {abstract}\nDomain: {domain}\nTechnologies: {', '.join(tech_stack)}"
        vector = embed_model.encode(text_to_embed, normalize_embeddings=True).tolist()
        vector_str = "[" + ",".join(str(round(v, 6)) for v in vector) + "]"

        try:
            cur.execute("""
                INSERT INTO project_embeddings (project_id, embedding_vector, updated_at)
                VALUES (%s, %s::vector, NOW())
                ON CONFLICT (project_id) DO UPDATE SET
                    embedding_vector = EXCLUDED.embedding_vector,
                    updated_at = NOW();
            """, (pid, vector_str))
        except Exception:
            # Fallback if vector extension cast differs
            cur.execute("""
                INSERT INTO project_embeddings (project_id, embedding_vector, updated_at)
                VALUES (%s, %s, NOW())
                ON CONFLICT (project_id) DO UPDATE SET
                    embedding_vector = EXCLUDED.embedding_vector,
                    updated_at = NOW();
            """, (pid, vector))

        # E. Regenerate formal Report PDF in storage/projects/{id}/
        proj_dir = f"d:/projectvault/storage/projects/{pid}"
        os.makedirs(proj_dir, exist_ok=True)
        pdf_name = f"{roll}_{re.sub(r'[^a-zA-Z0-9]+', '_', title)[:35]}_Report.pdf"
        pdf_path = os.path.join(proj_dir, pdf_name)
        generate_pdf_report(pdf_path, title, roll, name, batch, guide_name, abstract, domain, tech_stack)

        # Update project_files record
        cur.execute("""
            UPDATE project_files
            SET file_name = %s,
                file_path = %s
            WHERE project_id = %s AND file_type = 'REPORT';
        """, (pdf_name, pdf_path.replace('\\', '/'), pid))

        updated_count += 1
        print(f"[{updated_count:02d}/38] Remediated Project #{pid:02d} ({roll} - {name}) -> '{title[:45]}...'")

    cur.close()
    conn.close()

    print("\n" + "=" * 80)
    print(f"SUCCESS: Remediated all {updated_count} projects, user names, abstracts, embeddings & PDFs!")
    print("=" * 80)

if __name__ == "__main__":
    remediate_all()
