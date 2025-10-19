# SSH Connection Troubleshooting

## Error: "No route to host"

This means your computer cannot reach the Raspberry Pi at all on the network.

---

## Quick Diagnostics

### 1. Check if Pi is on Network

```bash
# Try to ping the Pi
ping 192.168.1.2

# If that fails, try by hostname
ping raspberrypi.local

# Scan entire network for the Pi
nmap -sn 192.168.1.0/24 | grep -B 2 "Raspberry"
```

**Results:**
- ✅ **Ping works**: Pi is online, but SSH might be blocked → See [SSH Service Issues](#ssh-service-issues)
- ❌ **No response**: Pi is not reachable → Continue below

### 2. Find Pi's Current IP Address

The Pi may have gotten a different IP after reboot.

```bash
# Scan your network (adjust range to your network)
sudo nmap -sn 192.168.1.0/24

# Look for:
# - "Raspberry Pi Foundation" in manufacturer
# - MAC addresses starting with: B8:27:EB, DC:A6:32, E4:5F:01
```

**Check your router:**
- Login to router admin panel (usually 192.168.1.1 or 192.168.0.1)
- Look at DHCP client list
- Find device named "raspberrypi" or with Raspberry Pi MAC

### 3. Physical Checks

**Power:**
- ✅ Red LED on = Power is good
- ❌ No red LED = Check power supply/cable

**Boot status:**
- ✅ Green LED blinking = Booting/running normally
- ⚠️ Green LED solid = SD card issue
- ❌ No green LED = Not booting (likely SD card corruption)

**Network:**
- ✅ Ethernet: Link lights on port
- ⚠️ WiFi: No visible indicator, needs configuration

---

## Common Issues & Solutions

### Issue 1: SD Card Corruption (Most Common)

**Symptoms:**
- No green LED activity, or constant green LED
- Pi was working before power outage
- Can't find Pi on network

**Solution:**
- SD card is corrupted, needs reflashing
- Follow [Quick Recovery Guide](../README.md#quick-recovery-after-power-failure)

**Prevention:**
- Use read-only filesystem (see [Prevention Guide](#preventing-future-issues))
- Add UPS or power backup
- Use high-quality SD card (Samsung EVO, SanDisk Extreme)

---

### Issue 2: IP Address Changed

**Symptoms:**
- Pi shows up on network scan but at different IP
- Can ping raspberrypi.local but not the old IP

**Solution:**

**Option A: Connect using hostname**
```bash
ssh pi@raspberrypi.local
```

**Option B: Find new IP and connect**
```bash
# Find the new IP
nmap -sn 192.168.1.0/24 | grep -B 2 "Raspberry"

# Connect with new IP
ssh pi@NEW_IP_ADDRESS
```

**Option C: Set static IP (recommended)**
```bash
# Edit dhcpcd.conf
sudo nano /etc/dhcpcd.conf

# Add at the end:
interface eth0
static ip_address=192.168.1.2/24
static routers=192.168.1.1
static domain_name_servers=192.168.1.1 8.8.8.8

# Restart networking
sudo systemctl restart dhcpcd
```

**Option D: Reserve IP in router (easiest)**
- Login to router admin
- Find DHCP settings
- Add reservation: MAC address → 192.168.1.2

---

### Issue 3: SSH Service Not Running

**Symptoms:**
- Can ping the Pi
- Connection refused or timeout on port 22

**Diagnostic:**
```bash
# Check if SSH port is open
nmap -p 22 192.168.1.2
```

**Solution (requires physical access):**

1. Connect monitor and keyboard to Pi
2. Login (default: username `pi`, password `raspberry`)
3. Enable and start SSH:
```bash
# Enable SSH
sudo systemctl enable ssh
sudo systemctl start ssh

# Verify it's running
sudo systemctl status ssh
```

---

### Issue 4: Firewall Blocking SSH

**Symptoms:**
- Can ping the Pi
- Port 22 shows as "filtered" in nmap

**Solution (requires physical access):**
```bash
# Check firewall status
sudo ufw status

# If active, allow SSH
sudo ufw allow 22/tcp

# Or disable firewall (not recommended)
sudo ufw disable
```

---

### Issue 5: WiFi Not Connected

**Symptoms:**
- Pi was using WiFi
- Can't find Pi on network after reboot

**Solution (requires physical access or Ethernet):**

1. Connect via Ethernet temporarily, or use monitor/keyboard
2. Configure WiFi:
```bash
# Edit wpa_supplicant
sudo nano /etc/wpa_supplicant/wpa_supplicant.conf

# Add your network:
network={
    ssid="YOUR_WIFI_NAME"
    psk="YOUR_WIFI_PASSWORD"
}

# Restart WiFi
sudo systemctl restart wpa_supplicant
sudo ifconfig wlan0 down
sudo ifconfig wlan0 up
```

Or use `raspi-config`:
```bash
sudo raspi-config
# System Options → Wireless LAN
```

---

## Preventing Future Issues

### 1. Set Static IP or DHCP Reservation

**Method A: Static IP on Pi**
```bash
sudo nano /etc/dhcpcd.conf

# Add:
interface eth0
static ip_address=192.168.1.2/24
static routers=192.168.1.1
static domain_name_servers=192.168.1.1
```

**Method B: DHCP Reservation (recommended)**
- Configure in router settings
- Binds MAC address to specific IP
- Survives SD card reflash

### 2. Enable SSH by Default

**For existing Pi:**
```bash
sudo systemctl enable ssh
```

**For fresh install:**
- When flashing SD card, create empty file named `ssh` in boot partition
- Or use Raspberry Pi Imager and enable SSH in settings

### 3. Hardware Protection

**Power:**
- UPS (Uninterruptible Power Supply)
- Battery backup HAT for Raspberry Pi
- Capacitor-based power backup

**Storage:**
- Use industrial-grade SD card
- Boot from USB SSD (more reliable)
- Regular backups (automated with this repo)

### 4. Software Protection

**Read-only filesystem:**
```bash
sudo apt install overlayroot
echo 'overlayroot="tmpfs"' | sudo tee -a /etc/overlayroot.conf
sudo reboot
```

**Boot from USB SSD:**
- More reliable than SD card
- Faster
- Less prone to corruption

---

## Emergency Access Methods

### Method 1: Physical Access (Most Reliable)

1. Connect HDMI monitor and USB keyboard
2. Login at console
3. Run diagnostics:
```bash
# Check network
ip addr show

# Check SSH
sudo systemctl status ssh

# Check logs
journalctl -xe
```

### Method 2: Serial Console (Advanced)

If you have a USB-to-TTL serial adapter:
```bash
# Connect to Pi's GPIO pins (GND, TX, RX)
# From your computer:
screen /dev/ttyUSB0 115200
# Or
minicom -D /dev/ttyUSB0 -b 115200
```

### Method 3: SD Card Recovery

1. Remove SD card from Pi
2. Insert into computer
3. Mount boot partition
4. Create `ssh` file to enable SSH:
```bash
# On macOS/Linux
touch /Volumes/boot/ssh

# On Windows
# Create empty file named "ssh" (no extension) in boot drive
```

---

## Diagnostic Script

Save this as `find-pi.sh`:

```bash
#!/bin/bash

echo "Searching for Raspberry Pi on network..."
echo ""

# Method 1: Try hostname
echo "1. Trying raspberrypi.local..."
if ping -c 1 raspberrypi.local &> /dev/null; then
    IP=$(ping -c 1 raspberrypi.local | grep -oE '([0-9]{1,3}\.){3}[0-9]{1,3}' | head -1)
    echo "   ✓ Found at: $IP"
    echo "   Try: ssh pi@raspberrypi.local"
else
    echo "   ✗ Not found via hostname"
fi

echo ""

# Method 2: Network scan
echo "2. Scanning network for Raspberry Pi devices..."
if command -v nmap &> /dev/null; then
    # Get your network range
    NETWORK=$(ip route | grep default | awk '{print $3}' | sed 's/\.[0-9]*$/.0\/24/')
    echo "   Scanning $NETWORK..."

    nmap -sn "$NETWORK" 2>/dev/null | grep -B 2 "Raspberry" | grep "Nmap scan" | awk '{print $5}'

    echo ""
    echo "3. Checking for open SSH ports..."
    # Check common IPs
    for i in {2..254}; do
        IP=$(echo "$NETWORK" | sed "s/\.0\/24/.$i/")
        if timeout 0.5 bash -c "echo >/dev/tcp/$IP/22" 2>/dev/null; then
            echo "   ✓ SSH open on: $IP"
            echo "     Try: ssh pi@$IP"
        fi
    done
else
    echo "   ! nmap not installed. Install with: brew install nmap"
fi

echo ""
echo "If not found:"
echo "  - Check physical connections (power, ethernet)"
echo "  - Check LED indicators (red=power, green=activity)"
echo "  - Try connecting monitor and keyboard"
echo "  - See: docs/SSH-TROUBLESHOOTING.md"
```

Usage:
```bash
chmod +x find-pi.sh
./find-pi.sh
```

---

## When All Else Fails

If nothing works and Pi won't respond:

1. **SD card is likely corrupted** → Reflash
2. **Follow Quick Recovery**: See [README.md](../README.md#quick-recovery-after-power-failure)
3. **Recovery time**: 5-10 minutes with this automated setup

---

## Getting Help

If you're still stuck:

1. Check Pi's LED patterns and compare with [official docs](https://www.raspberrypi.com/documentation/computers/configuration.html#led-warning-flash-codes)
2. Try with a fresh SD card to rule out corruption
3. Check power supply (needs 5V 3A for Pi 4)
4. Look for hardware damage after power surge

---

## Quick Reference

| Symptom | Likely Cause | Solution |
|---------|--------------|----------|
| No LEDs at all | No power | Check power supply/cable |
| Red LED only, no green | SD card issue | Reflash SD card |
| Green LED solid | Boot failure | Reflash SD card |
| Ping fails | Not on network | Check IP/network |
| Ping works, SSH fails | SSH not running | Enable SSH (needs physical access) |
| Different IP | DHCP changed IP | Set static IP or find new IP |
