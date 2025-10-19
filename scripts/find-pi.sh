#!/bin/bash

#############################################
# Find Raspberry Pi on Network
#############################################
# This script helps locate your Pi when
# you can't connect via SSH
#############################################

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}=========================================${NC}"
echo -e "${BLUE}Raspberry Pi Network Scanner${NC}"
echo -e "${BLUE}=========================================${NC}"
echo ""

# Method 1: Try hostname
echo -e "${YELLOW}[1/4] Trying raspberrypi.local...${NC}"
if ping -c 1 -W 1 raspberrypi.local &> /dev/null; then
    IP=$(ping -c 1 raspberrypi.local | grep -oE '([0-9]{1,3}\.){3}[0-9]{1,3}' | head -1)
    echo -e "   ${GREEN}✓ Found at: $IP${NC}"
    echo -e "   ${GREEN}Try: ssh pi@raspberrypi.local${NC}"

    # Check if SSH is open
    if nc -z -w 1 "$IP" 22 2>/dev/null; then
        echo -e "   ${GREEN}✓ SSH port 22 is OPEN${NC}"
    else
        echo -e "   ${RED}✗ SSH port 22 is CLOSED${NC}"
    fi
else
    echo -e "   ${RED}✗ Not found via hostname${NC}"
fi

echo ""

# Method 2: Try common IPs
echo -e "${YELLOW}[2/4] Checking common Pi IP addresses...${NC}"
COMMON_IPS=("192.168.1.2" "192.168.1.100" "192.168.0.2" "192.168.0.100")

for IP in "${COMMON_IPS[@]}"; do
    if ping -c 1 -W 1 "$IP" &> /dev/null; then
        echo -e "   ${GREEN}✓ Responding: $IP${NC}"
        if nc -z -w 1 "$IP" 22 2>/dev/null; then
            echo -e "     ${GREEN}✓ SSH is open - Try: ssh pi@$IP${NC}"
        else
            echo -e "     ${YELLOW}⚠ SSH is closed${NC}"
        fi
    fi
done

echo ""

# Method 3: Network scan with nmap
echo -e "${YELLOW}[3/4] Scanning network for Raspberry Pi devices...${NC}"

if ! command -v nmap &> /dev/null; then
    echo -e "   ${YELLOW}⚠ nmap not installed${NC}"
    echo -e "   Install with: ${BLUE}brew install nmap${NC} (macOS) or ${BLUE}sudo apt install nmap${NC} (Linux)"
else
    # Detect network
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS
        INTERFACE=$(route get default 2>/dev/null | grep interface | awk '{print $2}')
        if [ -n "$INTERFACE" ]; then
            NETWORK=$(ifconfig "$INTERFACE" | grep "inet " | awk '{print $2}' | sed 's/\.[0-9]*$/.0\/24/')
        fi
    else
        # Linux
        NETWORK=$(ip route | grep default | awk '{print $3}' | sed 's/\.[0-9]*$/.0\/24/')
    fi

    if [ -z "$NETWORK" ]; then
        NETWORK="192.168.1.0/24"
        echo -e "   ${YELLOW}Using default network: $NETWORK${NC}"
    else
        echo -e "   Scanning network: ${BLUE}$NETWORK${NC}"
    fi

    echo -e "   ${YELLOW}This may take a minute...${NC}"

    # Scan and find Raspberry Pi devices
    FOUND_DEVICES=$(nmap -sn "$NETWORK" 2>/dev/null | grep -B 2 "Raspberry Pi" | grep "Nmap scan" | awk '{print $5}')

    if [ -n "$FOUND_DEVICES" ]; then
        echo -e "   ${GREEN}✓ Found Raspberry Pi device(s):${NC}"
        while IFS= read -r DEVICE_IP; do
            echo -e "     ${GREEN}• $DEVICE_IP${NC}"

            # Check SSH port
            if nc -z -w 1 "$DEVICE_IP" 22 2>/dev/null; then
                echo -e "       ${GREEN}✓ SSH is open - Try: ssh pi@$DEVICE_IP${NC}"
            else
                echo -e "       ${YELLOW}⚠ SSH is closed${NC}"
            fi
        done <<< "$FOUND_DEVICES"
    else
        echo -e "   ${RED}✗ No Raspberry Pi devices found${NC}"
    fi
fi

echo ""

# Method 4: Check ARP table
echo -e "${YELLOW}[4/4] Checking ARP table for known Pi MAC addresses...${NC}"
echo -e "   ${YELLOW}Looking for Raspberry Pi Foundation MACs (B8:27:EB, DC:A6:32, E4:5F:01, D8:3A:DD)${NC}"

if [[ "$OSTYPE" == "darwin"* ]]; then
    # macOS
    ARP_ENTRIES=$(arp -a | grep -i "b8:27:eb\|dc:a6:32\|e4:5f:01\|d8:3a:dd")
else
    # Linux
    ARP_ENTRIES=$(arp -n | grep -i "b8:27:eb\|dc:a6:32\|e4:5f:01\|d8:3a:dd")
fi

if [ -n "$ARP_ENTRIES" ]; then
    echo -e "   ${GREEN}✓ Found Pi MAC address(es):${NC}"
    echo "$ARP_ENTRIES" | while IFS= read -r line; do
        echo -e "     ${GREEN}$line${NC}"
    done
else
    echo -e "   ${RED}✗ No Pi MAC addresses in ARP table${NC}"
fi

echo ""
echo -e "${BLUE}=========================================${NC}"
echo -e "${BLUE}Summary${NC}"
echo -e "${BLUE}=========================================${NC}"
echo ""

echo -e "${YELLOW}If your Pi was not found:${NC}"
echo "  1. Check physical connections (power, ethernet cable)"
echo "  2. Check LED indicators:"
echo "     • Red LED = Power (should be solid)"
echo "     • Green LED = Activity (should blink during boot)"
echo "  3. Connect a monitor and keyboard for direct access"
echo "  4. SD card may be corrupted - reflash if needed"
echo ""
echo -e "${YELLOW}Useful commands:${NC}"
echo "  • Force IP refresh:  sudo arp -d -a (then run this script again)"
echo "  • Check router:      Login to router admin panel and check DHCP clients"
echo "  • Serial console:    Connect via GPIO UART pins"
echo ""
echo -e "For detailed troubleshooting: ${BLUE}docs/SSH-TROUBLESHOOTING.md${NC}"
echo ""
