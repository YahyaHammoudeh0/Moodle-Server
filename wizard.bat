@echo off
REM ===========================================
REM Educational Platform Setup Wizard (Windows)
REM ===========================================
REM Feature-rich installer with Personal and School modes
REM ===========================================

setlocal enabledelayedexpansion

REM Platform directory
set "SCRIPT_DIR=%~dp0"
set "PLATFORM_DIR=%SCRIPT_DIR%edu-platform"

REM ===========================================
REM Banner
REM ===========================================
cls
echo.
echo    ███████╗██████╗ ██╗   ██╗    ██████╗ ██╗      █████╗ ████████╗███████╗ ██████╗ ██████╗ ███╗   ███╗
echo    ██╔════╝██╔══██╗██║   ██║    ██╔══██╗██║     ██╔══██╗╚══██╔══╝██╔════╝██╔═══██╗██╔══██╗████╗ ████║
echo    █████╗  ██║  ██║██║   ██║    ██████╔╝██║     ███████║   ██║   █████╗  ██║   ██║██████╔╝██╔████╔██║
echo    ██╔══╝  ██║  ██║██║   ██║    ██╔═══╝ ██║     ██╔══██║   ██║   ██╔══╝  ██║   ██║██╔══██╗██║╚██╔╝██║
echo    ███████╗██████╔╝╚██████╔╝    ██║     ███████╗██║  ██║   ██║   ██║     ╚██████╔╝██║  ██║██║ ╚═╝ ██║
echo    ╚══════╝╚═════╝  ╚═════╝     ╚═╝     ╚══════╝╚═╝  ╚═╝   ╚═╝   ╚═╝      ╚═════╝ ╚═╝  ╚═╝╚═╝     ╚═╝
echo.
echo     Moodle + JupyterHub + Code Server + AI + More
echo.

REM ===========================================
REM Check Docker
REM ===========================================
echo Checking Docker...

docker --version >nul 2>&1
if errorlevel 1 (
    echo.
    echo ERROR: Docker is not installed!
    echo.
    echo Please install Docker Desktop from:
    echo   https://www.docker.com/products/docker-desktop
    echo.
    pause
    exit /b 1
)

docker info >nul 2>&1
if errorlevel 1 (
    echo.
    echo ERROR: Docker Desktop is not running!
    echo Please start Docker Desktop and run this again.
    echo.
    pause
    exit /b 1
)

echo Docker ready
echo.

REM ===========================================
REM Detect Resources
REM ===========================================
for /f "tokens=2 delims==" %%i in ('wmic computersystem get TotalPhysicalMemory /value ^| find "="') do set TOTAL_RAM_BYTES=%%i
set /a TOTAL_RAM=!TOTAL_RAM_BYTES:~0,-9!

for /f "tokens=2 delims==" %%i in ('wmic cpu get NumberOfLogicalProcessors /value ^| find "="') do set TOTAL_CORES=%%i

echo System: !TOTAL_RAM!GB RAM, !TOTAL_CORES! CPU cores
echo.

REM ===========================================
REM Mode Selection
REM ===========================================
echo How will you use this platform?
echo.
echo   1) Personal Learning
echo      No passwords, instant access
echo      Perfect for self-learners and developers
echo.
echo   2) School / Institution
echo      Full authentication with SSO
echo      Domain, email, and user management
echo.

:SELECT_MODE
set /p mode_choice="Choose [1-2]: "
if "!mode_choice!"=="1" (
    set MODE=personal
    goto SETUP_PERSONAL
) else if "!mode_choice!"=="2" (
    set MODE=school
    goto SETUP_SCHOOL
) else (
    echo Please enter 1 or 2
    goto SELECT_MODE
)

REM ===========================================
REM Personal Mode Setup
REM ===========================================
:SETUP_PERSONAL
echo.
echo Personal Mode Selected
echo.
echo Your learning environment will be ready with:
echo   - No passwords required
echo   - Auto-login to all services
echo   - Full admin access everywhere
echo.

copy "%PLATFORM_DIR%\templates\.env.personal" "%PLATFORM_DIR%\.env" >nul

set COMPOSE_FILE=docker-compose.personal.yml
goto SELECT_SERVICES

REM ===========================================
REM School Mode Setup
REM ===========================================
:SETUP_SCHOOL
echo.
echo School/Institution Mode Selected
echo.

