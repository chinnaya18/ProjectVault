@echo off
set PGPASSWORD=0608
psql -U postgres -h localhost -p 5432 -d projectvault -c "SELECT id, email, name, roll_no, role, user_status FROM users ORDER BY id ASC;"
