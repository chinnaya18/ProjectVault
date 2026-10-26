@echo off
title ProjectVault Backend (Spring Boot :8081)
cd /d "%~dp0backend"
echo Starting Spring Boot Backend on http://localhost:8081...
mvn spring-boot:run
pause
