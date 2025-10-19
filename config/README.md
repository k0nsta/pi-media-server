# Service Configuration

This directory contains configuration files for all services. Configurations are created automatically on first run.

## Directory Structure

```
config/
├── adguard/
│   ├── conf/          # AdGuard configuration (backed up)
│   └── work/          # Runtime data (not backed up)
├── torrserv/          # TorrServ configuration
├── lampac/            # Lampac configuration
└── isponsorblocktv/   # iSponsorBlockTV configuration
```

## First Time Setup

### AdGuard Home
1. Access: `http://YOUR_PI_IP:3000`
2. Follow setup wizard
3. After setup, access at: `http://YOUR_PI_IP:80`

### TorrServ
1. Access: `http://YOUR_PI_IP:8090`
2. No initial setup required
3. Upload torrent files or add magnet links

### Lampac
1. Access: `http://YOUR_PI_IP:9118`
2. Configure IPTV sources in settings

### iSponsorBlockTV
1. Access: `http://YOUR_PI_IP:8008`
2. Follow pairing instructions for your TV

## Backup

Run backup script to save configurations:
```bash
cd ~/pi-media-server
./scripts/backup.sh
```

## Restore

Restore from backed up configurations:
```bash
cd ~/pi-media-server
./scripts/restore.sh
```
