#!/bin/bash
# ===========================================
# Educational Platform Setup Wizard
# ===========================================
# Interactive configuration based on available RAM
# ===========================================

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
BOLD='\033[1m'
NC='\033[0m'

# Platform directory
PLATFORM_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/edu-platform" && pwd)"
WIZARD_CONFIG="$PLATFORM_DIR/.wizard-config"

# ===========================================
# Banner
# ===========================================
print_banner() {
    clear
    echo -e "${CYAN}${BOLD}"
    cat << "EOF"
╔═══════════════════════════════════════════════════════════════╗
║                                                               ║
║           🎓  Educational Platform Setup Wizard              ║
║                                                               ║
║     Configure your platform based on available resources     ║
║                                                               ║
╚═══════════════════════════════════════════════════════════════╝
EOF
    echo -e "${NC}"
}

# ===========================================
# Detect System Resources
# ===========================================
detect_resources() {
    echo -e "${BLUE}ℹ${NC} Detecting system resources..."
    echo ""

    # Detect RAM (in GB)
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS
        TOTAL_RAM=$(sysctl hw.memsize | awk '{print int($2/1024/1024/1024)}')
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        # Linux
        TOTAL_RAM=$(free -g | awk '/^Mem:/{print $2}')
    else
        # Windows/Other - assume from Docker
        TOTAL_RAM=8
    fi

    # Detect CPU cores
    if command -v nproc &> /dev/null; then
        TOTAL_CORES=$(nproc)
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        TOTAL_CORES=$(sysctl -n hw.ncpu)
    else
        TOTAL_CORES=2
    fi

    # Detect disk space (GB)
    TOTAL_DISK=$(df -BG . | awk 'NR==2 {print $4}' | sed 's/G//')

    echo -e "  ${GREEN}✓${NC} RAM:        ${BOLD}${TOTAL_RAM} GB${NC}"
    echo -e "  ${GREEN}✓${NC} CPU Cores:  ${BOLD}${TOTAL_CORES}${NC}"
    echo -e "  ${GREEN}✓${NC} Disk Space: ${BOLD}${TOTAL_DISK} GB${NC}"
    echo ""
}

# ===========================================
# Show Service Profiles
# ===========================================
show_profiles() {
    echo -e "${CYAN}${BOLD}Available Configuration Profiles:${NC}"
    echo ""

    echo -e "${GREEN}1) MINIMAL${NC} - 4GB RAM minimum"
    echo "   Core services only: Moodle + PostgreSQL + Redis"
    echo "   Best for: Testing, small classes (<20 users)"
    echo ""

    echo -e "${GREEN}2) STANDARD${NC} - 8GB RAM recommended"
    echo "   Moodle + JupyterHub + Code Server + AI + Maxima"
    echo "   Best for: Full educational platform (50 users)"
    echo ""

    echo -e "${GREEN}3) ENHANCED${NC} - 16GB RAM recommended"
    echo "   Standard + RStudio + SageMath + Monitoring"
    echo "   Best for: Advanced courses, more users (100+)"
    echo ""

    echo -e "${GREEN}4) FULL${NC} - 32GB RAM recommended"
    echo "   Everything! Enhanced + GitLab + n8n + Analytics"
    echo "   Best for: Institution-wide deployment (500+ users)"
    echo ""

    echo -e "${GREEN}5) CUSTOM${NC} - Pick individual services"
    echo "   Choose exactly what you need"
    echo ""
}

# ===========================================
# Recommend Profile
# ===========================================
recommend_profile() {
    if [[ $TOTAL_RAM -lt 6 ]]; then
        RECOMMENDED="MINIMAL"
        echo -e "${YELLOW}⚠${NC}  Based on ${TOTAL_RAM}GB RAM, we recommend: ${BOLD}MINIMAL${NC}"
    elif [[ $TOTAL_RAM -lt 12 ]]; then
        RECOMMENDED="STANDARD"
        echo -e "${BLUE}ℹ${NC}  Based on ${TOTAL_RAM}GB RAM, we recommend: ${BOLD}STANDARD${NC}"
    elif [[ $TOTAL_RAM -lt 24 ]]; then
        RECOMMENDED="ENHANCED"
        echo -e "${GREEN}✓${NC} Based on ${TOTAL_RAM}GB RAM, we recommend: ${BOLD}ENHANCED${NC}"
    else
        RECOMMENDED="FULL"
        echo -e "${GREEN}✓${NC} Based on ${TOTAL_RAM}GB RAM, you can run: ${BOLD}FULL${NC}"
    fi
    echo ""
}

# ===========================================
# Core Services (Always Enabled)
# ===========================================
CORE_SERVICES=(
    "postgres:PostgreSQL Database:Required"
    "redis:Redis Cache:Required"
    "moodle:Moodle LMS:Required"
    "caddy:Reverse Proxy:Required"
)

