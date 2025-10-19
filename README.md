# Raspberry Pi Media Server

Automated setup and disaster recovery for a Raspberry Pi media server running AdGuard Home, TorrServ, Lampac, and iSponsorBlockTV.

## Services

- **AdGuard Home** - Network-wide ad blocking and DNS server
- **TorrServ** - Torrent streaming server
- **Lampac** - IPTV proxy server
- **iSponsorBlockTV** - YouTube ad blocker for smart TVs

## Quick Recovery (After Power Failure)

If your Raspberry Pi becomes unresponsive after a power outage:

### 1. Flash Fresh Raspberry Pi OS
- Download [Raspberry Pi Imager](https://www.raspberrypi.com/software/)
- Flash Raspberry Pi OS Lite (64-bit recommended)
- **Important**: In imager settings, enable SSH and set username/password

### 2. Boot and SSH In
```bash
ssh pi@raspberrypi.local
# or
ssh pi@<IP_ADDRESS>
```

### 3. Run Automated Setup (One Command)
```bash
curl -sSL https://raw.githubusercontent.com/k0nsta/pi-media-server/main/setup.sh | bash
```

**That's it!** In 5-10 minutes, all services will be running.

---

## Manual Setup (Detailed)

### Initial Setup

1. **Clone this repository**
```bash
git clone https://github.com/k0nsta/pi-media-server.git
cd pi-media-server
```

2. **Run setup script**
```bash
chmod +x setup.sh
./setup.sh
```

3. **Configure services**

After first boot, configure each service:

- **AdGuard Home**: http://YOUR_PI_IP:3000 (initial setup)
  - After setup: http://YOUR_PI_IP:80
- **TorrServ**: http://YOUR_PI_IP:5665
- **Lampac**: http://YOUR_PI_IP:9118
- **iSponsorBlockTV**: http://YOUR_PI_IP:8008

---

## Manual Docker Commands

### View running containers
```bash
cd ~/pi-media-server
docker compose ps
```

### View logs
```bash
# All services
docker compose logs -f

# Specific service
docker compose logs -f adguard
docker compose logs -f torrserv
```

### Restart services
```bash
# Restart all
docker compose restart

# Restart specific service
docker compose restart adguard
```

### Stop all services
```bash
docker compose down
```

### Start all services
```bash
docker compose up -d
```

### Update containers
```bash
docker compose pull
docker compose up -d
```

---

## Directory Structure

```
pi-media-server/
├── docker-compose.yml          # Service definitions
├── setup.sh                    # Automated setup script
├── .gitignore                  # Git ignore rules
├── README.md                   # This file
├── config/                     # Service configurations (generated at runtime)
│   ├── adguard/
│   ├── torrserv/
│   ├── lampac/
│   └── isponsorblocktv/
└── scripts/
    ├── health-check.sh        # Check service status
    ├── update.sh              # Update containers
    └── find-pi.sh             # Network scanning utility
```

---

## Preventing SD Card Corruption

Power failures are the main cause of SD card corruption. Consider:

### 1. Hardware Solutions
- **UPS (Uninterruptible Power Supply)** - Best option
- **Power bank with auto-switching** - Budget option
- **External SSD** - Move Docker volumes to USB SSD

### 2. Software Solutions (Advanced)

**Enable read-only root filesystem:**
```bash
# Install overlayroot
sudo apt install overlayroot

# Enable it
echo 'overlayroot="tmpfs"' | sudo tee -a /etc/overlayroot.conf
sudo reboot
```

**Move Docker data to external USB/SSD:**
```bash
# Stop Docker
sudo systemctl stop docker

# Move Docker data
sudo mv /var/lib/docker /mnt/external-drive/docker

# Create symlink
sudo ln -s /mnt/external-drive/docker /var/lib/docker

# Update fstab to auto-mount USB drive
# Add this line to /etc/fstab:
# UUID=YOUR_USB_UUID /mnt/external-drive ext4 defaults,nofail 0 2

sudo systemctl start docker
```

---

## Troubleshooting

### Services won't start
```bash
# Check Docker status
sudo systemctl status docker

# Check container logs
docker compose logs

# Restart Docker daemon
sudo systemctl restart docker
docker compose up -d
```

### Port conflicts
If port 80 or 53 is already in use, edit `docker-compose.yml` and change the port mappings.

### Permission issues
```bash
# Fix config directory permissions
chmod -R 755 ~/pi-media-server/config
```

### Can't pull images
```bash
# Check internet connection
ping -c 3 google.com

# Manually pull images
docker pull adguard/adguardhome:latest
docker pull ghcr.io/yourok/torrserver:latest
docker pull immisterio/lampac:latest
docker pull ghcr.io/dmunozv04/isponsorblocktv:latest
```

---

## Updating

### Update this repository
```bash
cd ~/pi-media-server
git pull
```

### Update Docker containers
```bash
cd ~/pi-media-server
docker compose pull
docker compose up -d
```

### Update system
```bash
sudo apt update
sudo apt upgrade -y
```

---

## Port Reference

| Service          | Port(s)                  | Purpose                |
|------------------|--------------------------|------------------------|
| AdGuard Home     | 53 (TCP/UDP)            | DNS                    |
|                  | 80, 443                  | Web UI                 |
|                  | 3000                     | Initial setup          |
|                  | 853                      | DNS-over-TLS           |
| TorrServ         | 5665                     | Web UI & API           |
| Lampac           | 9118                     | Web UI & API           |
| iSponsorBlockTV  | 8008                     | Web UI                 |

---

## Security Notes

- Change default passwords for all services
- Consider running AdGuard on a different port than 80 (edit docker-compose.yml)
- Enable HTTPS for AdGuard Home
- Don't expose TorrServ to the internet without authentication
- Keep your Raspberry Pi updated: `sudo apt update && sudo apt upgrade -y`

---

## Contributing

Feel free to submit issues or pull requests if you have improvements!

---

## License

MIT License - Feel free to use and modify for your own setup.

---

## Credits

- [AdGuard Home](https://github.com/AdguardTeam/AdGuardHome)
- [TorrServ](https://github.com/YouROK/TorrServer)
- [Lampac](https://github.com/immisterio/Lampac)
- [iSponsorBlockTV](https://github.com/dmunozv04/iSponsorBlockTV)
