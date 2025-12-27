#!/bin/bash
# ===========================================
# Educational Platform Backup Script
# ===========================================
# Creates backups of all platform data:
# - PostgreSQL databases (moodle_db, jupyterhub_db)
# - Moodle data files
# - JupyterHub user home directories
# - Code Server configuration
#
# Usage: ./backup.sh [--remote]
# Options:
#   --remote    Upload backup to remote storage (requires .env config)
# ===========================================

set -e

# Configuration
PLATFORM_DIR="${PLATFORM_DIR:-/opt/edu-platform}"
BACKUP_DIR="${BACKUP_DIR:-/opt/edu-platform/backups}"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
BACKUP_NAME="edu-platform-backup-${TIMESTAMP}"
BACKUP_PATH="${BACKUP_DIR}/${BACKUP_NAME}"
RETENTION_DAYS=7

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

    # Check if running from correct directory
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

    # Create backup directory
    mkdir -p "$BACKUP_PATH"

    log_success "Prerequisites check passed"
}

# ===========================================
# Backup PostgreSQL Databases
# ===========================================
backup_postgres() {
    log_info "Backing up PostgreSQL databases..."

    cd "$PLATFORM_DIR"

    # Backup Moodle database
    log_info "  Dumping moodle_db..."
    docker compose exec -T postgres pg_dump -U postgres moodle_db | gzip > "$BACKUP_PATH/moodle_db.sql.gz"

    # Backup JupyterHub database
    log_info "  Dumping jupyterhub_db..."
    docker compose exec -T postgres pg_dump -U postgres jupyterhub_db | gzip > "$BACKUP_PATH/jupyterhub_db.sql.gz"

    log_success "PostgreSQL databases backed up"
}

# ===========================================
# Backup Docker Volumes
# ===========================================
backup_volumes() {
    log_info "Backing up Docker volumes..."

    cd "$PLATFORM_DIR"

    # Get the compose project name
    PROJECT_NAME=$(docker compose config --format json | grep -o '"name":"[^"]*"' | head -1 | cut -d'"' -f4)
    if [[ -z "$PROJECT_NAME" ]]; then
        PROJECT_NAME="edu-platform"
    fi

    # Backup Moodle data
    log_info "  Backing up Moodle data..."
    docker run --rm \
        -v "${PROJECT_NAME}_moodledata:/data:ro" \
        -v "$BACKUP_PATH:/backup" \
        alpine tar czf /backup/moodledata.tar.gz -C /data .

    # Backup Moodle installation
    log_info "  Backing up Moodle installation..."
    docker run --rm \
        -v "${PROJECT_NAME}_moodle_data:/data:ro" \
        -v "$BACKUP_PATH:/backup" \
        alpine tar czf /backup/moodle.tar.gz -C /data .

    # Backup JupyterHub data
    log_info "  Backing up JupyterHub data..."
    docker run --rm \
        -v "${PROJECT_NAME}_jupyterhub_data:/data:ro" \
        -v "$BACKUP_PATH:/backup" \
        alpine tar czf /backup/jupyterhub_data.tar.gz -C /data .

    # Backup Jupyter user directories
    log_info "  Backing up Jupyter user directories..."
    docker run --rm \
        -v "${PROJECT_NAME}_jupyter_users:/data:ro" \
        -v "$BACKUP_PATH:/backup" \
        alpine tar czf /backup/jupyter_users.tar.gz -C /data .

    # Backup Code Server data
    log_info "  Backing up Code Server data..."
    docker run --rm \
        -v "${PROJECT_NAME}_code_server_data:/data:ro" \
        -v "$BACKUP_PATH:/backup" \
        alpine tar czf /backup/code_server_data.tar.gz -C /data .

    log_success "Docker volumes backed up"
}

# ===========================================
# Backup Configuration Files
# ===========================================
backup_config() {
    log_info "Backing up configuration files..."

    # Backup .env (encrypted)
    if [[ -f "$PLATFORM_DIR/.env" ]]; then
        cp "$PLATFORM_DIR/.env" "$BACKUP_PATH/.env"
        # Note: Consider encrypting this file
        log_warning ".env contains sensitive data - consider encrypting the backup"
    fi

    # Backup Caddyfile
    cp "$PLATFORM_DIR/caddy/Caddyfile" "$BACKUP_PATH/Caddyfile" 2>/dev/null || true

    # Backup JupyterHub config
    cp "$PLATFORM_DIR/jupyterhub/jupyterhub_config.py" "$BACKUP_PATH/jupyterhub_config.py" 2>/dev/null || true

    log_success "Configuration files backed up"
}

