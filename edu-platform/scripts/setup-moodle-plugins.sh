#!/bin/bash
# ===========================================
# Moodle Plugin Installer
# ===========================================
# Downloads and installs popular Moodle plugins
# Run after Moodle container starts
# ===========================================

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

MOODLE_CONTAINER="${1:-moodle}"

echo -e "${BLUE}============================================${NC}"
echo -e "${BLUE}   Moodle Plugin Installer${NC}"
echo -e "${BLUE}============================================${NC}"

# Wait for Moodle to be ready
echo -e "${YELLOW}Waiting for Moodle to be ready...${NC}"
until docker exec "$MOODLE_CONTAINER" curl -sf http://localhost:8080/login/index.php > /dev/null 2>&1; do
    sleep 10
    echo -n "."
done
echo ""
echo -e "${GREEN}Moodle is ready!${NC}"

# Plugin definitions: name|type|url
PLUGINS=(
    # H5P - Interactive Content
    "mod_hvp|mod|https://moodle.org/plugins/download.php/32108/mod_hvp_moodle44_2024100700.zip"

    # Level Up XP - Gamification
    "block_xp|block|https://moodle.org/plugins/download.php/31970/block_xp_moodle44_2024092000.zip"

    # Completion Progress - Visual progress bar
    "block_completion_progress|block|https://moodle.org/plugins/download.php/31567/block_completion_progress_moodle44_2024062400.zip"

    # Attendance - Track student attendance
    "mod_attendance|mod|https://moodle.org/plugins/download.php/32167/mod_attendance_moodle44_2024110500.zip"

    # Custom Certificate - Generate certificates
    "mod_customcert|mod|https://moodle.org/plugins/download.php/32002/mod_customcert_moodle44_2024100100.zip"

    # Board - Kanban-style course format
    "format_board|format|https://moodle.org/plugins/download.php/31891/format_board_moodle44_2024090200.zip"

    # Tiles - Visual course tiles
    "format_tiles|format|https://moodle.org/plugins/download.php/32047/format_tiles_moodle44_2024101500.zip"

    # STACK - Math questions with Maxima (and required dependencies)
    "qtype_stack|question|https://moodle.org/plugins/download.php/32187/qtype_stack_moodle44_2024111100.zip"
    "qbehaviour_adaptivemultipart|question|https://moodle.org/plugins/download.php/32188/qbehaviour_adaptivemultipart_moodle44_2024111100.zip"
    "qbehaviour_dfexplicitvaildate|question|https://moodle.org/plugins/download.php/32189/qbehaviour_dfexplicitvaildate_moodle44_2024111100.zip"
    "qbehaviour_dfcbmexplicitvaildate|question|https://moodle.org/plugins/download.php/32190/qbehaviour_dfcbmexplicitvaildate_moodle44_2024111100.zip"
)

echo -e "${BLUE}Installing ${#PLUGINS[@]} plugins...${NC}"
echo ""

for plugin_def in "${PLUGINS[@]}"; do
    IFS='|' read -r name type url <<< "$plugin_def"

    echo -e "${YELLOW}Installing: ${NC}$name"

    # Determine installation directory based on type
    if [[ "$type" == "question" ]]; then
        if [[ "$name" == qtype_* ]]; then
            install_dir="/bitnami/moodle/question/type"
        elif [[ "$name" == qbehaviour_* ]]; then
            install_dir="/bitnami/moodle/question/behaviour"
        else
            install_dir="/bitnami/moodle/question"
        fi
    else
        install_dir="/bitnami/moodle/$type"
    fi

    # Download plugin to temp
    docker exec "$MOODLE_CONTAINER" bash -c "
        cd /tmp
        curl -sL '$url' -o plugin.zip
        unzip -q -o plugin.zip -d $install_dir/
        rm plugin.zip
    " 2>/dev/null || echo -e "${RED}  Failed to download $name${NC}"

    echo -e "${GREEN}  Done${NC}"
done

# Upgrade Moodle database to install plugins
echo ""
echo -e "${BLUE}Upgrading Moodle database...${NC}"
docker exec "$MOODLE_CONTAINER" php /bitnami/moodle/admin/cli/upgrade.php --non-interactive 2>/dev/null || true

# Configure STACK to use Maxima (goemaxima)
echo -e "${BLUE}Configuring STACK for Maxima...${NC}"
docker exec "$MOODLE_CONTAINER" php /bitnami/moodle/admin/cli/cfg.php --component=qtype_stack --name=platform --set=server 2>/dev/null || true
docker exec "$MOODLE_CONTAINER" php /bitnami/moodle/admin/cli/cfg.php --component=qtype_stack --name=maximacommand --set="http://maxima:8080/goemaxima" 2>/dev/null || true
docker exec "$MOODLE_CONTAINER" php /bitnami/moodle/admin/cli/cfg.php --component=qtype_stack --name=maximaversion --set="5.47.0" 2>/dev/null || true
docker exec "$MOODLE_CONTAINER" php /bitnami/moodle/admin/cli/cfg.php --component=qtype_stack --name=plotcommand --set="gnuplot" 2>/dev/null || true

# Clear caches
echo -e "${BLUE}Clearing Moodle caches...${NC}"
docker exec "$MOODLE_CONTAINER" php /bitnami/moodle/admin/cli/purge_caches.php 2>/dev/null || true

echo ""
echo -e "${GREEN}============================================${NC}"
echo -e "${GREEN}   Plugin installation complete!${NC}"
echo -e "${GREEN}============================================${NC}"
echo ""
echo "Installed plugins:"
for plugin_def in "${PLUGINS[@]}"; do
    IFS='|' read -r name type url <<< "$plugin_def"
    echo "  - $name"
done
echo ""
echo -e "${YELLOW}Note: Visit Site Administration > Notifications to complete setup${NC}"
echo -e "${YELLOW}STACK: Site Admin > Plugins > Question types > STACK > Healthcheck${NC}"
