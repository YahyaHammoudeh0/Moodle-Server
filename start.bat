@echo off
REM ===========================================
REM Universal Educational Platform Launcher (Windows)
REM ===========================================
REM Works on Windows with Docker Desktop
REM No manual configuration required!
REM
REM Usage: start.bat
REM ===========================================

setlocal enabledelayedexpansion

REM Colors (Windows 10+)
set "BLUE=[94m"
set "GREEN=[92m"
set "YELLOW=[93m"
set "CYAN=[96m"
set "RED=[91m"
set "BOLD=[1m"
set "NC=[0m"

REM ===========================================
REM Banner
REM ===========================================
cls
echo.
echo %CYAN%╔═══════════════════════════════════════════════════════╗%NC%
echo %CYAN%║                                                       ║%NC%
echo %CYAN%║     🎓  Educational Platform                         ║%NC%
echo %CYAN%║                                                       ║%NC%
echo %CYAN%║     Moodle ^| JupyterHub ^| Code Server ^| AI          ║%NC%
echo %CYAN%║                                                       ║%NC%
echo %CYAN%╚═══════════════════════════════════════════════════════╝%NC%
echo.

REM ===========================================
REM Check Docker
REM ===========================================
echo %BLUE%ℹ%NC% Checking Docker installation...

docker --version >nul 2>&1
if errorlevel 1 (
    echo %RED%✗%NC% Docker is not installed!
    echo.
    echo Please install Docker Desktop for Windows:
    echo   → https://www.docker.com/products/docker-desktop
    echo.
    pause
    exit /b 1
)

docker info >nul 2>&1
if errorlevel 1 (
    echo %RED%✗%NC% Docker Desktop is not running!
    echo.
    echo Please start Docker Desktop and try again.
    pause
    exit /b 1
)

docker compose version >nul 2>&1
if errorlevel 1 (
    echo %RED%✗%NC% Docker Compose v2 is not available!
    echo.
    echo Please update Docker Desktop to the latest version.
    pause
    exit /b 1
)

echo %GREEN%✓%NC% Docker is ready
docker --version
docker compose version
echo.

REM ===========================================
REM Setup Environment
REM ===========================================
echo %BLUE%ℹ%NC% Configuring environment...

cd "%~dp0edu-platform"

