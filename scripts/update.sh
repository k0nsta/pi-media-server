#!/bin/bash

INSTALL_DIR="$HOME/pi-media-server"
cd "$INSTALL_DIR" || exit 1

echo "========================================="
echo "Updating Pi Media Server"
echo "========================================="
echo ""

echo "Step 1: Pulling latest images..."
if docker compose version &> /dev/null; then
    docker compose pull
else
    docker-compose pull
fi

echo ""
echo "Step 2: Recreating containers..."
if docker compose version &> /dev/null; then
    docker compose up -d
else
    docker-compose up -d
fi

echo ""
echo "Step 3: Cleaning up old images..."
docker image prune -f

echo ""
echo "========================================="
echo "Update Complete!"
echo "========================================="
echo ""

./scripts/health-check.sh
