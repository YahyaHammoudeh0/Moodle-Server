#!/bin/bash
# ===========================================
# Universal Educational Platform Launcher
# ===========================================
# Works on any system with Docker installed
# No manual configuration required!
#
# Usage: ./start.sh
# ===========================================

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# Logging functions
log_info() { echo -e "${BLUE}ℹ${NC} $1"; }
log_success() { echo -e "${GREEN}✓${NC} $1"; }
log_warning() { echo -e "${YELLOW}⚠${NC} $1"; }
log_error() { echo -e "${RED}✗${NC} $1"; }
log_step() { echo -e "${CYAN}${BOLD}▶${NC} $1"; }

# Platform directory
PLATFORM_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/edu-platform" && pwd)"

# ===========================================
# ASCII Art Banner
# ===========================================
print_banner() {
    echo -e "${CYAN}"
    cat << "EOF"
╔═══════════════════════════════════════════════════════╗
║                                                       ║
║     🎓  Educational Platform                         ║
║                                                       ║
║     Moodle | JupyterHub | Code Server | AI          ║
║                                                       ║
╚═══════════════════════════════════════════════════════╝
EOF
    echo -e "${NC}"
}

# ===========================================
# Check Docker
# ===========================================
check_docker() {
    log_step "Checking Docker installation..."

    if ! command -v docker &> /dev/null; then
        log_error "Docker is not installed!"
        echo ""
        echo "Please install Docker:"
        echo "  • Windows/Mac: https://www.docker.com/products/docker-desktop"
        echo "  • Linux: https://docs.docker.com/engine/install/"
        echo ""
        exit 1
    fi

    if ! docker info &> /dev/null; then
        log_error "Docker daemon is not running!"
        echo ""
        echo "Please start Docker Desktop (Windows/Mac) or Docker service (Linux)"
        exit 1
    fi

    # Check for docker compose v2
    if ! docker compose version &> /dev/null; then
        log_error "Docker Compose v2 is not available!"
        echo ""
        echo "Please install Docker Compose v2 (included in Docker Desktop)"
        exit 1
    fi

    log_success "Docker is ready"
    docker --version
    docker compose version
}

# ===========================================
# Generate Random Password
# ===========================================
generate_password() {
    # Generate a 16-character alphanumeric password
    if command -v openssl &> /dev/null; then
        openssl rand -base64 12 | tr -d "=+/" | cut -c1-16
    else
        # Fallback for systems without openssl
        cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 16 | head -n 1
    fi
}

