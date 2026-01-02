#!/bin/bash
# ===========================================
# Educational Platform Setup Wizard
# ===========================================
# Feature-rich installer with Personal and School modes
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
DIM='\033[2m'
NC='\033[0m'

# Platform directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLATFORM_DIR="$SCRIPT_DIR/edu-platform"

# ===========================================
# Banner
# ===========================================
print_banner() {
    clear
    echo -e "${CYAN}${BOLD}"
    cat << "EOF"

    ███████╗██████╗ ██╗   ██╗    ██████╗ ██╗      █████╗ ████████╗███████╗ ██████╗ ██████╗ ███╗   ███╗
    ██╔════╝██╔══██╗██║   ██║    ██╔══██╗██║     ██╔══██╗╚══██╔══╝██╔════╝██╔═══██╗██╔══██╗████╗ ████║
    █████╗  ██║  ██║██║   ██║    ██████╔╝██║     ███████║   ██║   █████╗  ██║   ██║██████╔╝██╔████╔██║
    ██╔══╝  ██║  ██║██║   ██║    ██╔═══╝ ██║     ██╔══██║   ██║   ██╔══╝  ██║   ██║██╔══██╗██║╚██╔╝██║
    ███████╗██████╔╝╚██████╔╝    ██║     ███████╗██║  ██║   ██║   ██║     ╚██████╔╝██║  ██║██║ ╚═╝ ██║
    ╚══════╝╚═════╝  ╚═════╝     ╚═╝     ╚══════╝╚═╝  ╚═╝   ╚═╝   ╚═╝      ╚═════╝ ╚═╝  ╚═╝╚═╝     ╚═╝

EOF
    echo -e "${NC}"
    echo -e "${DIM}    Moodle + JupyterHub + Code Server + AI + More${NC}"
    echo ""
}

# ===========================================
# Check Docker
# ===========================================
check_docker() {
    echo -e "${BLUE}Checking Docker...${NC}"

    if ! command -v docker &> /dev/null; then
        echo -e "${RED}Docker not installed!${NC}"
        echo ""
        echo "Install Docker first:"
        echo "  Fedora/RHEL: sudo dnf install docker docker-compose"
        echo "  Ubuntu/Debian: sudo apt install docker.io docker-compose"
        echo "  macOS: Install Docker Desktop from docker.com"
        echo "  Windows: Install Docker Desktop from docker.com"
        exit 1
    fi

    if ! docker info &> /dev/null; then
        echo -e "${YELLOW}Starting Docker...${NC}"
        sudo systemctl start docker 2>/dev/null || true
        sleep 2
    fi

    echo -e "${GREEN}Docker ready${NC}"
    echo ""
}

# ===========================================
# Detect Resources
# ===========================================
detect_resources() {
    # Detect RAM
    if [[ "$OSTYPE" == "darwin"* ]]; then
        TOTAL_RAM=$(sysctl hw.memsize | awk '{print int($2/1024/1024/1024)}')
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        TOTAL_RAM=$(free -g | awk '/^Mem:/{print $2}')
    else
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

    echo -e "${DIM}System: ${TOTAL_RAM}GB RAM, ${TOTAL_CORES} CPU cores${NC}"
    echo ""
}

# ===========================================
# Mode Selection
# ===========================================
select_mode() {
    echo -e "${BOLD}How will you use this platform?${NC}"
    echo ""
    echo -e "  ${GREEN}1)${NC} ${BOLD}Personal Learning${NC}"
    echo -e "     ${DIM}No passwords, instant access${NC}"
    echo -e "     ${DIM}Perfect for self-learners and developers${NC}"
    echo ""
    echo -e "  ${BLUE}2)${NC} ${BOLD}School / Institution${NC}"
    echo -e "     ${DIM}Full authentication with SSO${NC}"
    echo -e "     ${DIM}Domain, email, and user management${NC}"
    echo ""

    while true; do
        read -p "$(echo -e ${BOLD}Choose [1-2]:${NC} )" mode_choice
        case $mode_choice in
            1) MODE="personal"; break ;;
            2) MODE="school"; break ;;
            *) echo -e "${RED}Please enter 1 or 2${NC}" ;;
        esac
    done
    echo ""
}

# ===========================================
# Personal Mode Setup
# ===========================================
setup_personal() {
    echo -e "${GREEN}${BOLD}Personal Mode Selected${NC}"
    echo ""

    # Copy template
    cp "$PLATFORM_DIR/templates/.env.personal" "$PLATFORM_DIR/.env"

    # Simple username
    echo -e "${DIM}Your learning environment will be ready with:${NC}"
    echo -e "  - No passwords required"
    echo -e "  - Auto-login to all services"
    echo -e "  - Full admin access everywhere"
    echo ""

    COMPOSE_FILE="docker-compose.personal.yml"
}

