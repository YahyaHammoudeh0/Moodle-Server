# ===========================================
# Educational Platform Setup Wizard (PowerShell)
# ===========================================
# Interactive configuration based on available RAM
# Run with: powershell -ExecutionPolicy Bypass -File wizard.ps1
# ===========================================

# Enable colors
$Host.UI.RawUI.ForegroundColor = "White"

# Platform directory
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$PlatformDir = Join-Path $ScriptDir "edu-platform"
$WizardConfig = Join-Path $PlatformDir ".wizard-config"

# Colors
function Write-Info { param($msg) Write-Host "ℹ $msg" -ForegroundColor Blue }
function Write-Success { param($msg) Write-Host "✓ $msg" -ForegroundColor Green }
function Write-Warning { param($msg) Write-Host "⚠ $msg" -ForegroundColor Yellow }
function Write-Error { param($msg) Write-Host "✗ $msg" -ForegroundColor Red }
function Write-Header { param($msg) Write-Host $msg -ForegroundColor Cyan -BackgroundColor Black }

# ===========================================
# Banner
# ===========================================
Clear-Host
Write-Host ""
Write-Host "╔═══════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║                                                               ║" -ForegroundColor Cyan
Write-Host "║           🎓  Educational Platform Setup Wizard              ║" -ForegroundColor Cyan
Write-Host "║                                                               ║" -ForegroundColor Cyan
Write-Host "║     Configure your platform based on available resources     ║" -ForegroundColor Cyan
Write-Host "║                                                               ║" -ForegroundColor Cyan
Write-Host "╔═══════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host ""

# ===========================================
# Detect System Resources
# ===========================================
Write-Info "Detecting system resources..."
Write-Host ""

# Detect RAM (GB)
$TotalRAMBytes = (Get-CimInstance Win32_ComputerSystem).TotalPhysicalMemory
$TotalRAM = [Math]::Round($TotalRAMBytes / 1GB)

# Detect CPU cores
$TotalCores = (Get-CimInstance Win32_Processor).NumberOfLogicalProcessors

# Detect disk space (GB)
$Drive = (Get-Location).Drive
$TotalDisk = [Math]::Round((Get-PSDrive $Drive.Name).Free / 1GB)

Write-Success "RAM:        $TotalRAM GB"
Write-Success "CPU Cores:  $TotalCores"
Write-Success "Disk Space: $TotalDisk GB"
Write-Host ""

# ===========================================
# Show Service Profiles
# ===========================================
Write-Header "Available Configuration Profiles:"
Write-Host ""

Write-Host "1) MINIMAL" -ForegroundColor Green -NoNewline
Write-Host " - 4GB RAM minimum"
Write-Host "   Core services only: Moodle + PostgreSQL + Redis"
Write-Host "   Best for: Testing, small classes (<20 users)"
Write-Host ""

Write-Host "2) STANDARD" -ForegroundColor Green -NoNewline
Write-Host " - 8GB RAM recommended"
Write-Host "   Moodle + JupyterHub + Code Server + AI + Maxima"
Write-Host "   Best for: Full educational platform (50 users)"
Write-Host ""

Write-Host "3) ENHANCED" -ForegroundColor Green -NoNewline
Write-Host " - 16GB RAM recommended"
Write-Host "   Standard + RStudio + SageMath + Monitoring"
Write-Host "   Best for: Advanced courses, more users (100+)"
Write-Host ""

Write-Host "4) FULL" -ForegroundColor Green -NoNewline
Write-Host " - 32GB RAM recommended"
Write-Host "   Everything! Enhanced + GitLab + n8n + Analytics"
Write-Host "   Best for: Institution-wide deployment (500+ users)"
Write-Host ""

Write-Host "5) CUSTOM" -ForegroundColor Green -NoNewline
Write-Host " - Pick individual services"
Write-Host "   Choose exactly what you need"
Write-Host ""

# ===========================================
# Recommend Profile
# ===========================================
if ($TotalRAM -lt 6) {
    $Recommended = "MINIMAL"
    Write-Warning "Based on ${TotalRAM}GB RAM, we recommend: MINIMAL"
} elseif ($TotalRAM -lt 12) {
    $Recommended = "STANDARD"
    Write-Info "Based on ${TotalRAM}GB RAM, we recommend: STANDARD"
} elseif ($TotalRAM -lt 24) {
    $Recommended = "ENHANCED"
    Write-Success "Based on ${TotalRAM}GB RAM, we recommend: ENHANCED"
} else {
    $Recommended = "FULL"
    Write-Success "Based on ${TotalRAM}GB RAM, you can run: FULL"
}
Write-Host ""

# ===========================================
# Select Profile
# ===========================================
$ProfileChoice = Read-Host "Choose profile [1-5]"

