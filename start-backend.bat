@echo off
title ProjectVault Backend (Spring Boot :8080)
cd /d "%~dp0backend"
echo Starting Spring Boot Backend on http://localhost:8080...
mvn spring-boot:run
pause