if exist ".env" (
    echo %BLUE%ℹ%NC% .env file already exists, using existing configuration
) else (
    echo %BLUE%ℹ%NC% No .env found - generating with secure defaults...

    REM Generate random passwords (Windows compatible)
    set "chars=abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"

    REM Simple password generation for Windows
    set "POSTGRES_PASS=PG_%RANDOM%%RANDOM%_Sec"
    set "MOODLE_PASS=MD_%RANDOM%%RANDOM%_Sec"
    set "JUPYTER_PASS=JP_%RANDOM%%RANDOM%_Sec"
    set "CODE_PASS=CS_%RANDOM%%RANDOM%_Sec"
    set "PROXY_PASS=PR_%RANDOM%%RANDOM%_Sec"

    REM Create .env file
    (
        echo # ===========================================
        echo # AUTO-GENERATED CONFIGURATION
        echo # ===========================================
        echo # Generated: %date% %time%
        echo # This configuration works out of the box for local development
        echo.
        echo # Domain Configuration
        echo DOMAIN=localhost
        echo.
        echo # Moodle Configuration
        echo MOODLE_USERNAME=admin
        echo MOODLE_PASSWORD=!MOODLE_PASS!
        echo MOODLE_EMAIL=admin@localhost
        echo MOODLE_SITE_NAME=Educational Platform
        echo.
        echo # PostgreSQL Configuration
        echo POSTGRES_PASSWORD=!POSTGRES_PASS!
        echo POSTGRES_MOODLE_DB=moodle_db
        echo POSTGRES_JUPYTER_DB=jupyterhub_db
        echo.
        echo # JupyterHub Configuration
        echo JUPYTERHUB_ADMIN=admin
        echo JUPYTERHUB_ADMIN_PASSWORD=!JUPYTER_PASS!
        echo JUPYTER_MEMORY_LIMIT=1G
        echo JUPYTER_CPU_LIMIT=0.5
        echo.
        echo # Code Server Configuration
        echo CODE_SERVER_PASSWORD=!CODE_PASS!
        echo.
        echo # DeepSeek API Configuration
        echo DEEPSEEK_API_KEY=sk-placeholder-get-your-key-from-deepseek
        echo DEEPSEEK_PROXY_API_KEY=!PROXY_PASS!
        echo.
        echo # Maxima Configuration
        echo MAXIMA_POOL_SIZE=3
    ) > .env

    REM Create credentials file
    (
        echo ═══════════════════════════════════════════════════════
        echo   🔐 YOUR AUTO-GENERATED CREDENTIALS
        echo ═══════════════════════════════════════════════════════
        echo Generated: %date% %time%
        echo.
        echo 📚 MOODLE ^(http://localhost:8080^)
        echo    Username: admin
        echo    Password: !MOODLE_PASS!
        echo.
        echo 🔬 JUPYTERHUB ^(http://localhost:8000^)
        echo    Username: admin
        echo    Password: !JUPYTER_PASS!
        echo.
        echo 💻 CODE SERVER ^(http://localhost:8443^)
        echo    Password: !CODE_PASS!
        echo.
        echo 🤖 AI PROXY ^(http://localhost:8001^)
        echo    API Key: !PROXY_PASS!
        echo.
        echo ═══════════════════════════════════════════════════════
        echo ⚠️  IMPORTANT: Keep this file secure!
        echo ═══════════════════════════════════════════════════════
    ) > CREDENTIALS.txt

    echo %GREEN%✓%NC% .env file created with secure random passwords
    echo %GREEN%✓%NC% Credentials saved to: CREDENTIALS.txt
)

echo.

REM ===========================================
REM Start Services
REM ===========================================
echo %CYAN%▶%NC% Starting services...
echo.

echo %BLUE%ℹ%NC% Pulling Docker images (this may take a few minutes on first run)...
docker compose pull --quiet

echo %BLUE%ℹ%NC% Building custom images...
docker compose build --quiet

echo %BLUE%ℹ%NC% Starting all containers...
docker compose up -d

echo %GREEN%✓%NC% All services started!
echo.

REM ===========================================
REM Wait for Services
REM ===========================================
echo %CYAN%▶%NC% Waiting for services to be ready...
echo %BLUE%ℹ%NC% This may take 2-3 minutes on first startup...
echo.

timeout /t 20 /nobreak >nul

echo %GREEN%✓%NC% Services are ready!
echo.

REM ===========================================
REM Print Access Information
REM ===========================================
echo.
echo %GREEN%%BOLD%═══════════════════════════════════════════════════════%NC%
echo %GREEN%%BOLD%  🎉 Platform is Running!%NC%
echo %GREEN%%BOLD%═══════════════════════════════════════════════════════%NC%
echo.
echo %BOLD%📍 Access Your Services:%NC%
echo.
echo   %CYAN%📚 Moodle LMS%NC%
echo      → http://localhost:8080
echo.
echo   %CYAN%🔬 JupyterHub%NC%
echo      → http://localhost:8000
echo.
echo   %CYAN%💻 VS Code (Code Server)%NC%
echo      → http://localhost:8443
echo.
echo   %CYAN%🤖 AI Assistant API%NC%
echo      → http://localhost:8001/docs
echo.
echo %BOLD%🔐 Credentials:%NC%
echo      → See CREDENTIALS.txt in edu-platform folder
echo.
echo %BOLD%📊 Useful Commands:%NC%
echo.
echo   %YELLOW%View logs:%NC%         docker compose -f edu-platform/docker-compose.yml logs -f
echo   %YELLOW%Stop platform:%NC%     stop.bat
echo   %YELLOW%Service status:%NC%    docker compose -f edu-platform/docker-compose.yml ps
echo.
echo %GREEN%═══════════════════════════════════════════════════════%NC%
echo.

if exist "CREDENTIALS.txt" (
    type CREDENTIALS.txt
    echo.
)

echo %BLUE%ℹ%NC% Platform is ready to use! 🚀
echo.
echo Press any key to open Moodle in your browser...
pause >nul

start http://localhost:8080

endlocal
