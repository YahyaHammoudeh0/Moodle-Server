@echo off
REM ===========================================
REM Educational Platform Setup Wizard (Windows)
REM ===========================================
REM Interactive configuration based on available RAM
REM ===========================================

setlocal enabledelayedexpansion

REM Colors (Windows 10+)
set "BLUE=[94m"
set "GREEN=[92m"
set "YELLOW=[93m"
set "CYAN=[96m"
set "MAGENTA=[95m"
set "RED=[91m"
set "BOLD=[1m"
set "NC=[0m"

REM Platform directory
set "PLATFORM_DIR=%~dp0edu-platform"
set "WIZARD_CONFIG=%PLATFORM_DIR%\.wizard-config"

REM ===========================================
REM Banner
REM ===========================================
cls
echo.
echo %CYAN%%BOLD%╔═══════════════════════════════════════════════════════════════╗%NC%
echo %CYAN%%BOLD%║                                                               ║%NC%
echo %CYAN%%BOLD%║           🎓  Educational Platform Setup Wizard              ║%NC%
echo %CYAN%%BOLD%║                                                               ║%NC%
echo %CYAN%%BOLD%║     Configure your platform based on available resources     ║%NC%
echo %CYAN%%BOLD%║                                                               ║%NC%
echo %CYAN%%BOLD%╚═══════════════════════════════════════════════════════════════╝%NC%
echo.

REM ===========================================
REM Detect System Resources
REM ===========================================
echo %BLUE%ℹ%NC% Detecting system resources...
echo.

REM Detect RAM (Windows)
for /f "tokens=2 delims==" %%i in ('wmic computersystem get TotalPhysicalMemory /value ^| find "="') do set TOTAL_RAM_BYTES=%%i
set /a TOTAL_RAM=!TOTAL_RAM_BYTES:~0,-9!

REM Detect CPU cores
for /f "tokens=2 delims==" %%i in ('wmic cpu get NumberOfLogicalProcessors /value ^| find "="') do set TOTAL_CORES=%%i

REM Detect disk space (GB)
for /f "tokens=3" %%i in ('dir /-c ^| find "bytes free"') do set DISK_BYTES=%%i
set DISK_BYTES=!DISK_BYTES:,=!
set /a TOTAL_DISK=!DISK_BYTES:~0,-9!

echo   %GREEN%✓%NC% RAM:        %BOLD%!TOTAL_RAM! GB%NC%
echo   %GREEN%✓%NC% CPU Cores:  %BOLD%!TOTAL_CORES!%NC%
echo   %GREEN%✓%NC% Disk Space: %BOLD%!TOTAL_DISK! GB%NC%
echo.

REM ===========================================
REM Show Service Profiles
REM ===========================================
echo %CYAN%%BOLD%Available Configuration Profiles:%NC%
echo.

echo %GREEN%1^) MINIMAL%NC% - 4GB RAM minimum
echo    Core services only: Moodle + PostgreSQL + Redis
echo    Best for: Testing, small classes (^<20 users^)
echo.

echo %GREEN%2^) STANDARD%NC% - 8GB RAM recommended
echo    Moodle + JupyterHub + Code Server + AI + Maxima
echo    Best for: Full educational platform (50 users^)
echo.

echo %GREEN%3^) ENHANCED%NC% - 16GB RAM recommended
echo    Standard + RStudio + SageMath + Monitoring
echo    Best for: Advanced courses, more users (100+^)
echo.

echo %GREEN%4^) FULL%NC% - 32GB RAM recommended
echo    Everything! Enhanced + GitLab + n8n + Analytics
echo    Best for: Institution-wide deployment (500+ users^)
echo.

echo %GREEN%5^) CUSTOM%NC% - Pick individual services
echo    Choose exactly what you need
echo.

REM ===========================================
REM Recommend Profile
REM ===========================================
if !TOTAL_RAM! LSS 6 (
    set RECOMMENDED=MINIMAL
    echo %YELLOW%⚠%NC%  Based on !TOTAL_RAM!GB RAM, we recommend: %BOLD%MINIMAL%NC%
) else if !TOTAL_RAM! LSS 12 (
    set RECOMMENDED=STANDARD
    echo %BLUE%ℹ%NC%  Based on !TOTAL_RAM!GB RAM, we recommend: %BOLD%STANDARD%NC%
) else if !TOTAL_RAM! LSS 24 (
    set RECOMMENDED=ENHANCED
    echo %GREEN%✓%NC% Based on !TOTAL_RAM!GB RAM, we recommend: %BOLD%ENHANCED%NC%
) else (
    set RECOMMENDED=FULL
    echo %GREEN%✓%NC% Based on !TOTAL_RAM!GB RAM, you can run: %BOLD%FULL%NC%
)
echo.

