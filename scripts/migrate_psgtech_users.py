import psycopg2

def run_migration():
    conn = psycopg2.connect('postgresql://postgres:0608@localhost:5432/projectvault')
    cur = conn.cursor()

    # Get working password_hash from existing user
    cur.execute("SELECT password_hash FROM users WHERE role = 'ADMIN' OR email LIKE '%admin%' LIMIT 1;")
    row = cur.fetchone()
    hashed_pw = row[0] if row else "$2a$10$7EqJtq98hPqEX7fNZaFWoO9vS0Znp5Q.1/K9U/vjO5uE4EwI90yq6"

    # 1. Update Admin account
    cur.execute("""
        UPDATE users 
        SET email = 'admin.mca@psgtech.ac.in', name = 'Department Admin', roll_no = 'HOD-MCA'
        WHERE role = 'ADMIN' OR email LIKE 'admin%';
    """)

    # 2. Update Student accounts to @psgtech.ac.in
    cur.execute("""
        UPDATE users 
        SET email = REPLACE(REPLACE(email, '@university.edu', '@psgtech.ac.in'), '@projectvault.edu', '@psgtech.ac.in')
        WHERE role = 'STUDENT';
    """)

    # 3. Ensure MCA Department exists
    cur.execute("""
        INSERT INTO departments (id, name, code, description)
        VALUES (1, 'Master of Computer Applications', 'MCA', 'Department of Computer Applications, PSG College of Technology')
        ON CONFLICT (id) DO UPDATE SET name = EXCLUDED.name, code = EXCLUDED.code;
    """)

    # 4. Authentic 18 Faculty Members from PSG College of Technology MCA Department
    faculty_roster = [
        ('Dr. Ilayaraja N', 'Assistant Professor & Head (i/c)', 'nir.mca@psgtech.ac.in'),
        ('Dr. Manavalan R', 'Associate Professor', 'vrm.mca@psgtech.ac.in'),
        ('Mrs. Kalyani A', 'Assistant Professor (Sl. Gr.)', 'akk.mca@psgtech.ac.in'),
        ('Dr. Chitra A', 'Professor', 'ac.mca@psgtech.ac.in'),
        ('Dr. Sankar A', 'Professor', 'dras.mca@psgtech.ac.in'),
        ('Dr. Geetha N', 'Assistant Professor (Sl. Gr.)', 'sng.mca@psgtech.ac.in'),
        ('Dr. Bhama S', 'Assistant Professor (Sl. Gr.)', 'sba.mca@psgtech.ac.in'),
        ('Dr. Subathra M', 'Assistant Professor (Sl. Gr.)', 'msa.mca@psgtech.ac.in'),
        ('Mr. Sundar C', 'Assistant Professor (Sl. Gr.)', 'csr.mca@psgtech.ac.in'),
        ('Dr. Umarani V', 'Assistant Professor (Sl. Gr.)', 'vur.mca@psgtech.ac.in'),
        ('Mrs. Gowri Thangam J', 'Assistant Professor (Sr. Gr.)', 'jgt.mca@psgtech.ac.in'),
        ('Mrs. Gayathri K', 'Assistant Professor (Sr. Gr.)', 'kgi.mca@psgtech.ac.in'),
        ('Ms. Aruna R', 'Assistant Professor', 'ran.mca@psgtech.ac.in'),
        ('Dr. Venkatesan V', 'Assistant Professor (Sl. Gr.)', 'vvn.mca@psgtech.ac.in'),
        ('Mrs. Manoranjitham A', 'Assistant Professor (Sl. Gr.)', 'amr.mca@psgtech.ac.in'),
        ('Mrs. Rajeswari N', 'Assistant Professor (Sr. Gr.)', 'nrj.mca@psgtech.ac.in'),
        ('Mrs. Aarthi Mai A S', 'Assistant Professor', 'asa.mca@psgtech.ac.in'),
        ('Dr. Bhuvaneswari A', 'Assistant Professor', 'abh.mca@psgtech.ac.in')
    ]

    # Remove any old generic/visiting placeholder accounts if any
    cur.execute("DELETE FROM users WHERE email = 'monika.mca@psgtech.ac.in';")

    # Map existing faculty IDs or insert
    faculty_id_map = {}
    for full_name, designation, email in faculty_roster:
        cur.execute("SELECT id FROM users WHERE email = %s;", (email,))
        existing = cur.fetchone()
        if existing:
            f_id = existing[0]
            cur.execute("""
                UPDATE users 
                SET name = %s, roll_no = %s, role = 'FACULTY', department_id = 1, is_active = true
                WHERE id = %s;
            """, (full_name, designation, f_id))
        else:
            cur.execute("""
                INSERT INTO users (email, password_hash, name, roll_no, role, user_status, department_id, is_active)
                VALUES (%s, %s, %s, %s, 'FACULTY', 'ACTIVE', 1, true)
                RETURNING id;
            """, (email, hashed_pw, full_name, designation))
            f_id = cur.fetchone()[0]
        faculty_id_map[email] = f_id

    # Update projects guide references if needed
    geetha_id = faculty_id_map.get('sng.mca@psgtech.ac.in')
    gayathri_id = faculty_id_map.get('kgi.mca@psgtech.ac.in')
    manavalan_id = faculty_id_map.get('vrm.mca@psgtech.ac.in')
    ilayaraja_id = faculty_id_map.get('nir.mca@psgtech.ac.in')

    if geetha_id:
        cur.execute("UPDATE projects SET guide_faculty_id = %s WHERE id IN (64, 19, 9);", (geetha_id,))
    if gayathri_id:
        cur.execute("UPDATE projects SET guide_faculty_id = %s WHERE id = 66;", (gayathri_id,))

    conn.commit()

    cur.execute("""
        SELECT id, name, roll_no, email, role FROM users 
        WHERE role = 'FACULTY' 
        ORDER BY id ASC;
    """)
    print("=== Successfully Seeded 18 PSG Tech MCA Faculty Members ===")
    for row in cur.fetchall():
        r_name = row[1] or ""
        r_roll = row[2] or ""
        print(f"ID #{row[0]:2d} | {r_name:25s} | {r_roll:32s} | {row[3]}")

if __name__ == "__main__":
    run_migration()