# ===========================================
# School Mode Setup
# ===========================================
setup_school() {
    echo -e "${BLUE}${BOLD}School/Institution Mode Selected${NC}"
    echo ""

    # Domain
    echo -e "${BOLD}Enter your domain${NC} ${DIM}(e.g., myschool.edu)${NC}"
    read -p "> " DOMAIN
    DOMAIN=${DOMAIN:-localhost}
    echo ""

    # Admin email
    echo -e "${BOLD}Admin email${NC} ${DIM}(for SSL certificates and notifications)${NC}"
    read -p "> " ADMIN_EMAIL
    ADMIN_EMAIL=${ADMIN_EMAIL:-admin@$DOMAIN}
    echo ""

    # School name
    echo -e "${BOLD}School/Organization name${NC}"
    read -p "> " SCHOOL_NAME
    SCHOOL_NAME=${SCHOOL_NAME:-My School}
    echo ""

    # Generate secure passwords
    POSTGRES_PASS=$(openssl rand -base64 16 | tr -d "=+/")
    MOODLE_PASS=$(openssl rand -base64 12 | tr -d "=+/")
    JUPYTER_PASS=$(openssl rand -base64 12 | tr -d "=+/")
    CODE_PASS=$(openssl rand -base64 12 | tr -d "=+/")

    # Create .env from template
    cp "$PLATFORM_DIR/templates/.env.school" "$PLATFORM_DIR/.env"

    # Update values
    sed -i "s/DOMAIN=.*/DOMAIN=$DOMAIN/" "$PLATFORM_DIR/.env"
    sed -i "s/ADMIN_EMAIL=.*/ADMIN_EMAIL=$ADMIN_EMAIL/" "$PLATFORM_DIR/.env"
    sed -i "s/SCHOOL_NAME=.*/SCHOOL_NAME=$SCHOOL_NAME/" "$PLATFORM_DIR/.env"
    sed -i "s/POSTGRES_PASSWORD=.*/POSTGRES_PASSWORD=$POSTGRES_PASS/" "$PLATFORM_DIR/.env"
    sed -i "s/MOODLE_PASSWORD=.*/MOODLE_PASSWORD=$MOODLE_PASS/" "$PLATFORM_DIR/.env"
    sed -i "s/JUPYTERHUB_ADMIN_PASSWORD=.*/JUPYTERHUB_ADMIN_PASSWORD=$JUPYTER_PASS/" "$PLATFORM_DIR/.env"
    sed -i "s/CODE_SERVER_PASSWORD=.*/CODE_SERVER_PASSWORD=$CODE_PASS/" "$PLATFORM_DIR/.env"
    sed -i "s/RSTUDIO_PASSWORD=.*/RSTUDIO_PASSWORD=$CODE_PASS/" "$PLATFORM_DIR/.env"
    sed -i "s/SAGEMATH_TOKEN=.*/SAGEMATH_TOKEN=$CODE_PASS/" "$PLATFORM_DIR/.env"
    sed -i "s/GRAFANA_PASSWORD=.*/GRAFANA_PASSWORD=$CODE_PASS/" "$PLATFORM_DIR/.env"

    # Save credentials
    cat > "$PLATFORM_DIR/CREDENTIALS.txt" << EOF
============================================
  ADMIN CREDENTIALS - KEEP SECURE
============================================

Domain: $DOMAIN

MOODLE (https://learn.$DOMAIN)
  User: admin
  Pass: $MOODLE_PASS

JUPYTERHUB (https://jupyter.$DOMAIN)
  User: admin
  Pass: $JUPYTER_PASS

CODE SERVER (https://code.$DOMAIN)
  Pass: $CODE_PASS

DATABASE
  User: postgres
  Pass: $POSTGRES_PASS

============================================
EOF

    chmod 600 "$PLATFORM_DIR/CREDENTIALS.txt"
    echo -e "${GREEN}Credentials saved to CREDENTIALS.txt${NC}"
    echo ""

    COMPOSE_FILE="docker-compose.school.yml"
}

# ===========================================
# Service Selection
# ===========================================
select_services() {
    echo -e "${BOLD}Select services to install:${NC}"
    echo ""

    # Recommend based on RAM
    if [[ $TOTAL_RAM -lt 6 ]]; then
        echo -e "${YELLOW}With ${TOTAL_RAM}GB RAM, we recommend minimal services${NC}"
        PROFILE="minimal"
    elif [[ $TOTAL_RAM -lt 12 ]]; then
        echo -e "${GREEN}With ${TOTAL_RAM}GB RAM, standard services work well${NC}"
        PROFILE="standard"
    elif [[ $TOTAL_RAM -lt 24 ]]; then
        echo -e "${GREEN}With ${TOTAL_RAM}GB RAM, enhanced services available${NC}"
        PROFILE="enhanced"
    else
        echo -e "${GREEN}With ${TOTAL_RAM}GB RAM, all services available${NC}"
        PROFILE="full"
    fi
    echo ""

    echo -e "  ${GREEN}1)${NC} Minimal    ${DIM}(Moodle only - 4GB RAM)${NC}"
    echo -e "  ${GREEN}2)${NC} Standard   ${DIM}(+ Jupyter, Code Server, AI - 8GB RAM)${NC}"
    echo -e "  ${GREEN}3)${NC} Enhanced   ${DIM}(+ RStudio, SageMath, Monitoring - 16GB RAM)${NC}"
    echo -e "  ${GREEN}4)${NC} Full       ${DIM}(Everything! - 32GB RAM)${NC}"
    echo ""

    while true; do
        read -p "$(echo -e ${BOLD}Choose [1-4]:${NC} )" profile_choice
        case $profile_choice in
            1) SERVICES=""; break ;;
            2) SERVICES="maxima,jupyterhub,code-server"; break ;;
            3) SERVICES="maxima,jupyterhub,code-server,rstudio,sagemath,grafana,prometheus"; break ;;
            4) SERVICES="maxima,jupyterhub,code-server,rstudio,sagemath,grafana,prometheus,gitea,n8n,portainer"; break ;;
            *) echo -e "${RED}Please enter 1-4${NC}" ;;
        esac
    done

    # Update .env with selected services
    if grep -q "COMPOSE_PROFILES" "$PLATFORM_DIR/.env"; then
        sed -i "s/COMPOSE_PROFILES=.*/COMPOSE_PROFILES=$SERVICES/" "$PLATFORM_DIR/.env"
    else
        echo "COMPOSE_PROFILES=$SERVICES" >> "$PLATFORM_DIR/.env"
    fi
    echo ""
}