REM ===========================================
REM Select Profile
REM ===========================================
:SELECT_PROFILE
set /p profile_choice="%BOLD%Choose profile [1-5]:%NC% "

if "%profile_choice%"=="1" (
    set SELECTED_PROFILE=minimal
    set "ENABLED_SERVICES="
    goto CONFIG_DONE
) else if "%profile_choice%"=="2" (
    set SELECTED_PROFILE=standard
    set "ENABLED_SERVICES=maxima jupyterhub code-server deepseek-proxy"
    goto CONFIG_DONE
) else if "%profile_choice%"=="3" (
    set SELECTED_PROFILE=enhanced
    set "ENABLED_SERVICES=maxima jupyterhub code-server deepseek-proxy rstudio sagemath grafana prometheus"
    goto CONFIG_DONE
) else if "%profile_choice%"=="4" (
    set SELECTED_PROFILE=full
    set "ENABLED_SERVICES=maxima jupyterhub code-server deepseek-proxy rstudio sagemath grafana prometheus gitea n8n portainer"
    goto CONFIG_DONE
) else if "%profile_choice%"=="5" (
    set SELECTED_PROFILE=custom
    goto CUSTOM_SELECTION
) else (
    echo %RED%Invalid choice. Please enter 1-5.%NC%
    goto SELECT_PROFILE
)

REM ===========================================
REM Custom Service Selection
REM ===========================================
:CUSTOM_SELECTION
echo.
echo %CYAN%%BOLD%Select Optional Services:%NC%
echo.

set "ENABLED_SERVICES="
set /a total_memory=2048

REM Maxima
echo %BOLD%Maxima CAS (for STACK math^)%NC% (350MB RAM^)
set /p enable_maxima="  Enable? [y/N] "
if /i "!enable_maxima!"=="y" (
    set "ENABLED_SERVICES=!ENABLED_SERVICES! maxima"
    set /a total_memory+=350
)

REM JupyterHub
echo %BOLD%JupyterHub (Python/R/Julia notebooks^)%NC% (2GB RAM^)
set /p enable_jupyter="  Enable? [y/N] "
if /i "!enable_jupyter!"=="y" (
    set "ENABLED_SERVICES=!ENABLED_SERVICES! jupyterhub"
    set /a total_memory+=2048
)

REM Code Server
echo %BOLD%VS Code in Browser%NC% (512MB RAM^)
set /p enable_code="  Enable? [y/N] "
if /i "!enable_code!"=="y" (
    set "ENABLED_SERVICES=!ENABLED_SERVICES! code-server"
    set /a total_memory+=512
)

REM AI Assistant
echo %BOLD%AI Assistant API%NC% (128MB RAM^)
set /p enable_ai="  Enable? [y/N] "
if /i "!enable_ai!"=="y" (
    set "ENABLED_SERVICES=!ENABLED_SERVICES! deepseek-proxy"
    set /a total_memory+=128
)

REM RStudio
echo %BOLD%RStudio Server (R IDE^)%NC% (1GB RAM^)
set /p enable_rstudio="  Enable? [y/N] "
if /i "!enable_rstudio!"=="y" (
    set "ENABLED_SERVICES=!ENABLED_SERVICES! rstudio"
    set /a total_memory+=1024
)

REM SageMath
echo %BOLD%SageMath (Advanced Math^)%NC% (2GB RAM^)
set /p enable_sage="  Enable? [y/N] "
if /i "!enable_sage!"=="y" (
    set "ENABLED_SERVICES=!ENABLED_SERVICES! sagemath"
    set /a total_memory+=2048
)

REM Grafana
echo %BOLD%Grafana (Monitoring Dashboard^)%NC% (256MB RAM^)
set /p enable_grafana="  Enable? [y/N] "
if /i "!enable_grafana!"=="y" (
    set "ENABLED_SERVICES=!ENABLED_SERVICES! grafana"
    set /a total_memory+=256
)

