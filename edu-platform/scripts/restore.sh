#!/bin/bash
# ===========================================
# Educational Platform Restore Script
# ===========================================
# Restores platform from a backup archive
#
# Usage: ./restore.sh <backup-file.tar.gz>
# ===========================================

set -e

# Configuration
PLATFORM_DIR="${PLATFORM_DIR:-/opt/edu-platform}"
TEMP_DIR="/tmp/edu-platform-restore-$$"

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

# ===========================================
# Check Prerequisites
# ===========================================
check_prerequisites() {
    log_info "Checking prerequisites..."

    # Check for backup file argument
    if [[ -z "$1" ]]; then
        log_error "Usage: $0 <backup-file.tar.gz>"
        exit 1
    fi

    BACKUP_FILE="$1"

    # Check if backup file exists
    if [[ ! -f "$BACKUP_FILE" ]]; then
        log_error "Backup file not found: $BACKUP_FILE"
        exit 1
    fi

    # Check if docker-compose.yml exists
    if [[ ! -f "$PLATFORM_DIR/docker-compose.yml" ]]; then
        log_error "docker-compose.yml not found in $PLATFORM_DIR"
        log_info "Please run setup.sh first or set PLATFORM_DIR correctly"
        exit 1
    fi

    # Load environment variables
    if [[ -f "$PLATFORM_DIR/.env" ]]; then
        source "$PLATFORM_DIR/.env"
    fi

    log_success "Prerequisites check passed"
}

# ===========================================
# Stop Services
# ===========================================
stop_services() {
    log_info "Stopping services..."

    cd "$PLATFORM_DIR"
    docker compose down

    log_success "Services stopped"
}

# ===========================================
# Extract Backup
# ===========================================
extract_backup() {
    log_info "Extracting backup archive..."

    mkdir -p "$TEMP_DIR"
    tar xzf "$BACKUP_FILE" -C "$TEMP_DIR"

    # Find the backup directory (handle nested extraction)
    BACKUP_CONTENT=$(find "$TEMP_DIR" -maxdepth 1 -type d -name "edu-platform-backup-*" | head -1)
    if [[ -z "$BACKUP_CONTENT" ]]; then
        BACKUP_CONTENT="$TEMP_DIR"
    fi

    log_success "Backup extracted to $TEMP_DIR"
}

# ===========================================
# Restore PostgreSQL Databases
# ===========================================
restore_postgres() {
    log_info "Restoring PostgreSQL databases..."

    cd "$PLATFORM_DIR"

    # Start only PostgreSQL
    docker compose up -d postgres
    sleep 10  # Wait for PostgreSQL to be ready

    # Restore Moodle database
    if [[ -f "$BACKUP_CONTENT/moodle_db.sql.gz" ]]; then
        log_info "  Restoring moodle_db..."
        # Drop and recreate database
        docker compose exec -T postgres psql -U postgres -c "DROP DATABASE IF EXISTS moodle_db;"
        docker compose exec -T postgres psql -U postgres -c "CREATE DATABASE moodle_db OWNER moodle;"
        # Restore data
        gunzip -c "$BACKUP_CONTENT/moodle_db.sql.gz" | docker compose exec -T postgres psql -U postgres moodle_db
        log_success "  moodle_db restored"
    else
        log_warning "  moodle_db.sql.gz not found in backup"
    fi

    # Restore JupyterHub database
    if [[ -f "$BACKUP_CONTENT/jupyterhub_db.sql.gz" ]]; then
        log_info "  Restoring jupyterhub_db..."
        # Drop and recreate database
        docker compose exec -T postgres psql -U postgres -c "DROP DATABASE IF EXISTS jupyterhub_db;"
        docker compose exec -T postgres psql -U postgres -c "CREATE DATABASE jupyterhub_db OWNER jupyterhub;"
        # Restore data
        gunzip -c "$BACKUP_CONTENT/jupyterhub_db.sql.gz" | docker compose exec -T postgres psql -U postgres jupyterhub_db
        log_success "  jupyterhub_db restored"
    else
        log_warning "  jupyterhub_db.sql.gz not found in backup"
    fi

    # Stop PostgreSQL (will restart with all services later)
    docker compose stop postgres

    log_success "PostgreSQL databases restored"
}