# ===========================================
# Auto-Generate .env
# ===========================================
generate_env() {
    log_step "Configuring environment..."

    ENV_FILE="$PLATFORM_DIR/.env"

    if [[ -f "$ENV_FILE" ]]; then
        log_info ".env file already exists, using existing configuration"
        return
    fi

    log_info "No .env found - generating with secure defaults..."

    # Generate secure passwords
    POSTGRES_PASS=$(generate_password)
    MOODLE_PASS=$(generate_password)
    JUPYTER_PASS=$(generate_password)
    CODE_PASS=$(generate_password)
    PROXY_PASS=$(generate_password)

    # Create .env file
    cat > "$ENV_FILE" << EOF
# ===========================================
# AUTO-GENERATED CONFIGURATION
# ===========================================
# Generated: $(date)
# This configuration works out of the box for local development
# For production deployment, see edu-platform/.env.example

# ===========================================
# Domain Configuration (localhost for local dev)
# ===========================================
DOMAIN=localhost

# ===========================================
# Moodle Configuration
# ===========================================
MOODLE_USERNAME=admin
MOODLE_PASSWORD=${MOODLE_PASS}
MOODLE_EMAIL=admin@localhost
MOODLE_SITE_NAME=Educational Platform

# ===========================================
# PostgreSQL Configuration
# ===========================================
POSTGRES_PASSWORD=${POSTGRES_PASS}
POSTGRES_MOODLE_DB=moodle_db
POSTGRES_JUPYTER_DB=jupyterhub_db

# ===========================================
# JupyterHub Configuration
# ===========================================
JUPYTERHUB_ADMIN=admin
JUPYTERHUB_ADMIN_PASSWORD=${JUPYTER_PASS}
JUPYTER_MEMORY_LIMIT=1G
JUPYTER_CPU_LIMIT=0.5

# ===========================================
# Code Server Configuration
# ===========================================
CODE_SERVER_PASSWORD=${CODE_PASS}

# ===========================================
# DeepSeek API Configuration (Optional)
# ===========================================
# Get your key from https://platform.deepseek.com
DEEPSEEK_API_KEY=sk-placeholder-get-your-key-from-deepseek
DEEPSEEK_PROXY_API_KEY=${PROXY_PASS}

# ===========================================
# Maxima Configuration
# ===========================================
MAXIMA_POOL_SIZE=3
EOF

    log_success ".env file created with secure random passwords"

    # Create credentials file for user reference
    CREDS_FILE="$PLATFORM_DIR/CREDENTIALS.txt"
    cat > "$CREDS_FILE" << EOF
═══════════════════════════════════════════════════════
  🔐 YOUR AUTO-GENERATED CREDENTIALS
═══════════════════════════════════════════════════════
Generated: $(date)

📚 MOODLE (http://localhost:8080)
   Username: admin
   Password: ${MOODLE_PASS}

🔬 JUPYTERHUB (http://localhost:8000)
   Username: admin
   Password: ${JUPYTER_PASS}

💻 CODE SERVER (http://localhost:8443)
   Password: ${CODE_PASS}

🤖 AI PROXY (http://localhost:8001)
   API Key: ${PROXY_PASS}

═══════════════════════════════════════════════════════
⚠️  IMPORTANT: Keep this file secure!
    These are randomly generated passwords.
    To use custom passwords, edit edu-platform/.env
═══════════════════════════════════════════════════════
EOF

    echo ""
    log_success "Credentials saved to: ${CYAN}edu-platform/CREDENTIALS.txt${NC}"
    echo ""
}

# ===========================================
# Start Services
# ===========================================
start_services() {
    log_step "Starting services..."

    cd "$PLATFORM_DIR"

    # Pull latest images
    log_info "Pulling Docker images (this may take a few minutes on first run)..."
    docker compose pull --quiet

    # Build custom images
    log_info "Building custom images..."
    docker compose build --quiet

    # Start all services
    log_info "Starting all containers..."
    docker compose up -d

    log_success "All services started!"
}

# ===========================================
# Wait for Services
# ===========================================
wait_for_services() {
    log_step "Waiting for services to be ready..."

    echo ""
    log_info "This may take 2-3 minutes on first startup..."

    # Wait for health checks
    sleep 10

    local max_wait=180
    local elapsed=0
    local interval=5

    while [[ $elapsed -lt $max_wait ]]; do
        cd "$PLATFORM_DIR"

        # Check if key services are healthy
        if docker compose ps | grep -q "unhealthy"; then
            log_warning "Some services are still starting... (${elapsed}s elapsed)"
        elif docker compose ps | grep -E "(moodle|jupyterhub|caddy)" | grep -q "Up"; then
            log_success "Services are ready!"
            return 0
        fi

        sleep $interval
        elapsed=$((elapsed + interval))
    done

    log_warning "Services taking longer than expected, but continuing..."
}

# ===========================================
# Print Access Information
# ===========================================
print_access_info() {
    echo ""
    echo -e "${GREEN}${BOLD}═══════════════════════════════════════════════════════${NC}"
    echo -e "${GREEN}${BOLD}  🎉 Platform is Running!${NC}"
    echo -e "${GREEN}${BOLD}═══════════════════════════════════════════════════════${NC}"
    echo ""
    echo -e "${BOLD}📍 Access Your Services:${NC}"
    echo ""
    echo -e "  ${CYAN}📚 Moodle LMS${NC}"
    echo -e "     → http://localhost:8080"
    echo ""
    echo -e "  ${CYAN}🔬 JupyterHub${NC}"
    echo -e "     → http://localhost:8000"
    echo ""
    echo -e "  ${CYAN}💻 VS Code (Code Server)${NC}"
    echo -e "     → http://localhost:8443"
    echo ""
    echo -e "  ${CYAN}🤖 AI Assistant API${NC}"
    echo -e "     → http://localhost:8001/docs"
    echo ""
    echo -e "${BOLD}🔐 Credentials:${NC}"
    echo -e "     → See ${CYAN}edu-platform/CREDENTIALS.txt${NC}"
    echo ""
    echo -e "${BOLD}📊 Useful Commands:${NC}"
    echo ""
    echo -e "  ${YELLOW}View logs:${NC}         ./stop.sh logs"
    echo -e "  ${YELLOW}Stop platform:${NC}     ./stop.sh"
    echo -e "  ${YELLOW}Restart platform:${NC}  ./start.sh"
    echo -e "  ${YELLOW}Service status:${NC}    docker compose -f edu-platform/docker-compose.yml ps"
    echo ""
    echo -e "${GREEN}═══════════════════════════════════════════════════════${NC}"
    echo ""

    # Check if credentials file exists and show it
    if [[ -f "$PLATFORM_DIR/CREDENTIALS.txt" ]]; then
        cat "$PLATFORM_DIR/CREDENTIALS.txt"
        echo ""
    fi
}

# ===========================================
# Main Execution
# ===========================================
main() {
    clear
    print_banner

    check_docker
    echo ""

    generate_env
    echo ""

    start_services
    echo ""

    wait_for_services
    echo ""

    print_access_info

    log_info "Platform is ready to use! 🚀"
    echo ""
}

# Run main function
main "$@"
