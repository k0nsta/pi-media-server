#!/bin/bash
set -e

#############################################
# Raspberry Pi Media Server - Automated Setup
#############################################
# This script will:
# 1. Update the system
# 2. Install Docker and Docker Compose
# 3. Clone this repository
# 4. Set up all media services
# 5. Start all containers
#############################################

echo "========================================="
echo "Raspberry Pi Media Server Setup"
echo "========================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
REPO_URL="https://github.com/k0nsta/pi-media-server.git"
INSTALL_DIR="$HOME/pi-media-server"

# Check if running as root
if [ "$EUID" -eq 0 ]; then
    echo -e "${RED}Please do not run this script as root or with sudo${NC}"
    echo "The script will ask for sudo password when needed"
    exit 1
fi

echo -e "${GREEN}Step 1: Updating system packages...${NC}"
sudo apt update
sudo apt upgrade -y

echo -e "${GREEN}Step 2: Installing required packages...${NC}"
sudo apt install -y \
    git \
    curl \
    vim \
    htop \
    net-tools \
    ca-certificates \
    gnupg \
    lsb-release

echo -e "${GREEN}Step 3: Installing Docker...${NC}"
if command -v docker &> /dev/null; then
    echo "Docker is already installed"
    docker --version
else
    # Install Docker using convenience script (recommended for Raspberry Pi)
    curl -fsSL https://get.docker.com -o get-docker.sh
    sudo sh get-docker.sh

    # Add current user to docker group
    sudo usermod -aG docker $USER

    # Clean up
    rm get-docker.sh

    echo -e "${YELLOW}Docker installed. You may need to log out and back in for group changes to take effect.${NC}"
fi

echo -e "${GREEN}Step 4: Installing Docker Compose...${NC}"
if command -v docker-compose &> /dev/null; then
    echo "Docker Compose is already installed"
    docker-compose --version
else
    # Install docker-compose plugin
    sudo apt install -y docker-compose-plugin
fi

echo -e "${GREEN}Step 5: Cloning repository...${NC}"
if [ -d "$INSTALL_DIR" ]; then
    echo "Directory $INSTALL_DIR already exists. Pulling latest changes..."
    cd "$INSTALL_DIR"
    git pull
else
    git clone "$REPO_URL" "$INSTALL_DIR"
    cd "$INSTALL_DIR"
fi

echo -e "${GREEN}Step 6: Creating directory structure...${NC}"
mkdir -p config/{adguard/{work,conf},torrserv,lampac,isponsorblocktv}

echo -e "${GREEN}Step 7: Setting permissions...${NC}"
# Ensure proper permissions for config directories
chmod -R 755 config/

echo -e "${GREEN}Step 8: Starting Docker containers...${NC}"
# Use docker compose (new command) or docker-compose (old command)
if docker compose version &> /dev/null; then
    docker compose pull
    docker compose up -d
else
    docker-compose pull
    docker-compose up -d
fi

echo ""
echo -e "${GREEN}=========================================${NC}"
echo -e "${GREEN}Setup Complete!${NC}"
echo -e "${GREEN}=========================================${NC}"
echo ""
echo "Your services are now running:"
echo ""
echo "  AdGuard Home:      http://$(hostname -I | awk '{print $1}'):80"
echo "                     Initial setup: http://$(hostname -I | awk '{print $1}'):3000"
echo "  TorrServ:          http://$(hostname -I | awk '{print $1}'):8090"
echo "  Lampac:            http://$(hostname -I | awk '{print $1}'):9118"
echo "  iSponsorBlockTV:   http://$(hostname -I | awk '{print $1}'):8008"
echo ""
echo "To view logs:        cd $INSTALL_DIR && docker compose logs -f"
echo "To stop services:    cd $INSTALL_DIR && docker compose down"
echo "To restart services: cd $INSTALL_DIR && docker compose restart"
echo ""
echo -e "${YELLOW}Note: If you just installed Docker, you may need to log out and back in.${NC}"
echo -e "${YELLOW}After that, run: cd $INSTALL_DIR && docker compose up -d${NC}"
echo ""