switch ($ProfileChoice) {
    "1" {
        $SelectedProfile = "minimal"
        $EnabledServices = @()
    }
    "2" {
        $SelectedProfile = "standard"
        $EnabledServices = @("maxima", "jupyterhub", "code-server", "deepseek-proxy")
    }
    "3" {
        $SelectedProfile = "enhanced"
        $EnabledServices = @("maxima", "jupyterhub", "code-server", "deepseek-proxy", "rstudio", "sagemath", "grafana", "prometheus")
    }
    "4" {
        $SelectedProfile = "full"
        $EnabledServices = @("maxima", "jupyterhub", "code-server", "deepseek-proxy", "rstudio", "sagemath", "grafana", "prometheus", "gitea", "n8n", "portainer")
    }
    "5" {
        $SelectedProfile = "custom"
        $EnabledServices = @()

        Write-Host ""
        Write-Header "Select Optional Services:"
        Write-Host ""

        # Service definitions: name, memory (MB), description
        $Services = @(
            @{Name="maxima"; Memory=350; Desc="Maxima CAS (for STACK math)"},
            @{Name="jupyterhub"; Memory=2048; Desc="JupyterHub (Python/R/Julia notebooks)"},
            @{Name="code-server"; Memory=512; Desc="VS Code in Browser"},
            @{Name="deepseek-proxy"; Memory=128; Desc="AI Assistant API"},
            @{Name="rstudio"; Memory=1024; Desc="RStudio Server (R IDE)"},
            @{Name="sagemath"; Memory=2048; Desc="SageMath (Advanced Math)"},
            @{Name="grafana"; Memory=256; Desc="Grafana (Monitoring Dashboard)"},
            @{Name="prometheus"; Memory=512; Desc="Prometheus (Metrics)"},
            @{Name="gitea"; Memory=512; Desc="Gitea (Git Server)"},
            @{Name="n8n"; Memory=512; Desc="n8n (Workflow Automation)"},
            @{Name="portainer"; Memory=128; Desc="Portainer (Docker Management)"}
        )

        $TotalMemory = 2048  # Base services

        foreach ($Service in $Services) {
            Write-Host "$($Service.Desc)" -NoNewline
            Write-Host " ($($Service.Memory)MB RAM)"
            $Enable = Read-Host "  Enable? [y/N]"

            if ($Enable -ieq "y") {
                $EnabledServices += $Service.Name
                $TotalMemory += $Service.Memory
            }
        }

        Write-Host ""
        Write-Info "Estimated RAM usage: ~${TotalMemory}MB"

        if ($TotalMemory -gt ($TotalRAM * 1024)) {
            Write-Warning "Selected services may exceed available RAM!"
            $Continue = Read-Host "  Continue anyway? [y/N]"
            if ($Continue -ine "y") {
                Write-Error "Please re-run wizard and select fewer services"
                exit 1
            }
        }
    }
    default {
        Write-Error "Invalid choice. Please run wizard again and enter 1-5."
        exit 1
    }
}

# ===========================================
# Generate Configuration
# ===========================================
Write-Host ""
Write-Info "Generating configuration..."

# Create wizard config file
$ConfigContent = @"
# Educational Platform Wizard Configuration
# Generated: $(Get-Date)
PROFILE=$SelectedProfile
TOTAL_RAM=$TotalRAM
TOTAL_CORES=$TotalCores
ENABLED_SERVICES=$($EnabledServices -join ' ')
"@

$ConfigContent | Out-File -FilePath $WizardConfig -Encoding UTF8

# Convert to comma-separated for Docker Compose
$ComposeProfiles = $EnabledServices -join ','

# Update or create .env
$EnvFile = Join-Path $PlatformDir ".env"
if (Test-Path $EnvFile) {
    $EnvContent = Get-Content $EnvFile
    if ($EnvContent -match "^COMPOSE_PROFILES=") {
        $EnvContent = $EnvContent -replace "^COMPOSE_PROFILES=.*", "COMPOSE_PROFILES=$ComposeProfiles"
    } else {
        $EnvContent += "COMPOSE_PROFILES=$ComposeProfiles"
    }
    $EnvContent | Out-File -FilePath $EnvFile -Encoding UTF8
} else {
    "COMPOSE_PROFILES=$ComposeProfiles" | Out-File -FilePath $EnvFile -Encoding UTF8
}

Write-Success "Configuration saved"

# ===========================================
# Show Summary
# ===========================================
Write-Host ""
Write-Host "═══════════════════════════════════════════════════════" -ForegroundColor Green
Write-Host "  Configuration Summary" -ForegroundColor Green
Write-Host "═══════════════════════════════════════════════════════" -ForegroundColor Green
Write-Host ""
Write-Host "  Profile: $SelectedProfile"
Write-Host "  System RAM: ${TotalRAM}GB"
Write-Host ""
Write-Host "  Core Services (Always Enabled):"
Write-Host "    • PostgreSQL Database"
Write-Host "    • Redis Cache"
Write-Host "    • Moodle LMS"
Write-Host "    • Caddy Reverse Proxy"
Write-Host ""

