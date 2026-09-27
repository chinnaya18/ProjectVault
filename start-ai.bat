@echo off
title ProjectVault AI Service (FastAPI :8000)
cd /d "%~dp0ai-service"
echo Starting FastAPI AI Microservice on http://localhost:8000...
uvicorn app.main:app --reload --port 8000
pause