echo Enter your domain (e.g., myschool.edu)
set /p DOMAIN="> "
if "!DOMAIN!"=="" set DOMAIN=localhost

echo.
echo Admin email (for SSL certificates)
set /p ADMIN_EMAIL="> "
if "!ADMIN_EMAIL!"=="" set ADMIN_EMAIL=admin@!DOMAIN!

echo.
echo School/Organization name
set /p SCHOOL_NAME="> "
if "!SCHOOL_NAME!"=="" set SCHOOL_NAME=My School

REM Generate random passwords using PowerShell
for /f %%i in ('powershell -Command "[Convert]::ToBase64String([System.Security.Cryptography.RandomNumberGenerator]::GetBytes(12)) -replace '[+/=]',''  | Select -First 1"') do set POSTGRES_PASS=%%i
for /f %%i in ('powershell -Command "[Convert]::ToBase64String([System.Security.Cryptography.RandomNumberGenerator]::GetBytes(12)) -replace '[+/=]',''  | Select -First 1"') do set MOODLE_PASS=%%i
for /f %%i in ('powershell -Command "[Convert]::ToBase64String([System.Security.Cryptography.RandomNumberGenerator]::GetBytes(12)) -replace '[+/=]',''  | Select -First 1"') do set JUPYTER_PASS=%%i
for /f %%i in ('powershell -Command "[Convert]::ToBase64String([System.Security.Cryptography.RandomNumberGenerator]::GetBytes(12)) -replace '[+/=]',''  | Select -First 1"') do set CODE_PASS=%%i

copy "%PLATFORM_DIR%\templates\.env.school" "%PLATFORM_DIR%\.env" >nul

REM Update values in .env
powershell -Command "(Get-Content '%PLATFORM_DIR%\.env') -replace 'DOMAIN=.*', 'DOMAIN=!DOMAIN!' | Set-Content '%PLATFORM_DIR%\.env'"
powershell -Command "(Get-Content '%PLATFORM_DIR%\.env') -replace 'ADMIN_EMAIL=.*', 'ADMIN_EMAIL=!ADMIN_EMAIL!' | Set-Content '%PLATFORM_DIR%\.env'"
powershell -Command "(Get-Content '%PLATFORM_DIR%\.env') -replace 'SCHOOL_NAME=.*', 'SCHOOL_NAME=!SCHOOL_NAME!' | Set-Content '%PLATFORM_DIR%\.env'"
powershell -Command "(Get-Content '%PLATFORM_DIR%\.env') -replace 'POSTGRES_PASSWORD=.*', 'POSTGRES_PASSWORD=!POSTGRES_PASS!' | Set-Content '%PLATFORM_DIR%\.env'"
powershell -Command "(Get-Content '%PLATFORM_DIR%\.env') -replace 'MOODLE_PASSWORD=.*', 'MOODLE_PASSWORD=!MOODLE_PASS!' | Set-Content '%PLATFORM_DIR%\.env'"
powershell -Command "(Get-Content '%PLATFORM_DIR%\.env') -replace 'JUPYTERHUB_ADMIN_PASSWORD=.*', 'JUPYTERHUB_ADMIN_PASSWORD=!JUPYTER_PASS!' | Set-Content '%PLATFORM_DIR%\.env'"
powershell -Command "(Get-Content '%PLATFORM_DIR%\.env') -replace 'CODE_SERVER_PASSWORD=.*', 'CODE_SERVER_PASSWORD=!CODE_PASS!' | Set-Content '%PLATFORM_DIR%\.env'"

