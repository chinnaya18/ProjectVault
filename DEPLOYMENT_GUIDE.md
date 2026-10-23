# ProjectVault — Department LAN Deployment Guide (MCA Department)

This document provides instructions for deploying **ProjectVault** on an allotted PC within the department network, allowing students and faculty to access the platform via the department IP address.

---

## 1. System Architecture Overview

ProjectVault is composed of 3 modular services orchestrated for LAN operation:
1. **Frontend Web Client:** React 18 + Vite (Bound to `0.0.0.0:5173`, with automatic internal reverse-proxy to backend APIs).
2. **Core Backend API:** Spring Boot 3.3.4 + Java 17 (Running on port `8080`).
3. **AI Intelligence Microservice:** Python FastAPI + pgvector + AST Multimodal Duplication Engine (Running on port `8000`).
4. **Relational & Vector Store:** PostgreSQL 15/16 + `pgvector` extension (Running on port `5432`).

---

## 2. Prerequisites on Allotted Department PC

Ensure the following runtimes are installed on the allotted PC:
- **Operating System:** Windows 10/11 or Windows Server (or Linux/Ubuntu)
- **Java:** JDK 17 or higher
- **Node.js:** v18 or v20 LTS
- **Python:** 3.10, 3.11, or 3.12 (with `pip`)
- **PostgreSQL:** Version 15 or 16 with `pgvector` extension installed
- **Maven:** 3.8+ (optional if using `mvnw` or already compiled JAR)

*(Alternatively, if the department PC has Docker Desktop installed, only Docker & Docker Compose are required).*

---

## 3. Step-by-Step Installation (Native Windows Mode)

### Step 1: Extract the Project Archive
Unzip `ProjectVault-MCA.zip` into a clean folder, for example:
```text
D:\ProjectVault
```

### Step 2: Database Setup & Data Restoration
1. Open PostgreSQL Command Line (`psql`) or pgAdmin:
   ```sql
   CREATE DATABASE projectvault;
   \c projectvault;
   CREATE EXTENSION IF NOT EXISTS vector;
   ```
2. Restore the pre-seeded MCA database (contains all 38 verified projects, 18 faculty accounts, and 25MX student nominal roll):
   ```cmd
   psql -U postgres -d projectvault -f "D:\ProjectVault\data\projectvault_full_backup.sql"
   ```

### Step 3: Install Frontend & AI Dependencies (First-Time Setup)
1. **Frontend:**
   ```cmd
   cd D:\ProjectVault\frontend
   npm install
   ```
2. **AI Microservice:**
   ```cmd
   cd D:\ProjectVault\ai-service
   pip install -r requirements.txt
   ```

### Step 4: Configure Environment Variables
Copy `.env.example` to `.env` in the root folder:
```cmd
copy .env.example .env
```
Ensure database credentials match the department PC's PostgreSQL password:
```env
DB_HOST=localhost
DB_PORT=5432
DB_NAME=projectvault
DB_USER=postgres
DB_PASSWORD=your_postgres_password
```

---

## 4. Launching the Services

Double-click or run:
```cmd
D:\ProjectVault\start-all.bat
```
This automatically launches all 3 services in separate windows:
- **Spring Boot Backend:** `http://localhost:8080`
- **FastAPI AI Service:** `http://localhost:8000`
- **React Frontend:** `http://0.0.0.0:5173`

---

## 5. Connecting via Department LAN IP

1. Open PowerShell or Command Prompt on the allotted PC and run:
   ```cmd
   ipconfig
   ```
   Note the IPv4 Address (e.g. `10.18.25.102` or `192.168.1.50`).

2. **Access URL for All Department Users:**
   Any student, faculty, or visitor connected to the college LAN/WiFi can access ProjectVault directly in their web browser:
   ```text
   http://<DEPARTMENT_PC_IP>:5173
   ```
   *(Example: `http://10.18.25.102:5173`)*

> [!NOTE]
> Vite's built-in reverse proxy forwards all API and AI service calls internally on the host machine. You do **not** need to open ports 8080 or 8000 across the network firewall—only port **5173** needs to be accessible over LAN.

---

## 6. Pre-Configured Department Accounts

| Role | Email | Initial Password | Description |
| :--- | :--- | :--- | :--- |
| **Department Admin / HOD** | `admin@psgtech.ac.in` | `Password@123` | Full access, nominal roll ingestion, user governance, audit trail |
| **HOD (i/c) Faculty Guide** | `nir.mca@psgtech.ac.in` | `Password@123` | Dr. Ilayaraja N (Designated Guide reviews & approvals) |
| **Faculty Guide** | `vrm.mca@psgtech.ac.in` | `Password@123` | Dr. Manavalan R (Associate Professor) |
| **Faculty Guide** | `sng.mca@psgtech.ac.in` | `Password@123` | Dr. Geetha N (Assistant Professor Sl. Gr.) |
| **Student (25MX Batch)** | `25mx102@psgtech.ac.in` | Custom Password | Activated student profile (Balasubramaniam S) |
| **Other 25MX Students** | `25mx...@psgtech.ac.in` | `Password@123` | Can sign in or activate via Google SMTP OTP |

---

## 7. Alternative: Single-Command Docker Deployment

If Docker Desktop is installed on the allotted PC:
```cmd
cd D:\ProjectVault
docker-compose up -d
```
ProjectVault will run on port `80`:
```text
http://<DEPARTMENT_PC_IP>
```
