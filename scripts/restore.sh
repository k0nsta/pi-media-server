#!/bin/bash

#############################################
# Restore Script for Pi Media Server
#############################################
# This script restores backed up configurations
# from the git repository to the running system
#############################################

set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(dirname "$SCRIPT_DIR")"
CONFIG_DIR="$REPO_DIR/config"

echo -e "${GREEN}Starting restore of service configurations...${NC}"

# Stop containers first
echo -e "${YELLOW}Stopping containers...${NC}"
cd "$REPO_DIR"
if docker compose version &> /dev/null; then
    docker compose down
else
    docker-compose down
fi

# Restore AdGuard Home configuration
echo -e "${YELLOW}Restoring AdGuard Home config...${NC}"
if [ -f "$CONFIG_DIR/adguard/AdGuardHome.yaml.backup" ]; then
    mkdir -p "$CONFIG_DIR/adguard/conf"
    cp "$CONFIG_DIR/adguard/AdGuardHome.yaml.backup" "$CONFIG_DIR/adguard/conf/AdGuardHome.yaml"
    echo "AdGuard config restored"
fi

# Restore TorrServ configuration
echo -e "${YELLOW}Restoring TorrServ config...${NC}"
if [ -f "$CONFIG_DIR/torrserv/config.json.backup" ]; then
    mkdir -p "$CONFIG_DIR/torrserv"
    cp "$CONFIG_DIR/torrserv/config.json.backup" "$CONFIG_DIR/torrserv/config.json"
    echo "TorrServ config restored"
fi

# Restore Lampac configuration
echo -e "${YELLOW}Restoring Lampac config...${NC}"
if [ -d "$CONFIG_DIR/lampac" ]; then
    find "$CONFIG_DIR/lampac" -name "*.backup" | while read backup_file; do
        original_file="${backup_file%.backup}"
        cp "$backup_file" "$original_file"
    done
    echo "Lampac config restored"
fi

# Restore iSponsorBlockTV configuration
echo -e "${YELLOW}Restoring iSponsorBlockTV config...${NC}"
if [ -f "$CONFIG_DIR/isponsorblocktv/config.json.backup" ]; then
    mkdir -p "$CONFIG_DIR/isponsorblocktv"
    cp "$CONFIG_DIR/isponsorblocktv/config.json.backup" "$CONFIG_DIR/isponsorblocktv/config.json"
    echo "iSponsorBlockTV config restored"
fi

# Set proper permissions
echo -e "${YELLOW}Setting permissions...${NC}"
chmod -R 755 "$CONFIG_DIR"

# Start containers
echo -e "${YELLOW}Starting containers...${NC}"
if docker compose version &> /dev/null; then
    docker compose up -d
else
    docker-compose up -d
fi

echo ""
echo -e "${GREEN}=========================================${NC}"
echo -e "${GREEN}Restore complete!${NC}"
echo -e "${GREEN}=========================================${NC}"
echo ""
echo "Services are starting up. Check status with:"
echo "  docker compose ps"
echo "  docker compose logs -f"
echo ""
