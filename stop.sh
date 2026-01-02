#!/bin/bash
# ===========================================
# Educational Platform - Stop Script
# ===========================================

set -e

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

PLATFORM_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/edu-platform" && pwd)"

# Check if user wants to view logs
if [[ "$1" == "logs" ]]; then
    echo -e "${BLUE}ℹ${NC} Showing logs (Ctrl+C to exit)..."
    cd "$PLATFORM_DIR"

    # Include optional compose file if it exists
    COMPOSE_FILES="-f docker-compose.yml -f docker-compose.override.yml"
    if [[ -f "docker-compose.optional.yml" ]]; then
        COMPOSE_FILES="$COMPOSE_FILES -f docker-compose.optional.yml"
    fi

    docker compose $COMPOSE_FILES logs -f
    exit 0
fi

echo -e "${BLUE}ℹ${NC} Stopping Educational Platform..."

cd "$PLATFORM_DIR"

# Stop all services including optional ones
COMPOSE_FILES="-f docker-compose.yml -f docker-compose.override.yml"
if [[ -f "docker-compose.optional.yml" ]]; then
    COMPOSE_FILES="$COMPOSE_FILES -f docker-compose.optional.yml"
fi

docker compose $COMPOSE_FILES down

echo -e "${GREEN}✓${NC} Platform stopped successfully"
echo ""
echo -e "${YELLOW}Note:${NC} Your data is preserved in Docker volumes"
echo -e "      To start again, run: ${BLUE}./start.sh${NC}"
echo -e "      To remove all data, run: ${BLUE}docker compose down -v${NC}"
echo ""
