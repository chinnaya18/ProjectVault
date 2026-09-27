@echo off
echo ===================================================
echo   Starting ProjectVault Full Stack Architecture
echo ===================================================
echo.
echo Launching Backend (Spring Boot :8080)...
start "ProjectVault Backend" cmd /k "cd /d %~dp0backend && mvn spring-boot:run"

echo Launching AI Service (FastAPI :8000)...
start "ProjectVault AI Service" cmd /k "cd /d %~dp0ai-service && uvicorn app.main:app --reload --port 8000"

echo Launching Frontend (React Vite :5173)...
start "ProjectVault Frontend" cmd /k "cd /d %~dp0frontend && npm run dev"

echo.
echo All 3 services have been launched in separate terminal windows.
echo Frontend will be accessible at: http://localhost:5173
echo Backend Swagger API at:         http://localhost:8080/swagger-ui/index.html
echo AI Service Docs at:             http://localhost:8000/docs
echo.
pause
