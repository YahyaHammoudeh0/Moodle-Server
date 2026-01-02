@echo off
REM ===========================================
REM Educational Platform - Stop Script (Windows)
REM ===========================================

set "GREEN=[92m"
set "BLUE=[94m"
set "YELLOW=[93m"
set "NC=[0m"

if "%1"=="logs" (
    echo %BLUE%ℹ%NC% Showing logs (Ctrl+C to exit^)...
    cd "%~dp0edu-platform"
    docker compose logs -f
    exit /b 0
)

echo %BLUE%ℹ%NC% Stopping Educational Platform...

cd "%~dp0edu-platform"
docker compose down

echo %GREEN%✓%NC% Platform stopped successfully
echo.
echo %YELLOW%Note:%NC% Your data is preserved in Docker volumes
echo       To start again, run: start.bat
echo       To remove all data, run: docker compose down -v
echo.

pause
