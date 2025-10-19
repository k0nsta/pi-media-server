#!/bin/bash

#############################################
# Backup Script for Pi Media Server
#############################################
# This script backs up critical configurations
# from running containers to the git repository
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

echo -e "${GREEN}Starting backup of service configurations...${NC}"

# Backup AdGuard Home configuration
echo -e "${YELLOW}Backing up AdGuard Home config...${NC}"
if [ -d "$CONFIG_DIR/adguard/conf" ]; then
    # Only backup the main config file, not databases/sessions
    if [ -f "$CONFIG_DIR/adguard/conf/AdGuardHome.yaml" ]; then
        sudo cp "$CONFIG_DIR/adguard/conf/AdGuardHome.yaml" "$CONFIG_DIR/adguard/AdGuardHome.yaml.backup"
        sudo chown $USER:$USER "$CONFIG_DIR/adguard/AdGuardHome.yaml.backup"
        echo "AdGuard config backed up"
    fi
fi

# Backup TorrServ configuration
echo -e "${YELLOW}Backing up TorrServ config...${NC}"
if [ -d "$CONFIG_DIR/torrserv" ]; then
    # Backup config files but not the database (too large)
    if [ -f "$CONFIG_DIR/torrserv/config.json" ]; then
        cp "$CONFIG_DIR/torrserv/config.json" "$CONFIG_DIR/torrserv/config.json.backup"
        echo "TorrServ config backed up"
    fi
fi

# Backup Lampac configuration
echo -e "${YELLOW}Backing up Lampac config...${NC}"
if [ -d "$CONFIG_DIR/lampac" ]; then
    # Backup settings files
    find "$CONFIG_DIR/lampac" -name "*.json" -o -name "*.conf" | while read file; do
        cp "$file" "$file.backup"
    done
    echo "Lampac config backed up"
fi

# Backup iSponsorBlockTV configuration
echo -e "${YELLOW}Backing up iSponsorBlockTV config...${NC}"
if [ -d "$CONFIG_DIR/isponsorblocktv" ]; then
    # Backup config files
    if [ -f "$CONFIG_DIR/isponsorblocktv/config.json" ]; then
        cp "$CONFIG_DIR/isponsorblocktv/config.json" "$CONFIG_DIR/isponsorblocktv/config.json.backup"
        echo "iSponsorBlockTV config backed up"
    fi
fi

echo ""
echo -e "${GREEN}=========================================${NC}"
echo -e "${GREEN}Backup complete!${NC}"
echo -e "${GREEN}=========================================${NC}"
echo ""
echo "Next steps:"
echo "1. Review changes:     git status"
echo "2. Add changes:        git add -A"
echo "3. Commit:             git commit -m 'Backup: $(date +%Y-%m-%d)'"
echo "4. Push to remote:     git push"
echo ""
echo -e "${YELLOW}IMPORTANT: Review files before committing to ensure no passwords are included!${NC}"
echo ""
