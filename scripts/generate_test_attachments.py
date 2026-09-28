import os
from reportlab.lib.pagesizes import letter
from reportlab.platypus import SimpleDocTemplate, Paragraph, Spacer, Table, TableStyle, HRFlowable
from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
from reportlab.lib import colors

def create_pdf(filename, title, subtitle, metadata, sections):
    os.makedirs(os.path.dirname(filename), exist_ok=True)
    doc = SimpleDocTemplate(
        filename,
        pagesize=letter,
        rightMargin=45,
        leftMargin=45,
        topMargin=45,
        bottomMargin=45
    )

    styles = getSampleStyleSheet()
    
    title_style = ParagraphStyle(
        'DocTitle',
        parent=styles['Heading1'],
        fontName='Helvetica-Bold',
        fontSize=18,
        leading=22,
        textColor=colors.HexColor('#1E293B'),
        spaceAfter=6
    )

    subtitle_style = ParagraphStyle(
        'DocSubtitle',
        parent=styles['Normal'],
        fontName='Helvetica-Bold',
        fontSize=12,
        leading=16,
        textColor=colors.HexColor('#4338CA'),
        spaceAfter=12
    )

    meta_label_style = ParagraphStyle(
        'MetaLabel',
        parent=styles['Normal'],
        fontName='Helvetica-Bold',
        fontSize=9,
        leading=12,
        textColor=colors.HexColor('#64748B')
    )

    meta_val_style = ParagraphStyle(
        'MetaVal',
        parent=styles['Normal'],
        fontName='Helvetica',
        fontSize=9,
        leading=12,
        textColor=colors.HexColor('#0F172A')
    )

    h2_style = ParagraphStyle(
        'Heading2Custom',
        parent=styles['Heading2'],
        fontName='Helvetica-Bold',
        fontSize=12,
        leading=15,
        textColor=colors.HexColor('#0F172A'),
        spaceBefore=12,
        spaceAfter=6
    )

    body_style = ParagraphStyle(
        'BodyCustom',
        parent=styles['Normal'],
        fontName='Helvetica',
        fontSize=9.5,
        leading=14,
        textColor=colors.HexColor('#334155'),
        spaceAfter=8
    )

    bullet_style = ParagraphStyle(
        'BulletCustom',
        parent=styles['Normal'],
        fontName='Helvetica',
        fontSize=9.5,
        leading=13,
        textColor=colors.HexColor('#334155'),
        leftIndent=15,
        firstLineIndent=-10,
        spaceAfter=4
    )

    story = []

    # Title & Subtitle
    story.append(Paragraph(title, title_style))
    story.append(Paragraph(subtitle, subtitle_style))
    story.append(HRFlowable(width="100%", thickness=1.5, color=colors.HexColor('#E2E8F0'), spaceAfter=10))

    # Metadata Table
    meta_data = []
    for k, v in metadata.items():
        meta_data.append([Paragraph(f"<b>{k}:</b>", meta_label_style), Paragraph(v, meta_val_style)])
    
    t = Table(meta_data, colWidths=[130, 390])
    t.setStyle(TableStyle([
        ('BACKGROUND', (0,0), (-1,-1), colors.HexColor('#F8FAFC')),
        ('BOX', (0,0), (-1,-1), 0.5, colors.HexColor('#E2E8F0')),
        ('INNERGRID', (0,0), (-1,-1), 0.5, colors.HexColor('#F1F5F9')),
        ('PADDING', (0,0), (-1,-1), 5),
    ]))
    story.append(t)
    story.append(Spacer(1, 14))

    # Sections
    for heading, paragraphs in sections:
        story.append(Paragraph(heading, h2_style))
        for p in paragraphs:
            if p.startswith("•") or p.startswith("-"):
                story.append(Paragraph(f"• {p.lstrip('•- ')}", bullet_style))
            else:
                story.append(Paragraph(p, body_style))
        story.append(Spacer(1, 4))

    doc.build(story)
    print(f"Generated: {filename}")