# ===========================================
# Restore Docker Volumes
# ===========================================
restore_volumes() {
    log_info "Restoring Docker volumes..."

    cd "$PLATFORM_DIR"

    # Get the compose project name
    PROJECT_NAME=$(docker compose config --format json | grep -o '"name":"[^"]*"' | head -1 | cut -d'"' -f4)
    if [[ -z "$PROJECT_NAME" ]]; then
        PROJECT_NAME="edu-platform"
    fi

    # Restore Moodle data
    if [[ -f "$BACKUP_CONTENT/moodledata.tar.gz" ]]; then
        log_info "  Restoring Moodle data..."
        # Create volume if it doesn't exist
        docker volume create "${PROJECT_NAME}_moodledata" 2>/dev/null || true
        # Clear and restore
        docker run --rm \
            -v "${PROJECT_NAME}_moodledata:/data" \
            -v "$BACKUP_CONTENT:/backup:ro" \
            alpine sh -c "rm -rf /data/* && tar xzf /backup/moodledata.tar.gz -C /data"
        log_success "  Moodle data restored"
    fi

    # Restore Moodle installation
    if [[ -f "$BACKUP_CONTENT/moodle.tar.gz" ]]; then
        log_info "  Restoring Moodle installation..."
        docker volume create "${PROJECT_NAME}_moodle_data" 2>/dev/null || true
        docker run --rm \
            -v "${PROJECT_NAME}_moodle_data:/data" \
            -v "$BACKUP_CONTENT:/backup:ro" \
            alpine sh -c "rm -rf /data/* && tar xzf /backup/moodle.tar.gz -C /data"
        log_success "  Moodle installation restored"
    fi

    # Restore JupyterHub data
    if [[ -f "$BACKUP_CONTENT/jupyterhub_data.tar.gz" ]]; then
        log_info "  Restoring JupyterHub data..."
        docker volume create "${PROJECT_NAME}_jupyterhub_data" 2>/dev/null || true
        docker run --rm \
            -v "${PROJECT_NAME}_jupyterhub_data:/data" \
            -v "$BACKUP_CONTENT:/backup:ro" \
            alpine sh -c "rm -rf /data/* && tar xzf /backup/jupyterhub_data.tar.gz -C /data"
        log_success "  JupyterHub data restored"
    fi

    # Restore Jupyter user directories
    if [[ -f "$BACKUP_CONTENT/jupyter_users.tar.gz" ]]; then
        log_info "  Restoring Jupyter user directories..."
        docker volume create "${PROJECT_NAME}_jupyter_users" 2>/dev/null || true
        docker run --rm \
            -v "${PROJECT_NAME}_jupyter_users:/data" \
            -v "$BACKUP_CONTENT:/backup:ro" \
            alpine sh -c "rm -rf /data/* && tar xzf /backup/jupyter_users.tar.gz -C /data"
        log_success "  Jupyter user directories restored"
    fi

    # Restore Code Server data
    if [[ -f "$BACKUP_CONTENT/code_server_data.tar.gz" ]]; then
        log_info "  Restoring Code Server data..."
        docker volume create "${PROJECT_NAME}_code_server_data" 2>/dev/null || true
        docker run --rm \
            -v "${PROJECT_NAME}_code_server_data:/data" \
            -v "$BACKUP_CONTENT:/backup:ro" \
            alpine sh -c "rm -rf /data/* && tar xzf /backup/code_server_data.tar.gz -C /data"
        log_success "  Code Server data restored"
    fi

    log_success "Docker volumes restored"
}

# ===========================================
# Restore Configuration (Optional)
# ===========================================
restore_config() {
    log_info "Checking configuration files..."

    # Only restore .env if user confirms
    if [[ -f "$BACKUP_CONTENT/.env" ]]; then
        echo ""
        log_warning "Backup contains .env file with sensitive configuration."
        read -p "Do you want to restore .env from backup? (y/n) " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            cp "$BACKUP_CONTENT/.env" "$PLATFORM_DIR/.env"
            chmod 600 "$PLATFORM_DIR/.env"
            log_success ".env restored from backup"
        else
            log_info "Keeping current .env file"
        fi
    fi
}

# ===========================================
# Start Services
# ===========================================
start_services() {
    log_info "Starting services..."

    cd "$PLATFORM_DIR"
    docker compose up -d

    log_info "Waiting for services to be healthy..."
    sleep 30

    # Check service health
    docker compose ps

    log_success "Services started"
}

# ===========================================
# Cleanup
# ===========================================
cleanup() {
    log_info "Cleaning up temporary files..."

    rm -rf "$TEMP_DIR"

    log_success "Cleanup complete"
}

# ===========================================
# Verify Restoration
# ===========================================
verify_restoration() {
    log_info "Verifying restoration..."

    cd "$PLATFORM_DIR"

    # Check if services are running
    RUNNING=$(docker compose ps --format json | grep -c '"State":"running"' || echo 0)
    TOTAL=$(docker compose ps --format json | wc -l)

    echo ""
    echo "Services running: $RUNNING / $TOTAL"

    if [[ $RUNNING -lt $TOTAL ]]; then
        log_warning "Some services may not be running. Check with: docker compose ps"
    else
        log_success "All services are running"
    fi
}

# ===========================================
# Print Summary
# ===========================================
print_summary() {
    echo ""
    echo "=========================================="
    echo -e "${GREEN}Restore Complete!${NC}"
    echo "=========================================="
    echo ""
    echo "Restored from: $BACKUP_FILE"
    echo ""
    echo "Next steps:"
    echo "  1. Verify services are running:"
    echo "     docker compose ps"
    echo ""
    echo "  2. Check service logs for errors:"
    echo "     docker compose logs"
    echo ""
    echo "  3. Test access to:"
    echo "     - Moodle: https://learn.DOMAIN"
    echo "     - JupyterHub: https://jupyter.DOMAIN"
    echo "     - Code Server: https://code.DOMAIN"
    echo ""
    echo "  4. Verify data integrity:"
    echo "     - Check Moodle courses and users"
    echo "     - Check Jupyter notebooks"
    echo "     - Test STACK questions"
    echo ""
}

# ===========================================
# Main Execution
# ===========================================
main() {
    echo ""
    echo "=========================================="
    echo "Educational Platform Restore"
    echo "=========================================="
    echo ""

    check_prerequisites "$1"

    echo ""
    log_warning "This will restore from backup and may overwrite existing data!"
    read -p "Are you sure you want to continue? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log_info "Restore cancelled"
        exit 0
    fi

    stop_services
    extract_backup
    restore_postgres
    restore_volumes
    restore_config
    start_services
    cleanup
    verify_restoration
    print_summary
}

# Run main function
main "$@"
