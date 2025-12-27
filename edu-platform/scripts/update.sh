#!/bin/bash
# ===========================================
# Educational Platform Update Script
# ===========================================
# Updates all Docker images and restarts services
# Creates a backup before updating for safety
#
# Usage: ./update.sh [--skip-backup] [--skip-pull]
# Options:
#   --skip-backup    Skip creating backup before update
#   --skip-pull      Skip pulling new images (just restart)
# ===========================================

set -e

# Configuration
PLATFORM_DIR="${PLATFORM_DIR:-/opt/edu-platform}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Logging functions
log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Options
SKIP_BACKUP=false
SKIP_PULL=false

# ===========================================
# Parse Arguments
# ===========================================
parse_args() {
    for arg in "$@"; do
        case $arg in
            --skip-backup)
                SKIP_BACKUP=true
                log_warning "Skipping backup before update"
                shift
                ;;
            --skip-pull)
                SKIP_PULL=true
                log_info "Skipping image pull (restart only)"
                shift
                ;;
            --help)
                echo "Usage: $0 [--skip-backup] [--skip-pull]"
                echo ""
                echo "Options:"
                echo "  --skip-backup    Skip creating backup before update"
                echo "  --skip-pull      Skip pulling new images (just restart)"
                exit 0
                ;;
        esac
    done
}

# ===========================================
# Check Prerequisites
# ===========================================
check_prerequisites() {
    log_info "Checking prerequisites..."

    # Check if docker-compose.yml exists
    if [[ ! -f "$PLATFORM_DIR/docker-compose.yml" ]]; then
        log_error "docker-compose.yml not found in $PLATFORM_DIR"
        exit 1
    fi

    # Load environment variables
    if [[ -f "$PLATFORM_DIR/.env" ]]; then
        source "$PLATFORM_DIR/.env"
    else
        log_error ".env file not found"
        exit 1
    fi

    log_success "Prerequisites check passed"
}

# ===========================================
# Create Pre-Update Backup
# ===========================================
create_backup() {
    if [[ "$SKIP_BACKUP" == "true" ]]; then
        log_info "Skipping backup (--skip-backup flag set)"
        return
    fi

    log_info "Creating pre-update backup..."

    if [[ -f "$SCRIPT_DIR/backup.sh" ]]; then
        "$SCRIPT_DIR/backup.sh"
        log_success "Pre-update backup created"
    else
        log_warning "backup.sh not found, skipping backup"
    fi
}

# ===========================================
# Record Current Versions
# ===========================================
record_versions() {
    log_info "Recording current image versions..."

    cd "$PLATFORM_DIR"

    echo "Current image versions:" > /tmp/update-versions-before.txt
    docker compose images >> /tmp/update-versions-before.txt 2>&1 || true

    log_success "Current versions recorded"
}

# ===========================================
# Pull New Images
# ===========================================
pull_images() {
    if [[ "$SKIP_PULL" == "true" ]]; then
        log_info "Skipping image pull (--skip-pull flag set)"
        return
    fi

    log_info "Pulling latest Docker images..."

    cd "$PLATFORM_DIR"

    # Pull all images
    docker compose pull

    log_success "Images pulled"
}

# ===========================================
# Rebuild Custom Images
# ===========================================
rebuild_custom_images() {
    if [[ "$SKIP_PULL" == "true" ]]; then
        return
    fi

    log_info "Rebuilding custom images..."

    cd "$PLATFORM_DIR"

    # Rebuild JupyterHub
    if [[ -f "./jupyterhub/Dockerfile" ]]; then
        log_info "  Rebuilding JupyterHub..."
        docker compose build jupyterhub
    fi

    # Rebuild notebook image
    if [[ -f "./jupyter-notebook/Dockerfile" ]]; then
        log_info "  Rebuilding Jupyter notebook image..."
        docker build -t edu-platform-notebook:latest ./jupyter-notebook/
    fi

    # Rebuild DeepSeek proxy
    if [[ -f "./deepseek-proxy/Dockerfile" ]]; then
        log_info "  Rebuilding DeepSeek proxy..."
        docker compose build deepseek-proxy
    fi

    log_success "Custom images rebuilt"
}

# ===========================================
# Stop Services
# ===========================================
stop_services() {
    log_info "Stopping services..."

    cd "$PLATFORM_DIR"
    docker compose stop

    log_success "Services stopped"
}

# ===========================================
# Start Services
# ===========================================
start_services() {
    log_info "Starting services with new images..."

    cd "$PLATFORM_DIR"
    docker compose up -d

    log_success "Services starting..."
}