# ===========================================
# Pull Images
# ===========================================
pull_images() {
    echo -e "${BLUE}${BOLD}Downloading Docker images...${NC}"
    echo -e "${DIM}This may take several minutes on first run${NC}"
    echo ""

    cd "$PLATFORM_DIR"

    if [[ -n "$SERVICES" ]]; then
        docker compose -f docker-compose.yml -f "$COMPOSE_FILE" -f docker-compose.optional.yml pull 2>&1 | grep -E "(Pulling|Downloaded|Pull complete|Already exists)" || true
    else
        docker compose -f docker-compose.yml -f "$COMPOSE_FILE" pull 2>&1 | grep -E "(Pulling|Downloaded|Pull complete|Already exists)" || true
    fi

    echo ""
    echo -e "${GREEN}Images downloaded${NC}"
    echo ""
}

# ===========================================
# Summary
# ===========================================
show_summary() {
    echo ""
    echo -e "${GREEN}${BOLD}============================================${NC}"
    echo -e "${GREEN}${BOLD}  Setup Complete!${NC}"
    echo -e "${GREEN}${BOLD}============================================${NC}"
    echo ""

    if [[ "$MODE" == "personal" ]]; then
        echo -e "  ${BOLD}Mode:${NC} Personal Learning (No passwords)"
        echo ""
        echo -e "  ${BOLD}Access URLs:${NC}"
        echo -e "    Dashboard:    ${CYAN}http://localhost:8080${NC}"
        echo -e "    Moodle:       ${CYAN}http://localhost:8081${NC}"
        echo -e "    JupyterHub:   ${CYAN}http://localhost:8000${NC}"
        echo -e "    Code Server:  ${CYAN}http://localhost:8844${NC}"
    else
        echo -e "  ${BOLD}Mode:${NC} School/Institution"
        echo -e "  ${BOLD}Domain:${NC} $DOMAIN"
        echo ""
        echo -e "  ${BOLD}Access URLs:${NC}"
        echo -e "    Moodle:       ${CYAN}https://learn.$DOMAIN${NC}"
        echo -e "    JupyterHub:   ${CYAN}https://jupyter.$DOMAIN${NC}"
        echo -e "    Code Server:  ${CYAN}https://code.$DOMAIN${NC}"
        echo ""
        echo -e "  ${YELLOW}Credentials saved to:${NC} $PLATFORM_DIR/CREDENTIALS.txt"
    fi

    echo ""
    echo -e "${GREEN}============================================${NC}"
    echo ""
}

# ===========================================
# Start Platform
# ===========================================
start_platform() {
    read -p "$(echo -e ${BOLD}Start the platform now? [Y/n]${NC} )" -n 1 -r
    echo ""

    if [[ ! $REPLY =~ ^[Nn]$ ]]; then
        echo ""
        echo -e "${BLUE}Starting platform...${NC}"

        cd "$PLATFORM_DIR"

        if [[ -n "$SERVICES" ]]; then
            docker compose -f docker-compose.yml -f "$COMPOSE_FILE" -f docker-compose.optional.yml up -d
        else
            docker compose -f docker-compose.yml -f "$COMPOSE_FILE" up -d
        fi

        echo ""
        echo -e "${GREEN}${BOLD}Platform is starting!${NC}"
        echo ""
        echo -e "${DIM}Moodle takes 2-3 minutes to fully initialize on first run.${NC}"
        echo -e "${DIM}Check status with: docker compose ps${NC}"
        echo ""

        if [[ "$MODE" == "personal" ]]; then
            echo -e "Open ${CYAN}http://localhost:8080${NC} in your browser"
        fi
    fi
}

# ===========================================
# Main
# ===========================================
main() {
    print_banner
    check_docker
    detect_resources
    select_mode

    if [[ "$MODE" == "personal" ]]; then
        setup_personal
    else
        setup_school
    fi

    select_services
    pull_images
    show_summary
    start_platform
}

main "$@"