REM Prometheus
echo %BOLD%Prometheus (Metrics^)%NC% (512MB RAM^)
set /p enable_prometheus="  Enable? [y/N] "
if /i "!enable_prometheus!"=="y" (
    set "ENABLED_SERVICES=!ENABLED_SERVICES! prometheus"
    set /a total_memory+=512
)

REM Gitea
echo %BOLD%Gitea (Git Server^)%NC% (512MB RAM^)
set /p enable_gitea="  Enable? [y/N] "
if /i "!enable_gitea!"=="y" (
    set "ENABLED_SERVICES=!ENABLED_SERVICES! gitea"
    set /a total_memory+=512
)

REM n8n
echo %BOLD%n8n (Workflow Automation^)%NC% (512MB RAM^)
set /p enable_n8n="  Enable? [y/N] "
if /i "!enable_n8n!"=="y" (
    set "ENABLED_SERVICES=!ENABLED_SERVICES! n8n"
    set /a total_memory+=512
)

REM Portainer
echo %BOLD%Portainer (Docker Management^)%NC% (128MB RAM^)
set /p enable_portainer="  Enable? [y/N] "
if /i "!enable_portainer!"=="y" (
    set "ENABLED_SERVICES=!ENABLED_SERVICES! portainer"
    set /a total_memory+=128
)

echo.
echo %BLUE%ℹ%NC%  Estimated RAM usage: %BOLD%~!total_memory!MB%NC%

set /a ram_mb=!TOTAL_RAM!*1024
if !total_memory! GTR !ram_mb! (
    echo %YELLOW%⚠%NC%  Warning: Selected services may exceed available RAM!
    set /p continue_anyway="  Continue anyway? [y/N] "
    if /i not "!continue_anyway!"=="y" goto CUSTOM_SELECTION
)

REM ===========================================
REM Generate Configuration
REM ===========================================
:CONFIG_DONE
echo.
echo %BLUE%ℹ%NC% Generating configuration...

REM Create wizard config file
(
    echo # Educational Platform Wizard Configuration
    echo # Generated: %date% %time%
    echo PROFILE=!SELECTED_PROFILE!
    echo TOTAL_RAM=!TOTAL_RAM!
    echo TOTAL_CORES=!TOTAL_CORES!
    echo ENABLED_SERVICES=!ENABLED_SERVICES!
) > "%WIZARD_CONFIG%"

REM Convert space-separated to comma-separated
set "COMPOSE_PROFILES=!ENABLED_SERVICES: =,!"

REM Update or create .env
if exist "%PLATFORM_DIR%\.env" (
    REM Update existing .env
    powershell -Command "(Get-Content '%PLATFORM_DIR%\.env') -replace '^COMPOSE_PROFILES=.*', 'COMPOSE_PROFILES=!COMPOSE_PROFILES!' | Set-Content '%PLATFORM_DIR%\.env'"
) else (
    echo COMPOSE_PROFILES=!COMPOSE_PROFILES! >> "%PLATFORM_DIR%\.env"
)

echo %GREEN%✓%NC% Configuration saved

REM ===========================================
REM Show Summary
REM ===========================================
echo.
echo %GREEN%%BOLD%═══════════════════════════════════════════════════════%NC%
echo %GREEN%%BOLD%  Configuration Summary%NC%
echo %GREEN%%BOLD%═══════════════════════════════════════════════════════%NC%
echo.
echo   %BOLD%Profile:%NC% !SELECTED_PROFILE!
echo   %BOLD%System RAM:%NC% !TOTAL_RAM!GB
echo.
echo   %BOLD%Core Services (Always Enabled^):%NC%
echo     • PostgreSQL Database
echo     • Redis Cache
echo     • Moodle LMS
echo     • Caddy Reverse Proxy
echo.

if not "!ENABLED_SERVICES!"=="" (
    echo   %BOLD%Optional Services (Enabled^):%NC%
    for %%s in (!ENABLED_SERVICES!) do (
        if "%%s"=="maxima" echo     • Maxima CAS (for STACK math^)
        if "%%s"=="jupyterhub" echo     • JupyterHub (Python/R/Julia notebooks^)
        if "%%s"=="code-server" echo     • VS Code in Browser
        if "%%s"=="deepseek-proxy" echo     • AI Assistant API
        if "%%s"=="rstudio" echo     • RStudio Server (R IDE^)
        if "%%s"=="sagemath" echo     • SageMath (Advanced Math^)
        if "%%s"=="grafana" echo     • Grafana (Monitoring Dashboard^)
        if "%%s"=="prometheus" echo     • Prometheus (Metrics^)
        if "%%s"=="gitea" echo     • Gitea (Git Server^)
        if "%%s"=="n8n" echo     • n8n (Workflow Automation^)
        if "%%s"=="portainer" echo     • Portainer (Docker Management^)
    )
) else (
    echo   %BOLD%Optional Services:%NC% None
)

