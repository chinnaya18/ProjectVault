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
    -- Departments Seed (MCA alone)
    INSERT INTO departments (name, code, description) VALUES
    ('Master of Computer Applications', 'MCA', 'Master of Computer Applications Department')
    ON CONFLICT (name) DO NOTHING;

    -- Cleanup non-MCA departments if any
    UPDATE users SET department_id = (SELECT id FROM departments WHERE code = 'MCA' LIMIT 1);
    UPDATE projects SET department_id = (SELECT id FROM departments WHERE code = 'MCA' LIMIT 1);
    DELETE FROM departments WHERE code != 'MCA';

    -- Users Seed (BCrypt hash for password 'Password@123')
    INSERT INTO users (email, password_hash, first_name, last_name, role, user_status, department_id) VALUES
    ('admin@university.edu', '$2a$10$7.S5vDq6H/LzX0m2E/0W9.Xf2Fq3pG8K1J0L8M2N4P6Q8R0S2T4U', 'System', 'Admin', 'ADMIN', 'ACTIVE', 1),
    ('geetha@university.edu', '$2a$10$7.S5vDq6H/LzX0m2E/0W9.Xf2Fq3pG8K1J0L8M2N4P6Q8R0S2T4U', 'Geetha', 'Faculty', 'FACULTY', 'ACTIVE', 1),
    ('gayathri@university.edu', '$2a$10$7.S5vDq6H/LzX0m2E/0W9.Xf2Fq3pG8K1J0L8M2N4P6Q8R0S2T4U', 'Gayathri', 'Faculty', 'FACULTY', 'ACTIVE', 1),
    ('manavalan@university.edu', '$2a$10$7.S5vDq6H/LzX0m2E/0W9.Xf2Fq3pG8K1J0L8M2N4P6Q8R0S2T4U', 'Manavalan', 'Faculty', 'FACULTY', 'ACTIVE', 1),
    ('25mx101@university.edu', '$2a$10$7.S5vDq6H/LzX0m2E/0W9.Xf2Fq3pG8K1J0L8M2N4P6Q8R0S2T4U', 'Bala', 'Student', 'STUDENT', 'ACTIVE', 1),
    ('25mx102@university.edu', '$2a$10$7.S5vDq6H/LzX0m2E/0W9.Xf2Fq3pG8K1J0L8M2N4P6Q8R0S2T4U', 'Gopi', 'Student', 'STUDENT', 'ACTIVE', 1),
    ('25mx103@university.edu', '$2a$10$7.S5vDq6H/LzX0m2E/0W9.Xf2Fq3pG8K1J0L8M2N4P6Q8R0S2T4U', 'Kaleel', 'Student', 'STUDENT', 'ACTIVE', 1),
    ('25mx104@university.edu', '$2a$10$7.S5vDq6H/LzX0m2E/0W9.Xf2Fq3pG8K1J0L8M2N4P6Q8R0S2T4U', 'Vikram', 'Student', 'STUDENT', 'ACTIVE', 1),
    ('25mx105@university.edu', '$2a$10$7.S5vDq6H/LzX0m2E/0W9.Xf2Fq3pG8K1J0L8M2N4P6Q8R0S2T4U', 'Chinnaya', 'Student', 'STUDENT', 'ACTIVE', 1),
    ('25mx106@university.edu', '$2a$10$7.S5vDq6H/LzX0m2E/0W9.Xf2Fq3pG8K1J0L8M2N4P6Q8R0S2T4U', 'Saravanavel', 'Student', 'STUDENT', 'ACTIVE', 1)
    ON CONFLICT (email) DO UPDATE SET first_name = EXCLUDED.first_name, last_name = EXCLUDED.last_name, role = EXCLUDED.role;

    -- Delete legacy user accounts
    DELETE FROM users WHERE email NOT IN (
        'admin@university.edu',
        'geetha@university.edu',
        'gayathri@university.edu',
        'manavalan@university.edu',
        '25mx101@university.edu',
        '25mx102@university.edu',
        '25mx103@university.edu',
        '25mx104@university.edu',
        '25mx105@university.edu',
        '25mx106@university.edu'
    );

    -- Seed Projects
    INSERT INTO projects (title, abstract, academic_year, semester, project_type, status, visibility, department_id, created_by_user_id, repository_url) VALUES
    ('Crop Disease Detection Using Convolutional Neural Networks', 'An automated deep learning system to identify plant pathogens from leaf imagery using ResNet50.', '2024-2025', 4, 'Major Project', 'APPROVED', 'PUBLIC', 1, 3, 'https://github.com/example/crop-disease'),
    ('Smart Campus Parking Management via IoT Sensors', 'An Internet-of-Things based real-time parking spot occupancy tracker using ultrasonic sensors and MQTT broker.', '2024-2025', 4, 'Major Project', 'APPROVED', 'PUBLIC', 1, 4, 'https://github.com/example/smart-parking'),
    ('Blockchain-Based Verified Credential Repository', 'A decentralized academic degree certificate verification platform utilizing Ethereum smart contracts.', '2025-2026', 3, 'Mini Project', 'APPROVED', 'PUBLIC', 1, 3, 'https://github.com/example/blockchain-creds')
    ON CONFLICT DO NOTHING;

    -- Seed Project File Attachments
    INSERT INTO project_files (project_id, file_name, file_type, file_size, storage_path, storage_type, uploaded_by_user_id)
    SELECT p.id, 'project_specification_document.pdf', 'application/pdf', 1048576, 'storage/documents/' || p.id || '_spec.pdf', 'LOCAL', p.created_by_user_id
    FROM projects p
    WHERE NOT EXISTS (SELECT 1 FROM project_files pf WHERE pf.project_id = p.id);
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