REM Save credentials
(
    echo ============================================
    echo   ADMIN CREDENTIALS - KEEP SECURE
    echo ============================================
    echo.
    echo Domain: !DOMAIN!
    echo.
    echo MOODLE ^(https://learn.!DOMAIN!^)
    echo   User: admin
    echo   Pass: !MOODLE_PASS!
    echo.
    echo JUPYTERHUB ^(https://jupyter.!DOMAIN!^)
    echo   User: admin
    echo   Pass: !JUPYTER_PASS!
    echo.
    echo CODE SERVER ^(https://code.!DOMAIN!^)
    echo   Pass: !CODE_PASS!
    echo.
    echo DATABASE
    echo   User: postgres
    echo   Pass: !POSTGRES_PASS!
    echo.
    echo ============================================
) > "%PLATFORM_DIR%\CREDENTIALS.txt"

echo.
echo Credentials saved to CREDENTIALS.txt
echo.

set COMPOSE_FILE=docker-compose.school.yml
goto SELECT_SERVICES

REM ===========================================
REM Service Selection
REM ===========================================
:SELECT_SERVICES
echo Select services to install:
echo.

if !TOTAL_RAM! LSS 6 (
    echo With !TOTAL_RAM!GB RAM, we recommend minimal services
) else if !TOTAL_RAM! LSS 12 (
    echo With !TOTAL_RAM!GB RAM, standard services work well
) else if !TOTAL_RAM! LSS 24 (
    echo With !TOTAL_RAM!GB RAM, enhanced services available
) else (
    echo With !TOTAL_RAM!GB RAM, all services available
)
echo.

echo   1) Minimal    (Moodle only - 4GB RAM)
echo   2) Standard   (+ Jupyter, Code Server, AI - 8GB RAM)
echo   3) Enhanced   (+ RStudio, SageMath, Monitoring - 16GB RAM)
echo   4) Full       (Everything! - 32GB RAM)
echo.

:SELECT_PROFILE
set /p profile_choice="Choose [1-4]: "
if "!profile_choice!"=="1" (
    set "SERVICES="
) else if "!profile_choice!"=="2" (
    set "SERVICES=maxima,jupyterhub,code-server"
) else if "!profile_choice!"=="3" (
    set "SERVICES=maxima,jupyterhub,code-server,rstudio,sagemath,grafana,prometheus"
) else if "!profile_choice!"=="4" (
    set "SERVICES=maxima,jupyterhub,code-server,rstudio,sagemath,grafana,prometheus,gitea,n8n,portainer"
) else (
    echo Please enter 1-4
    goto SELECT_PROFILE
)

REM Update COMPOSE_PROFILES in .env
powershell -Command "(Get-Content '%PLATFORM_DIR%\.env') -replace 'COMPOSE_PROFILES=.*', 'COMPOSE_PROFILES=!SERVICES!' | Set-Content '%PLATFORM_DIR%\.env'"

echo.

REM ===========================================
REM Pull Images
REM ===========================================
echo Downloading Docker images...
echo This may take several minutes on first run
echo.

cd /d "%PLATFORM_DIR%"

if "!SERVICES!"=="" (
    docker compose -f docker-compose.yml -f !COMPOSE_FILE! pull
) else (
    docker compose -f docker-compose.yml -f !COMPOSE_FILE! -f docker-compose.optional.yml pull
)

echo.
echo Images downloaded
echo.

REM ===========================================
REM Summary
REM ===========================================
echo.
echo ============================================
echo   Setup Complete!
echo ============================================
echo.

if "!MODE!"=="personal" (
    echo   Mode: Personal Learning (No passwords)
    echo.
    echo   Access URLs:
    echo     Dashboard:    http://localhost:8080
    echo     Moodle:       http://localhost:8081
    echo     JupyterHub:   http://localhost:8000
    echo     Code Server:  http://localhost:8844
) else (
    echo   Mode: School/Institution
    echo   Domain: !DOMAIN!
    echo.
    echo   Access URLs:
    echo     Moodle:       https://learn.!DOMAIN!
    echo     JupyterHub:   https://jupyter.!DOMAIN!
    echo     Code Server:  https://code.!DOMAIN!
    echo.
    echo   Credentials saved to: %PLATFORM_DIR%\CREDENTIALS.txt
)

echo.
echo ============================================
echo.

set /p start_now="Start the platform now? [Y/n] "
if /i not "!start_now!"=="n" (
    echo.
    echo Starting platform...

    if "!SERVICES!"=="" (
        docker compose -f docker-compose.yml -f !COMPOSE_FILE! up -d
    ) else (
        docker compose -f docker-compose.yml -f !COMPOSE_FILE! -f docker-compose.optional.yml up -d
    )

    echo.
    echo Platform is starting!
    echo.
    echo Moodle takes 2-3 minutes to fully initialize on first run.
    echo.

    if "!MODE!"=="personal" (
        echo Open http://localhost:8080 in your browser
        start http://localhost:8080
    )
)

echo.
pause
endlocal
