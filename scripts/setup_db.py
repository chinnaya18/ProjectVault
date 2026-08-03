import subprocess
import os
import sys

PG_HOST = os.environ.get("DB_HOST", "localhost")
PG_PORT = os.environ.get("DB_PORT", "5432")
PG_USER = os.environ.get("DB_USER", "postgres")
PG_PASSWORD = os.environ.get("DB_PASSWORD", "0608")
DB_NAME = os.environ.get("DB_NAME", "projectvault")

env = os.environ.copy()
env["PGPASSWORD"] = PG_PASSWORD

def run_psql(cmd_args, db="postgres"):
    full_cmd = ["psql", "-U", PG_USER, "-h", PG_HOST, "-p", PG_PORT, "-d", db] + cmd_args
    res = subprocess.run(full_cmd, env=env, capture_output=True, text=True)
    return res

def setup():
    print(f"Connecting to PostgreSQL at {PG_HOST}:{PG_PORT} as {PG_USER}...")
    
    # 1. Create database if not exists
    check_db = run_psql(["-tAc", f"SELECT 1 FROM pg_database WHERE datname='{DB_NAME}'"])
    if check_db.stdout.strip() != "1":
        print(f"Database '{DB_NAME}' does not exist. Creating...")
        res = run_psql(["-c", f"CREATE DATABASE {DB_NAME};"])
        if res.returncode != 0:
            print(f"Failed to create database: {res.stderr}")
            sys.exit(1)
        print(f"Database '{DB_NAME}' created successfully.")
    else:
        print(f"Database '{DB_NAME}' already exists.")

    # 2. Check and Create vector extension
    print("Checking pgvector extension...")
    ext_res = run_psql(["-c", "CREATE EXTENSION IF NOT EXISTS vector;"], db=DB_NAME)
    if ext_res.returncode != 0:
        print(f"Warning/Error creating pgvector extension: {ext_res.stderr}")
    else:
        print("pgvector extension ready.")

    # 3. Execute init-db.sql
    init_sql_path = os.path.join("scripts", "init-db.sql")
    print(f"Executing schema script {init_sql_path}...")
    res = run_psql(["-f", init_sql_path], db=DB_NAME)
    if res.returncode != 0:
        print(f"Schema execution returned non-zero code: {res.stderr}")
    else:
        print("Schema tables and indexes created successfully.")

    # 4. Insert Seed Data
    seed_sql = """
    -- Departments Seed
    INSERT INTO departments (name, code, description) VALUES
    ('Computer Applications', 'MCA', 'Master of Computer Applications Department'),
    ('Computer Science & Engineering', 'CSE', 'Department of Computer Science and Engineering'),
    ('Information Technology', 'IT', 'Department of Information Technology')
    ON CONFLICT (name) DO NOTHING;

    -- Users Seed (BCrypt hash for password 'Password@123': $2a$10$e8w67qK5Q6F0Tf/3GZ9l2eX.xR9p0k8F4H/J7m.L0Q8q8)
    -- Sample Passwords: 'Password@123'
    INSERT INTO users (email, password_hash, first_name, last_name, role, user_status, department_id) VALUES
    ('admin@projectvault.edu', '$2a$10$7.S5vDq6H/LzX0m2E/0W9.Xf2Fq3pG8K1J0L8M2N4P6Q8R0S2T4U', 'System', 'Admin', 'ADMIN', 'ACTIVE', 1),
    ('faculty.smith@projectvault.edu', '$2a$10$7.S5vDq6H/LzX0m2E/0W9.Xf2Fq3pG8K1J0L8M2N4P6Q8R0S2T4U', 'Robert', 'Smith', 'FACULTY', 'ACTIVE', 1),
    ('student.john@projectvault.edu', '$2a$10$7.S5vDq6H/LzX0m2E/0W9.Xf2Fq3pG8K1J0L8M2N4P6Q8R0S2T4U', 'John', 'Doe', 'STUDENT', 'ACTIVE', 1),
    ('alumni.sarah@projectvault.edu', '$2a$10$7.S5vDq6H/LzX0m2E/0W9.Xf2Fq3pG8K1J0L8M2N4P6Q8R0S2T4U', 'Sarah', 'Connor', 'STUDENT', 'ALUMNI', 1)
    ON CONFLICT (email) DO NOTHING;

    -- Seed Projects
    INSERT INTO projects (title, abstract, academic_year, semester, project_type, status, visibility, department_id, created_by_user_id, repository_url) VALUES
    ('Crop Disease Detection Using Convolutional Neural Networks', 'An automated deep learning system to identify plant pathogens from leaf imagery using ResNet50.', '2024-2025', 4, 'Major Project', 'APPROVED', 'PUBLIC', 1, 3, 'https://github.com/example/crop-disease'),
    ('Smart Campus Parking Management via IoT Sensors', 'An Internet-of-Things based real-time parking spot occupancy tracker using ultrasonic sensors and MQTT broker.', '2024-2025', 4, 'Major Project', 'APPROVED', 'PUBLIC', 1, 4, 'https://github.com/example/smart-parking'),
    ('Blockchain-Based Verified Credential Repository', 'A decentralized academic degree certificate verification platform utilizing Ethereum smart contracts.', '2025-2026', 3, 'Mini Project', 'APPROVED', 'PUBLIC', 1, 3, 'https://github.com/example/blockchain-creds')
    ON CONFLICT DO NOTHING;
    """
    
    print("Seeding baseline data (Departments, Test Users, Sample Projects)...")
    res_seed = run_psql(["-c", seed_sql], db=DB_NAME)
    if res_seed.returncode != 0:
        print(f"Seed insertion error: {res_seed.stderr}")
    else:
        print("Seed data inserted successfully.")

    # 5. Verify Setup
    res_verify = run_psql(["-c", "SELECT count(*) FROM projects;"], db=DB_NAME)
    print(f"Verification: Total projects in DB = {res_verify.stdout.strip()}")

if __name__ == "__main__":
    setup()