# ===========================================
# Optional Services
# ===========================================
OPTIONAL_SERVICES=(
    "maxima:Maxima CAS (for STACK math):350MB:standard"
    "jupyterhub:JupyterHub (Python/R/Julia notebooks):2GB:standard"
    "code-server:VS Code in Browser:512MB:standard"
    "deepseek-proxy:AI Assistant API:128MB:standard"
    "rstudio:RStudio Server (R IDE):1GB:enhanced"
    "sagemath:SageMath (Advanced Math):2GB:enhanced"
    "grafana:Grafana (Monitoring Dashboard):256MB:enhanced"
    "prometheus:Prometheus (Metrics):512MB:enhanced"
    "gitea:Gitea (Git Server - lightweight):512MB:enhanced"
    "n8n:n8n (Workflow Automation):512MB:full"
    "portainer:Portainer (Docker Management):128MB:full"
)

# ===========================================
# Select Profile
# ===========================================
select_profile() {
    while true; do
        read -p "$(echo -e ${BOLD}Choose profile [1-5]:${NC} )" profile_choice

        case $profile_choice in
            1)
                SELECTED_PROFILE="minimal"
                ENABLED_SERVICES=()
                break
                ;;
            2)
                SELECTED_PROFILE="standard"
                ENABLED_SERVICES=("maxima" "jupyterhub" "code-server" "deepseek-proxy")
                break
                ;;
            3)
                SELECTED_PROFILE="enhanced"
                ENABLED_SERVICES=("maxima" "jupyterhub" "code-server" "deepseek-proxy" "rstudio" "sagemath" "grafana" "prometheus")
                break
                ;;
            4)
                SELECTED_PROFILE="full"
                ENABLED_SERVICES=("maxima" "jupyterhub" "code-server" "deepseek-proxy" "rstudio" "sagemath" "grafana" "prometheus" "gitea" "n8n" "portainer")
                break
                ;;
            5)
                SELECTED_PROFILE="custom"
                select_custom_services
                break
                ;;
            *)
                echo -e "${RED}Invalid choice. Please enter 1-5.${NC}"
                ;;
        esac
    done
}

# ===========================================
# Custom Service Selection
# ===========================================
select_custom_services() {
    echo ""
    echo -e "${CYAN}${BOLD}Select Optional Services:${NC}"
    echo ""

    ENABLED_SERVICES=()
    local total_memory=2048  # Base services (Moodle + DB + Redis)

    for service_def in "${OPTIONAL_SERVICES[@]}"; do
        IFS=':' read -r service name memory profile <<< "$service_def"

        echo -e "${BOLD}$name${NC} (${memory} RAM)"
        read -p "  Enable? [y/N] " -n 1 -r
        echo

        if [[ $REPLY =~ ^[Yy]$ ]]; then
            ENABLED_SERVICES+=("$service")
            # Extract number from memory string
            mem_num=$(echo $memory | grep -o '[0-9]*')
            total_memory=$((total_memory + mem_num))
        fi
    done

    echo ""
    echo -e "${BLUE}ℹ${NC}  Estimated RAM usage: ${BOLD}~${total_memory}MB${NC}"

    if [[ $total_memory -gt $((TOTAL_RAM * 1024)) ]]; then
        echo -e "${YELLOW}⚠${NC}  Warning: Selected services may exceed available RAM!"
        read -p "  Continue anyway? [y/N] " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            select_custom_services
        fi
    fi
}

# ===========================================
# Generate Configuration
# ===========================================
generate_config() {
    echo ""
    echo -e "${BLUE}ℹ${NC} Generating configuration..."

    # Create wizard config file
    cat > "$WIZARD_CONFIG" << EOF
# Educational Platform Wizard Configuration
# Generated: $(date)
PROFILE=$SELECTED_PROFILE
TOTAL_RAM=$TOTAL_RAM
TOTAL_CORES=$TOTAL_CORES
ENABLED_SERVICES="${ENABLED_SERVICES[*]}"
EOF

    # Generate Docker Compose profiles string
    COMPOSE_PROFILES=$(IFS=,; echo "${ENABLED_SERVICES[*]}")

    # Save to .env
    if [[ -f "$PLATFORM_DIR/.env" ]]; then
        # Update existing .env
        if grep -q "COMPOSE_PROFILES" "$PLATFORM_DIR/.env"; then
            sed -i.bak "s/COMPOSE_PROFILES=.*/COMPOSE_PROFILES=$COMPOSE_PROFILES/" "$PLATFORM_DIR/.env"
        else
            echo "COMPOSE_PROFILES=$COMPOSE_PROFILES" >> "$PLATFORM_DIR/.env"
        fi
    else
        echo "COMPOSE_PROFILES=$COMPOSE_PROFILES" >> "$PLATFORM_DIR/.env"
    fi

    echo -e "${GREEN}✓${NC} Configuration saved"
}

