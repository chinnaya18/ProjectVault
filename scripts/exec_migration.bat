@echo off
set PGPASSWORD=0608
psql -U postgres -h localhost -p 5432 -d projectvault -f "%~dp0migrate_user_schema.sql"