# ===========================================
# Wait for Health Checks
# ===========================================
wait_for_health() {
    log_info "Waiting for services to be healthy..."

    cd "$PLATFORM_DIR"

    # Maximum wait time (5 minutes)
    MAX_WAIT=300
    ELAPSED=0
    INTERVAL=10

    while [[ $ELAPSED -lt $MAX_WAIT ]]; do
        # Count healthy services
        HEALTHY=$(docker compose ps --format json 2>/dev/null | grep -c '"Health":"healthy"' || echo 0)
        TOTAL=$(docker compose ps --format json 2>/dev/null | wc -l || echo 0)
        RUNNING=$(docker compose ps --format json 2>/dev/null | grep -c '"State":"running"' || echo 0)

        echo -ne "\r  Running: $RUNNING/$TOTAL, Healthy: $HEALTHY (${ELAPSED}s elapsed)     "

        # Check if all services are running
        if [[ $RUNNING -eq $TOTAL ]] && [[ $RUNNING -gt 0 ]]; then
            echo ""
            log_success "All services are running"
            return 0
        fi

        sleep $INTERVAL
        ELAPSED=$((ELAPSED + INTERVAL))
    done

    echo ""
    log_warning "Timeout waiting for services. Some may still be starting."
    return 1
}

# ===========================================
# Health Check
# ===========================================
health_check() {
    log_info "Running health checks..."

    cd "$PLATFORM_DIR"

    FAILED=0

    # Check each service
    for SERVICE in postgres redis moodle maxima jupyterhub code-server deepseek-proxy caddy; do
        STATE=$(docker compose ps --format "{{.State}}" "$SERVICE" 2>/dev/null || echo "not found")
        if [[ "$STATE" == "running" ]]; then
            echo -e "  ${GREEN}✓${NC} $SERVICE is running"
        else
            echo -e "  ${RED}✗${NC} $SERVICE is $STATE"
            FAILED=$((FAILED + 1))
        fi
    done

    if [[ $FAILED -gt 0 ]]; then
        log_warning "$FAILED service(s) may have issues"
        return 1
    else
        log_success "All services healthy"
        return 0
    fi
}

# ===========================================
# Record New Versions
# ===========================================
record_new_versions() {
    log_info "Recording new image versions..."

    cd "$PLATFORM_DIR"

    echo ""
    echo "Image versions after update:"
    docker compose images

    log_success "New versions recorded"
}

# ===========================================
# Cleanup Old Images
# ===========================================
cleanup_old_images() {
    log_info "Cleaning up unused Docker images..."

    # Remove dangling images
    docker image prune -f

    # Show disk usage
    echo ""
    echo "Docker disk usage:"
    docker system df

    log_success "Cleanup complete"
}

# ===========================================
# Rollback Instructions
# ===========================================
print_rollback_instructions() {
    echo ""
    echo "=========================================="
    echo "Rollback Instructions (if needed)"
    echo "=========================================="
    echo ""
    echo "If the update caused issues, you can rollback:"
    echo ""
    echo "1. Check the backup created before update:"
    echo "   ls -la $PLATFORM_DIR/backups/"
    echo ""
    echo "2. Stop services:"
    echo "   cd $PLATFORM_DIR && docker compose down"
    echo ""
    echo "3. Restore from backup:"
    echo "   ./scripts/restore.sh backups/<backup-file>.tar.gz"
    echo ""
    echo "4. If you need specific old image versions:"
    echo "   Check /tmp/update-versions-before.txt"
    echo ""
}

# ===========================================
# Print Summary
# ===========================================
print_summary() {
    echo ""
    echo "=========================================="
    echo -e "${GREEN}Update Complete!${NC}"
    echo "=========================================="
    echo ""
    echo "Services have been updated to the latest versions."
    echo ""
    echo "Next steps:"
    echo "  1. Verify services are working:"
    echo "     - Moodle: https://learn.$DOMAIN"
    echo "     - JupyterHub: https://jupyter.$DOMAIN"
    echo "     - Code Server: https://code.$DOMAIN"
    echo ""
    echo "  2. Check logs for any errors:"
    echo "     docker compose logs --tail=50"
    echo ""
    echo "  3. Monitor resource usage:"
    echo "     docker stats"
    echo ""
    print_rollback_instructions
}

# ===========================================
# Main Execution
# ===========================================
main() {
    echo ""
    echo "=========================================="
    echo "Educational Platform Update"
    echo "=========================================="
    echo ""

    parse_args "$@"
    check_prerequisites

    echo ""
    log_info "This will update all Docker images and restart services."
    read -p "Continue? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log_info "Update cancelled"
        exit 0
    fi

    create_backup
    record_versions
    pull_images
    rebuild_custom_images
    stop_services
    start_services

    if wait_for_health; then
        health_check
    fi

    record_new_versions
    cleanup_old_images
    print_summary
}

# Run main function
main "$@"