# ===========================================
# Show Summary
# ===========================================
show_summary() {
    echo ""
    echo -e "${GREEN}${BOLD}═══════════════════════════════════════════════════════${NC}"
    echo -e "${GREEN}${BOLD}  Configuration Summary${NC}"
    echo -e "${GREEN}${BOLD}═══════════════════════════════════════════════════════${NC}"
    echo ""
    echo -e "  ${BOLD}Profile:${NC} $SELECTED_PROFILE"
    echo -e "  ${BOLD}System RAM:${NC} ${TOTAL_RAM}GB"
    echo ""
    echo -e "  ${BOLD}Core Services (Always Enabled):${NC}"
    echo "    • PostgreSQL Database"
    echo "    • Redis Cache"
    echo "    • Moodle LMS"
    echo "    • Caddy Reverse Proxy"
    echo ""

    if [[ ${#ENABLED_SERVICES[@]} -gt 0 ]]; then
        echo -e "  ${BOLD}Optional Services (Enabled):${NC}"
        for service in "${ENABLED_SERVICES[@]}"; do
            # Find service name
            for service_def in "${OPTIONAL_SERVICES[@]}"; do
                IFS=':' read -r svc_id name memory profile <<< "$service_def"
                if [[ "$svc_id" == "$service" ]]; then
                    echo "    • $name"
                    break
                fi
            done
        done
    else
        echo -e "  ${BOLD}Optional Services:${NC} None"
    fi

    echo ""
    echo -e "${GREEN}═══════════════════════════════════════════════════════${NC}"
    echo ""
}

# ===========================================
# Create Service Access Info
# ===========================================
create_access_info() {
    local ACCESS_FILE="$PLATFORM_DIR/SERVICES.md"

    cat > "$ACCESS_FILE" << 'EOF'
# 🎓 Enabled Services

## Core Services

| Service | URL (Dev) | URL (Production) | Description |
|---------|-----------|------------------|-------------|
| Moodle LMS | http://localhost:8080 | https://learn.DOMAIN | Learning Management System |
| PostgreSQL | localhost:5432 | Internal | Database |
| Redis | localhost:6379 | Internal | Cache |

## Optional Services

EOF

    # Add enabled optional services
    for service in "${ENABLED_SERVICES[@]}"; do
        case $service in
            maxima)
                echo "| Maxima CAS | Internal:8765 | Internal | Computer Algebra System |" >> "$ACCESS_FILE"
                ;;
            jupyterhub)
                echo "| JupyterHub | http://localhost:8000 | https://jupyter.DOMAIN | Multi-user Notebooks |" >> "$ACCESS_FILE"
                ;;
            code-server)
                echo "| VS Code | http://localhost:8443 | https://code.DOMAIN | Code Server |" >> "$ACCESS_FILE"
                ;;
            deepseek-proxy)
                echo "| AI Assistant | http://localhost:8001/docs | https://ai.DOMAIN | AI API |" >> "$ACCESS_FILE"
                ;;
            rstudio)
                echo "| RStudio | http://localhost:8787 | https://rstudio.DOMAIN | R IDE |" >> "$ACCESS_FILE"
                ;;
            sagemath)
                echo "| SageMath | http://localhost:8888 | https://sage.DOMAIN | Advanced Math |" >> "$ACCESS_FILE"
                ;;
            grafana)
                echo "| Grafana | http://localhost:3000 | https://monitor.DOMAIN | Monitoring Dashboard |" >> "$ACCESS_FILE"
                ;;
            prometheus)
                echo "| Prometheus | http://localhost:9090 | Internal | Metrics Collection |" >> "$ACCESS_FILE"
                ;;
            gitea)
                echo "| Gitea | http://localhost:3001 | https://git.DOMAIN | Git Server |" >> "$ACCESS_FILE"
                ;;
            n8n)
                echo "| n8n | http://localhost:5678 | https://workflow.DOMAIN | Workflow Automation |" >> "$ACCESS_FILE"
                ;;
            portainer)
                echo "| Portainer | http://localhost:9000 | https://docker.DOMAIN | Docker Management |" >> "$ACCESS_FILE"
                ;;
        esac
    done

    echo "" >> "$ACCESS_FILE"
    echo "📌 **Credentials**: See \`CREDENTIALS.txt\` for login information" >> "$ACCESS_FILE"
}

# ===========================================
# Main Execution
# ===========================================
main() {
    print_banner

    detect_resources
    show_profiles
    recommend_profile

    select_profile

    generate_config
    show_summary
    create_access_info

    echo -e "${GREEN}✓${NC} Setup wizard complete!"
    echo ""
    echo "Next steps:"
    echo "  1. Run ${CYAN}./start.sh${NC} to start your platform"
    echo "  2. Check ${CYAN}edu-platform/SERVICES.md${NC} for access URLs"
    echo "  3. See ${CYAN}edu-platform/CREDENTIALS.txt${NC} for login info"
    echo ""

    read -p "Start platform now? [Y/n] " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Nn]$ ]]; then
        cd "$(dirname "${BASH_SOURCE[0]}")"
        ./start.sh
    fi
}

# Run wizard
main "$@"