# ===========================================
# Create Final Archive
# ===========================================
create_archive() {
    log_info "Creating final backup archive..."

    cd "$BACKUP_DIR"

    # Create compressed archive
    tar czf "${BACKUP_NAME}.tar.gz" "$BACKUP_NAME"

    # Remove uncompressed backup
    rm -rf "$BACKUP_PATH"

    # Calculate size
    BACKUP_SIZE=$(du -h "${BACKUP_NAME}.tar.gz" | cut -f1)

    log_success "Backup archive created: ${BACKUP_NAME}.tar.gz (${BACKUP_SIZE})"
}

# ===========================================
# Cleanup Old Backups
# ===========================================
cleanup_old_backups() {
    log_info "Cleaning up backups older than ${RETENTION_DAYS} days..."

    find "$BACKUP_DIR" -name "edu-platform-backup-*.tar.gz" -type f -mtime +$RETENTION_DAYS -delete

    # Count remaining backups
    BACKUP_COUNT=$(find "$BACKUP_DIR" -name "edu-platform-backup-*.tar.gz" -type f | wc -l)

    log_success "Cleanup complete. ${BACKUP_COUNT} backup(s) retained."
}

# ===========================================
# Upload to Remote Storage (Optional)
# ===========================================
upload_remote() {
    log_info "Uploading backup to remote storage..."

    cd "$BACKUP_DIR"

    # Check for Hetzner Storage Box configuration
    if [[ -n "$BACKUP_HOST" ]] && [[ -n "$BACKUP_USER" ]]; then
        log_info "  Uploading to Hetzner Storage Box..."

        # Using scp (requires SSH key or sshpass)
        scp "${BACKUP_NAME}.tar.gz" "${BACKUP_USER}@${BACKUP_HOST}:${BACKUP_PATH:-/backups}/" || {
            log_error "Failed to upload to Hetzner Storage Box"
            return 1
        }

        log_success "Uploaded to Hetzner Storage Box"
        return 0
    fi

    # Check for S3 configuration
    if [[ -n "$S3_BUCKET" ]] && [[ -n "$S3_ACCESS_KEY" ]]; then
        log_info "  Uploading to S3..."

        # Requires aws-cli or similar tool
        if command -v aws &> /dev/null; then
            export AWS_ACCESS_KEY_ID="$S3_ACCESS_KEY"
            export AWS_SECRET_ACCESS_KEY="$S3_SECRET_KEY"

            aws s3 cp "${BACKUP_NAME}.tar.gz" "s3://${S3_BUCKET}/" --endpoint-url "${S3_ENDPOINT:-https://s3.amazonaws.com}" || {
                log_error "Failed to upload to S3"
                return 1
            }

            log_success "Uploaded to S3"
            return 0
        else
            log_error "aws-cli not installed. Cannot upload to S3."
            return 1
        fi
    fi

    log_warning "No remote storage configured. Backup stored locally only."
}

# ===========================================
# Print Summary
# ===========================================
print_summary() {
    echo ""
    echo "=========================================="
    echo -e "${GREEN}Backup Complete!${NC}"
    echo "=========================================="
    echo ""
    echo "Backup location: ${BACKUP_DIR}/${BACKUP_NAME}.tar.gz"
    echo "Backup size: ${BACKUP_SIZE}"
    echo ""
    echo "Contents:"
    echo "  - moodle_db.sql.gz (Moodle database)"
    echo "  - jupyterhub_db.sql.gz (JupyterHub database)"
    echo "  - moodledata.tar.gz (Moodle files)"
    echo "  - moodle.tar.gz (Moodle installation)"
    echo "  - jupyterhub_data.tar.gz (JupyterHub data)"
    echo "  - jupyter_users.tar.gz (User notebooks)"
    echo "  - code_server_data.tar.gz (VS Code data)"
    echo "  - .env (Configuration)"
    echo ""
    echo "To restore from this backup:"
    echo "  ./restore.sh ${BACKUP_DIR}/${BACKUP_NAME}.tar.gz"
    echo ""
}

# ===========================================
# Main Execution
# ===========================================
main() {
    echo ""
    echo "=========================================="
    echo "Educational Platform Backup"
    echo "=========================================="
    echo ""

    REMOTE_UPLOAD=false

    # Parse arguments
    for arg in "$@"; do
        case $arg in
            --remote)
                REMOTE_UPLOAD=true
                shift
                ;;
        esac
    done

    check_prerequisites
    backup_postgres
    backup_volumes
    backup_config
    create_archive
    cleanup_old_backups

    if [[ "$REMOTE_UPLOAD" == "true" ]]; then
        upload_remote
    fi

    print_summary
}

# Run main function
main "$@"
