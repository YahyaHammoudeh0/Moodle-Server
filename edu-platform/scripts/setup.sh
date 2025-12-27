#!/bin/bash
# ===========================================
# Educational Platform Setup Script
# ===========================================
# This script prepares a fresh Ubuntu 24.04 server for the educational platform
# Target: Hetzner CCX13 (2 dedicated vCPU, 8GB RAM, 80GB SSD)
#
# Usage: sudo ./setup.sh
# ===========================================

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

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

    # Check if running as root
    if [[ $EUID -ne 0 ]]; then
        log_error "This script must be run as root (use sudo)"
        exit 1
    fi

    # Check Ubuntu version
    if ! grep -q "Ubuntu" /etc/os-release; then
        log_warning "This script is designed for Ubuntu. Proceed with caution."
    fi

    # Check minimum RAM (7GB for containers + buffer)
    total_ram=$(free -g | awk '/^Mem:/{print $2}')
    if [[ $total_ram -lt 7 ]]; then
        log_warning "System has ${total_ram}GB RAM. 8GB recommended."
    fi

    # Check disk space (50GB minimum)
    disk_space=$(df -BG / | awk 'NR==2 {print $4}' | sed 's/G//')
    if [[ $disk_space -lt 50 ]]; then
        log_warning "Only ${disk_space}GB disk space available. 80GB recommended."
    fi

    log_success "Prerequisites check completed"
}

# ===========================================
# Update System
# ===========================================
update_system() {
    log_info "Updating system packages..."

    apt-get update
    DEBIAN_FRONTEND=noninteractive apt-get upgrade -y

    log_success "System updated"
}

# ===========================================
# Install Docker
# ===========================================
install_docker() {
    log_info "Installing Docker..."

    # Check if Docker is already installed
    if command -v docker &> /dev/null; then
        log_info "Docker is already installed"
        docker --version
    else
        # Install prerequisites
        apt-get install -y \
            apt-transport-https \
            ca-certificates \
            curl \
            gnupg \
            lsb-release

        # Add Docker's official GPG key
        install -m 0755 -d /etc/apt/keyrings
        curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
        chmod a+r /etc/apt/keyrings/docker.gpg

        # Set up the repository
        echo \
            "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
            $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
            tee /etc/apt/sources.list.d/docker.list > /dev/null

        # Install Docker Engine
        apt-get update
        apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

        log_success "Docker installed"
    fi

    # Start and enable Docker
    systemctl start docker
    systemctl enable docker

    # Verify Docker Compose v2
    docker compose version
}

# ===========================================
# Configure Firewall
# ===========================================
configure_firewall() {
    log_info "Configuring firewall (UFW)..."

    apt-get install -y ufw

    # Reset UFW to default
    ufw --force reset

    # Default policies
    ufw default deny incoming
    ufw default allow outgoing

    # Allow SSH
    ufw allow 22/tcp

    # Allow HTTP and HTTPS
    ufw allow 80/tcp
    ufw allow 443/tcp

    # Enable UFW
    ufw --force enable

    log_success "Firewall configured (ports 22, 80, 443 open)"
}

# ===========================================
# Create Non-Root User
# ===========================================
create_user() {
    log_info "Creating eduplatform user..."

    if id "eduplatform" &>/dev/null; then
        log_info "User eduplatform already exists"
    else
        useradd -m -s /bin/bash eduplatform
        usermod -aG docker eduplatform
        log_success "User eduplatform created and added to docker group"
    fi
}

# ===========================================
# Configure Automatic Security Updates
# ===========================================
configure_auto_updates() {
    log_info "Configuring automatic security updates..."

    apt-get install -y unattended-upgrades apt-listchanges

    # Configure unattended-upgrades
    cat > /etc/apt/apt.conf.d/20auto-upgrades << 'EOF'
APT::Periodic::Update-Package-Lists "1";
APT::Periodic::Unattended-Upgrade "1";
APT::Periodic::AutocleanInterval "7";
EOF

    # Enable security updates only
    cat > /etc/apt/apt.conf.d/50unattended-upgrades << 'EOF'
Unattended-Upgrade::Allowed-Origins {
    "${distro_id}:${distro_codename}-security";
};
Unattended-Upgrade::Package-Blacklist {
};
Unattended-Upgrade::AutoFixInterruptedDpkg "true";
Unattended-Upgrade::MinimalSteps "true";
Unattended-Upgrade::Remove-Unused-Dependencies "true";
Unattended-Upgrade::Automatic-Reboot "false";
EOF

    systemctl enable unattended-upgrades
    systemctl start unattended-upgrades

    log_success "Automatic security updates configured"
}

# ===========================================
# Configure Swap (Critical for 8GB RAM)
# ===========================================
configure_swap() {
    log_info "Configuring swap..."

    # Check if swap already exists
    if swapon --show | grep -q "/swapfile"; then
        log_info "Swap file already exists"
    else
        # Create 4GB swap file
        fallocate -l 4G /swapfile
        chmod 600 /swapfile
        mkswap /swapfile
        swapon /swapfile

        # Make permanent
        echo '/swapfile none swap sw 0 0' >> /etc/fstab

        log_success "4GB swap file created"
    fi

    # Set swappiness to prefer RAM over swap
    sysctl vm.swappiness=10
    echo 'vm.swappiness=10' >> /etc/sysctl.conf

    # Set vfs_cache_pressure
    sysctl vm.vfs_cache_pressure=50
    echo 'vm.vfs_cache_pressure=50' >> /etc/sysctl.conf

    log_success "Swap configured with swappiness=10"
}

