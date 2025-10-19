#!/bin/bash

INSTALL_DIR="$HOME/pi-media-server"
cd "$INSTALL_DIR" || exit 1

echo "========================================="
echo "Pi Media Server Health Check"
echo "========================================="
echo ""

SERVICES=("adguard" "torrserv" "lampac" "isponsorblocktv")
ALL_HEALTHY=true

for service in "${SERVICES[@]}"; do
    status=$(docker inspect -f '{{.State.Status}}' "$service" 2>/dev/null)

    if [ "$status" == "running" ]; then
        echo "✓ $service: running"
    elif [ "$status" == "restarting" ]; then
        echo "⚠ $service: restarting"
        ALL_HEALTHY=false
    else
        echo "✗ $service: stopped or not found"
        ALL_HEALTHY=false
    fi
done

echo ""
echo "Docker disk usage:"
docker system df

if [ "$ALL_HEALTHY" = true ]; then
    echo ""
    echo "All services are healthy!"
    exit 0
else
    echo ""
    echo "Some services need attention!"
    exit 1
fi