if __name__ == "__main__":
    out_dir = r"d:\projectvault\test-attachments"

    # ==========================================
    # Project 1 - Document 1: Synopsis
    # ==========================================
    p1_synopsis_sections = [
        ("1. Project Summary & Motivation", [
            "Agricultural irrigation consumes over 70% of global accessible freshwater. Traditional timer-based irrigation schedules often result in substantial water wastage due to disregard for actual soil water retention and real-time precipitation dynamics.",
            "This project develops an IoT Automated Smart Irrigation and Soil Moisture Analytics System deploying ESP32 microcontrollers and capacitive moisture sensors. By collecting localized soil telemetry and computing evapotranspiration thresholds, the system activates solenoid valve actuators over MQTT only when moisture falls below critical crop thresholds."
        ]),
        ("2. Core Objectives", [
            "• Deploy low-power ESP32 edge microcontroller nodes across segmented field zones.",
            "• Continuously measure ground moisture percentage, ambient humidity, and thermal levels.",
            "• Automate solenoid valve relays with safety timeout shut-offs to prevent over-watering.",
            "• Stream real-time telemetry to a cloud dashboard for agricultural analytics and water volume savings tracking."
        ]),
        ("3. System Architecture & Methodology", [
            "The edge nodes acquire analog telemetry via capacitive moisture sensors (v1.2) and DHT22 sensors. An embedded FreeRTOS loop converts raw voltage signals into calibrated volumetric water content (VWC) metrics.",
            "Data packets are packaged in JSON and transmitted over 2.4 GHz Wi-Fi / MQTT broker to the ProjectVault analytics backend. When threshold VWC < 35% is met, a relay activation command is triggered for 120 seconds."
        ]),
        ("4. Expected Outcomes & Impact", [
            "• Conservation of irrigation water by approximately 30% to 38% compared to timer systems.",
            "• Reduction in crop root rot caused by oversaturation in clay and loam soils.",
            "• Automated alert dispatch via Telegram/Email when anomalous sensor disconnects occur."
        ])
    ]

    create_pdf(
        os.path.join(out_dir, "Project1_Smart_Irrigation_Synopsis.pdf"),
        "IoT Automated Smart Irrigation and Soil Moisture Analytics System",
        "Project Synopsis & Executive Proposal (MCA Mini Project)",
        {
            "Academic Year": "2024-2025 (Semester 3)",
            "Course / Type": "Mini Project (MCA-305)",
            "Department": "Master of Computer Applications (MCA)",
            "Repository URL": "https://github.com/projectvault/smart-irrigation-iot.git",
            "Hardware Target": "ESP32-WROOM-32, Capacitive Soil Moisture Sensors, 12V Solenoid Valves"
        },
        p1_synopsis_sections
    )

    # ==========================================
    # Project 1 - Document 2: SRS
    # ==========================================
    p1_srs_sections = [
        ("1. Introduction & Scope", [
            "This Software Requirements Specification (SRS) details the functional, operational, and interface requirements for the IoT Smart Irrigation controller firmware and cloud monitoring dashboard."
        ]),
        ("2. Functional Requirements", [
            "• FR-01 (Sensor Data Acquisition): The ESP32 node must sample moisture and temperature sensors at 15-second intervals.",
            "• FR-02 (Threshold Evaluation): The system must trigger solenoid valve relay GPIO pin HIGH when calibrated VWC drops below 35%.",
            "• FR-03 (MQTT Broker Telemetry): Telemetry packets containing node_id, timestamp, vwc, and battery_voltage must publish to 'farm/zone1/telemetry'.",
            "• FR-04 (Manual Override): The cloud dashboard must provide a secure switch to manually open or close water valves.",
            "• FR-05 (Fail-Safe Timer): The valve must auto-close after 5 continuous minutes of pumping if sensor readings do not update."
        ]),
        ("3. Non-Functional Requirements", [
            "• Reliability: System must operate uninterrupted with 99.5% uptime during cultivation seasons.",
            "• Power Consumption: Edge nodes must consume less than 80mA in active mode and 15uA in deep sleep.",
            "• Response Latency: Valve activation commands must execute within 1.5 seconds of threshold trigger."
        ]),
        ("4. Hardware & Software Interfaces", [
            "• Microcontroller: ESP32 Dual-Core Tensilica Xtensa 32-bit LX6 @ 240MHz.",
            "• Protocol: MQTT v3.1.1 over TLS 1.3 / TCP Port 8883.",
            "• Database: PostgreSQL with TimescaleDB extension for time-series sensor points."
        ])
    ]

    create_pdf(
        os.path.join(out_dir, "Project1_Smart_Irrigation_SRS.pdf"),
        "Software Requirements Specification (SRS)",
        "IoT Automated Smart Irrigation and Soil Moisture Analytics System",
        {
            "Document Version": "v1.0 (Final Draft)",
            "Project ID / Code": "MCA-2024-IOT-041",
            "Repository": "https://github.com/projectvault/smart-irrigation-iot.git",
            "Author": "ProjectVault Student Team"
        },
        p1_srs_sections
    )

    # ==========================================
    # Project 2 - Document 1: Synopsis (Disguised Clone)
    # ==========================================
    p2_synopsis_sections = [
        ("1. Research Background & Purpose", [
            "In modern agronomy, optimizing moisture distribution across arid terrain is critical for yield sustainability. Conventional irrigation setups suffer from severe hydro-inefficiencies due to static delivery timing.",
            "This initiative presents the Precision Hydro-Sensing Agricultural Platform with Closed-Loop Valve Actuation. By integrating specialized micro-sensing nodes with telemetry relay channels, hydraulic discharge is dynamically governed to maintain optimal subterranean hydration."
        ]),
        ("2. Strategic Goals", [
            "• Deploy telemetry nodes featuring multi-channel ground probes across agricultural zones.",
            "• Continuously evaluate subterranean hydration levels and thermal environmental factors.",
            "• Regulate valve actuation modules autonomously according to calculated moisture thresholds.",
            "• Deliver operational intelligence to a centralized agricultural management portal."
        ]),
        ("3. Methodological Framework", [
            "Subterranean sensing probes translate dielectric soil properties into proportional electrical potentials. The primary processing unit computes volumetric moisture percentages and publishes encrypted telemetry via wireless packet brokers.",
            "Upon detecting hydration deficits below designated target indices, an actuation relay energizes the delivery valve for a calibrated duration, replenishing soil beds."
        ]),
        ("4. Anticipated Outcomes", [
            "• Significant reduction in water expenditure across arid cultivation plots.",
            "• Mitigation of soil nutrient leaching caused by over-saturation.",
            "• Proactive transmission of telemetry anomalies and battery degradation alerts."
        ])
    ]

    create_pdf(
        os.path.join(out_dir, "Project2_Precision_HydroSensing_Synopsis.pdf"),
        "Precision Hydro-Sensing Agricultural Platform with Closed-Loop Valve Actuation",
        "Project Synopsis & Technical Proposal (Disguised Clone Submission)",
        {
            "Academic Year": "2025-2026 (Semester 3)",
            "Course / Type": "Mini Project (MCA-305)",
            "Department": "Master of Computer Applications (MCA)",
            "Repository URL": "https://github.com/projectvault/smart-irrigation-iot.git",
            "Target Architecture": "Low-Power Sensing Microcontroller, Dielectric Ground Probes, Actuation Solenoids"
        },
        p2_synopsis_sections
    )

    # ==========================================
    # Project 2 - Document 2: SRS (Disguised Clone)
    # ==========================================
    p2_srs_sections = [
        ("1. Specification Scope", [
            "This Technical Requirements Document establishes the operational specifications and system constraints for the Precision Hydro-Sensing Agricultural telemetry unit and valve control subsystem."
        ]),
        ("2. Operational Requirements", [
            "• REQ-A1 (Ground Metric Ingestion): Sensing probes must measure ground hydration and thermal parameters at 15-second cycles.",
            "• REQ-A2 (Automated Discharge Control): The platform must energize hydraulic discharge relays whenever moisture index falls below 35%.",
            "• REQ-A3 (Wireless Broker Publication): Ingested telemetry must be formatted in JSON and transmitted to the wireless broker topic 'agri/zone1/metrics'.",
            "• REQ-A4 (Administrative Direct Override): The web console must furnish authorized operators with manual override controls for hydraulic lines.",
            "• REQ-A5 (Emergency Timeout Protection): Discharge valves must automatically de-energize after 300 seconds if telemetry reception is interrupted."
        ]),
        ("3. System Quality Attributes", [
            "• Resilience: The sensing apparatus must maintain continuous field operation with minimal maintenance.",
            "• Energy Efficiency: Micro-nodes must leverage low-power deep sleep cycles between telemetry transmissions.",
            "• Command Responsiveness: Valve trigger commands must achieve execution within 1500 milliseconds."
        ]),
        ("4. Physical & Protocol Specifications", [
            "• Microcontroller: 32-bit Dual-Core Wireless SoC @ 240MHz.",
            "• Communication: MQTT over TLS v1.3.",
            "• Persistence Layer: Relational Time-Series Database."
        ])
    ]

    create_pdf(
        os.path.join(out_dir, "Project2_Precision_HydroSensing_SRS.pdf"),
        "System & Operational Requirements Specification",
        "Precision Hydro-Sensing Agricultural Platform with Closed-Loop Valve Actuation",
        {
            "Document Version": "v1.0 (Proposal Draft)",
            "Project Reference": "MCA-2025-AGRI-088",
            "Repository": "https://github.com/projectvault/smart-irrigation-iot.git",
            "Author": "Student Candidate"
        },
        p2_srs_sections
    )
