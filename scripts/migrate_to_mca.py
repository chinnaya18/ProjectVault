import psycopg2

def migrate():
    conn = psycopg2.connect("postgresql://postgres:0608@localhost:5432/projectvault")
    cur = conn.cursor()
    
    # 1. Update department 1
    cur.execute("""
        UPDATE departments 
        SET name = 'Computer Applications', 
            code = 'MCA', 
            description = 'Master of Computer Applications Department' 
        WHERE id = 1;
    """)
    
    # 2. Assign all faculties and students to MCA (department_id = 1)
    cur.execute("UPDATE users SET department_id = 1;")
    conn.commit()
    
    cur.execute("SELECT id, name, email, role, department_id FROM users ORDER BY role, id;")
    users = cur.fetchall()
    print("Migrated Users:")
    for u in users:
        print(f"ID: {u[0]} | {u[1]} ({u[2]}) | Role: {u[3]} | Dept ID: {u[4]}")
        
    cur.close()
    conn.close()

if __name__ == "__main__":
    migrate()