if ($EnabledServices.Count -gt 0) {
    Write-Host "  Optional Services (Enabled):"
    foreach ($Service in $EnabledServices) {
        switch ($Service) {
            "maxima" { Write-Host "    • Maxima CAS (for STACK math)" }
            "jupyterhub" { Write-Host "    • JupyterHub (Python/R/Julia notebooks)" }
            "code-server" { Write-Host "    • VS Code in Browser" }
            "deepseek-proxy" { Write-Host "    • AI Assistant API" }
            "rstudio" { Write-Host "    • RStudio Server (R IDE)" }
            "sagemath" { Write-Host "    • SageMath (Advanced Math)" }
            "grafana" { Write-Host "    • Grafana (Monitoring Dashboard)" }
            "prometheus" { Write-Host "    • Prometheus (Metrics)" }
            "gitea" { Write-Host "    • Gitea (Git Server)" }
            "n8n" { Write-Host "    • n8n (Workflow Automation)" }
            "portainer" { Write-Host "    • Portainer (Docker Management)" }
        }
    }
} else {
    Write-Host "  Optional Services: None"
}

Write-Host ""
Write-Host "═══════════════════════════════════════════════════════" -ForegroundColor Green
Write-Host ""

# ===========================================
# Create Service Access Info
# ===========================================
$ServicesFile = Join-Path $PlatformDir "SERVICES.md"
$ServicesContent = @"
# 🎓 Enabled Services

## Core Services

| Service | URL (Dev) | URL (Production) | Description |
|---------|-----------|------------------|-------------|
| Moodle LMS | http://localhost:8080 | https://learn.DOMAIN | Learning Management System |
| PostgreSQL | localhost:5432 | Internal | Database |
| Redis | localhost:6379 | Internal | Cache |

## Optional Services

"@

foreach ($Service in $EnabledServices) {
    switch ($Service) {
        "maxima" { $ServicesContent += "| Maxima CAS | Internal:8765 | Internal | Computer Algebra System |`n" }
        "jupyterhub" { $ServicesContent += "| JupyterHub | http://localhost:8000 | https://jupyter.DOMAIN | Multi-user Notebooks |`n" }
        "code-server" { $ServicesContent += "| VS Code | http://localhost:8443 | https://code.DOMAIN | Code Server |`n" }
        "deepseek-proxy" { $ServicesContent += "| AI Assistant | http://localhost:8001/docs | https://ai.DOMAIN | AI API |`n" }
        "rstudio" { $ServicesContent += "| RStudio | http://localhost:8787 | https://rstudio.DOMAIN | R IDE |`n" }
        "sagemath" { $ServicesContent += "| SageMath | http://localhost:8888 | https://sage.DOMAIN | Advanced Math |`n" }
        "grafana" { $ServicesContent += "| Grafana | http://localhost:3000 | https://monitor.DOMAIN | Monitoring Dashboard |`n" }
        "prometheus" { $ServicesContent += "| Prometheus | http://localhost:9090 | Internal | Metrics Collection |`n" }
        "gitea" { $ServicesContent += "| Gitea | http://localhost:3001 | https://git.DOMAIN | Git Server |`n" }
        "n8n" { $ServicesContent += "| n8n | http://localhost:5678 | https://workflow.DOMAIN | Workflow Automation |`n" }
        "portainer" { $ServicesContent += "| Portainer | http://localhost:9000 | https://docker.DOMAIN | Docker Management |`n" }
    }
}

$ServicesContent += @"

📌 **Credentials**: See ``CREDENTIALS.txt`` for login information
"@

$ServicesContent | Out-File -FilePath $ServicesFile -Encoding UTF8

# ===========================================
# Completion
# ===========================================
Write-Success "Setup wizard complete!"
Write-Host ""
Write-Host "Next steps:"
Write-Host "  1. Run" -NoNewline
Write-Host " start.bat" -ForegroundColor Cyan -NoNewline
Write-Host " to start your platform"
Write-Host "  2. Check" -NoNewline
Write-Host " edu-platform\SERVICES.md" -ForegroundColor Cyan -NoNewline
Write-Host " for access URLs"
Write-Host "  3. See" -NoNewline
Write-Host " edu-platform\CREDENTIALS.txt" -ForegroundColor Cyan -NoNewline
Write-Host " for login info"
Write-Host ""

$StartNow = Read-Host "Start platform now? [Y/n]"
if ($StartNow -ine "n") {
    Set-Location $ScriptDir
    & ".\start.bat"
}
