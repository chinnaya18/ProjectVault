import os
import subprocess

def update_roles():
    env = os.environ.copy()
    env["PGPASSWORD"] = "0608"
    
    sql = """
    UPDATE users SET role = 'ADMIN' WHERE email = 'admin@university.edu';
    UPDATE users SET role = 'FACULTY' WHERE email = 'faculty@university.edu';
    UPDATE users SET role = 'STUDENT' WHERE email = 'student@university.edu';
    """
    
    cmd = ["psql", "-U", "postgres", "-h", "localhost", "-d", "projectvault", "-c", sql]
    res = subprocess.run(cmd, env=env, capture_output=True, text=True)
    if res.returncode == 0:
        print("Successfully updated user roles in PostgreSQL!")
        print(res.stdout)
    else:
        print("Error updating roles:", res.stderr)

if __name__ == "__main__":
    update_roles()