echo.
echo %GREEN%═══════════════════════════════════════════════════════%NC%
echo.

REM ===========================================
REM Create Service Access Info
REM ===========================================
(
    echo # 🎓 Enabled Services
    echo.
    echo ## Core Services
    echo.
    echo ^| Service ^| URL (Dev^) ^| URL (Production^) ^| Description ^|
    echo ^|^---------^|^-----------^|^------------------^|^-------------^|
    echo ^| Moodle LMS ^| http://localhost:8080 ^| https://learn.DOMAIN ^| Learning Management System ^|
    echo ^| PostgreSQL ^| localhost:5432 ^| Internal ^| Database ^|
    echo ^| Redis ^| localhost:6379 ^| Internal ^| Cache ^|
    echo.
    echo ## Optional Services
    echo.
) > "%PLATFORM_DIR%\SERVICES.md"

REM Add enabled optional services
for %%s in (!ENABLED_SERVICES!) do (
    if "%%s"=="maxima" echo ^| Maxima CAS ^| Internal:8765 ^| Internal ^| Computer Algebra System ^| >> "%PLATFORM_DIR%\SERVICES.md"
    if "%%s"=="jupyterhub" echo ^| JupyterHub ^| http://localhost:8000 ^| https://jupyter.DOMAIN ^| Multi-user Notebooks ^| >> "%PLATFORM_DIR%\SERVICES.md"
    if "%%s"=="code-server" echo ^| VS Code ^| http://localhost:8443 ^| https://code.DOMAIN ^| Code Server ^| >> "%PLATFORM_DIR%\SERVICES.md"
    if "%%s"=="deepseek-proxy" echo ^| AI Assistant ^| http://localhost:8001/docs ^| https://ai.DOMAIN ^| AI API ^| >> "%PLATFORM_DIR%\SERVICES.md"
    if "%%s"=="rstudio" echo ^| RStudio ^| http://localhost:8787 ^| https://rstudio.DOMAIN ^| R IDE ^| >> "%PLATFORM_DIR%\SERVICES.md"
    if "%%s"=="sagemath" echo ^| SageMath ^| http://localhost:8888 ^| https://sage.DOMAIN ^| Advanced Math ^| >> "%PLATFORM_DIR%\SERVICES.md"
    if "%%s"=="grafana" echo ^| Grafana ^| http://localhost:3000 ^| https://monitor.DOMAIN ^| Monitoring Dashboard ^| >> "%PLATFORM_DIR%\SERVICES.md"
    if "%%s"=="prometheus" echo ^| Prometheus ^| http://localhost:9090 ^| Internal ^| Metrics Collection ^| >> "%PLATFORM_DIR%\SERVICES.md"
    if "%%s"=="gitea" echo ^| Gitea ^| http://localhost:3001 ^| https://git.DOMAIN ^| Git Server ^| >> "%PLATFORM_DIR%\SERVICES.md"
    if "%%s"=="n8n" echo ^| n8n ^| http://localhost:5678 ^| https://workflow.DOMAIN ^| Workflow Automation ^| >> "%PLATFORM_DIR%\SERVICES.md"
    if "%%s"=="portainer" echo ^| Portainer ^| http://localhost:9000 ^| https://docker.DOMAIN ^| Docker Management ^| >> "%PLATFORM_DIR%\SERVICES.md"
)

(
    echo.
    echo 📌 **Credentials**: See `CREDENTIALS.txt` for login information
) >> "%PLATFORM_DIR%\SERVICES.md"

REM ===========================================
REM Completion
REM ===========================================
echo %GREEN%✓%NC% Setup wizard complete!
echo.
echo Next steps:
echo   1. Run %CYAN%start.bat%NC% to start your platform
echo   2. Check %CYAN%edu-platform\SERVICES.md%NC% for access URLs
echo   3. See %CYAN%edu-platform\CREDENTIALS.txt%NC% for login info
echo.

set /p start_now="Start platform now? [Y/n] "
if /i not "!start_now!"=="n" (
    cd "%~dp0"
    call start.bat
)

endlocal