# ===========================================
# Install Fail2ban
# ===========================================
install_fail2ban() {
    log_info "Installing Fail2ban..."

    apt-get install -y fail2ban

    # Configure Fail2ban for SSH
    cat > /etc/fail2ban/jail.local << 'EOF'
[DEFAULT]
bantime = 3600
findtime = 600
maxretry = 5
ignoreip = 127.0.0.1/8

[sshd]
enabled = true
port = ssh
filter = sshd
logpath = /var/log/auth.log
maxretry = 3
bantime = 86400
EOF

    systemctl enable fail2ban
    systemctl restart fail2ban

    log_success "Fail2ban configured"
}

# ===========================================
# Setup Platform Directory
# ===========================================
setup_platform() {
    log_info "Setting up platform directory..."

    PLATFORM_DIR="/opt/edu-platform"

    # Create directory if it doesn't exist
    mkdir -p "$PLATFORM_DIR"

    # Copy files from script directory (assumes script is run from repo)
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

    if [[ -f "$SCRIPT_DIR/docker-compose.yml" ]]; then
        cp -r "$SCRIPT_DIR"/* "$PLATFORM_DIR"/
        log_success "Platform files copied to $PLATFORM_DIR"
    else
        log_warning "docker-compose.yml not found in parent directory"
        log_info "Please manually copy platform files to $PLATFORM_DIR"
    fi

    # Set ownership
    chown -R eduplatform:eduplatform "$PLATFORM_DIR"

    # Copy .env.example to .env if it doesn't exist
    if [[ -f "$PLATFORM_DIR/.env.example" ]] && [[ ! -f "$PLATFORM_DIR/.env" ]]; then
        cp "$PLATFORM_DIR/.env.example" "$PLATFORM_DIR/.env"
        log_info "Created .env from .env.example"
    fi
}

# ===========================================
# Configure Environment
# ===========================================
configure_env() {
    log_info "Configuring environment..."

    PLATFORM_DIR="/opt/edu-platform"

    if [[ -f "$PLATFORM_DIR/.env" ]]; then
        echo ""
        log_warning "Please edit the .env file with your settings:"
        echo ""
        echo "  nano $PLATFORM_DIR/.env"
        echo ""
        echo "Required changes:"
        echo "  1. Set DOMAIN to your domain name"
        echo "  2. Change all default passwords"
        echo "  3. Add your DEEPSEEK_API_KEY if using AI features"
        echo ""

        read -p "Do you want to edit .env now? (y/n) " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            nano "$PLATFORM_DIR/.env"
        fi
    else
        log_warning ".env file not found. Please create it manually."
    fi
}

# ===========================================
# Build Custom Images
# ===========================================
build_images() {
    log_info "Building custom Docker images..."

    PLATFORM_DIR="/opt/edu-platform"
    cd "$PLATFORM_DIR"

    # Build JupyterHub image
    log_info "Building JupyterHub image..."
    docker build -t edu-platform-jupyterhub:latest ./jupyterhub/

    # Build custom notebook image
    log_info "Building Jupyter notebook image (this may take 10-15 minutes)..."
    docker build -t edu-platform-notebook:latest ./jupyter-notebook/

    # Build DeepSeek proxy
    log_info "Building DeepSeek proxy image..."
    docker build -t edu-platform-deepseek-proxy:latest ./deepseek-proxy/

    log_success "All custom images built"
}

# ===========================================
# Start Services
# ===========================================
start_services() {
    log_info "Starting services..."

    PLATFORM_DIR="/opt/edu-platform"
    cd "$PLATFORM_DIR"

    # Start services
    docker compose up -d

    log_info "Waiting for services to be healthy..."
    sleep 30

    # Check service health
    docker compose ps

    log_success "Services started"
}

# ===========================================
# Print Summary
# ===========================================
print_summary() {
    echo ""
    echo "=========================================="
    echo -e "${GREEN}Educational Platform Setup Complete!${NC}"
    echo "=========================================="
    echo ""
    echo "Platform directory: /opt/edu-platform"
    echo ""
    echo "Next steps:"
    echo "  1. Ensure DNS A records point to this server's IP:"
    echo "     - learn.DOMAIN -> Server IP"
    echo "     - jupyter.DOMAIN -> Server IP"
    echo "     - code.DOMAIN -> Server IP"
    echo "     - ai.DOMAIN -> Server IP"
    echo ""
    echo "  2. Check service status:"
    echo "     cd /opt/edu-platform && docker compose ps"
    echo ""
    echo "  3. View logs:"
    echo "     docker compose logs -f"
    echo ""
    echo "  4. Access services (after DNS propagation):"
    echo "     - Moodle: https://learn.DOMAIN"
    echo "     - JupyterHub: https://jupyter.DOMAIN"
    echo "     - Code Server: https://code.DOMAIN"
    echo "     - AI Assistant: https://ai.DOMAIN"
    echo ""
    echo "  5. Install STACK plugin in Moodle:"
    echo "     See docs/STACK_SETUP.md for instructions"
    echo ""
    echo "  6. Create JupyterHub users:"
    echo "     See docs/JUPYTER_USAGE.md for instructions"
    echo ""
    echo "For troubleshooting, see docs/TROUBLESHOOTING.md"
    echo ""
}

# ===========================================
# Main Execution
# ===========================================
main() {
    echo ""
    echo "=========================================="
    echo "Educational Platform Setup Script"
    echo "=========================================="
    echo ""

    check_prerequisites
    update_system
    install_docker
    configure_firewall
    create_user
    configure_auto_updates
    configure_swap
    install_fail2ban
    setup_platform
    configure_env

    echo ""
    read -p "Do you want to build Docker images now? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        build_images
    else
        log_info "Skipping image build. Run 'docker compose build' later."
    fi

    echo ""
    read -p "Do you want to start services now? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        start_services
    else
        log_info "Skipping service start. Run 'docker compose up -d' later."
    fi

    print_summary
}

# Run main function
main "$@"
