# Cassidy Asphalt - Digital Signage Kiosk System

A Raspberry Pi 4-based kiosk solution for displaying Smartsheet crew schedules on conference room monitors.

## Project Overview

**Client:** Cassidy Asphalt & Paving
**Developer:** Fructify LLC (Mike Farley)
**Version:** 1.0.0
**Last Updated:** February 2026

### Purpose

Display crew schedules and calendars published from Smartsheet on large monitors in the conference room. Each of the 6 work crews has a dedicated display showing their schedule in real-time.

### Architecture

```
┌─────────────────┐     ┌─────────────────┐     ┌─────────────────┐
│   Smartsheet    │────▶│  Published URL  │────▶│   Pi 4 Kiosk    │
│   (Source)      │     │  (Read-Only)    │     │   (Display)     │
└─────────────────┘     └─────────────────┘     └─────────────────┘
                                                        │
                                                        ▼
                                                ┌─────────────────┐
                                                │  HDMI Monitor   │
                                                │  (Conference)   │
                                                └─────────────────┘
```

## Hardware Requirements

### Per Kiosk Station
- Raspberry Pi 4 Model B (4GB RAM recommended)
- 32GB+ microSD card (Class 10 or better)
- Official Raspberry Pi power supply (5V 3A USB-C)
- Micro HDMI to HDMI cable
- Monitor with HDMI input
- Ethernet cable (recommended) or WiFi access
- Case with passive cooling (optional but recommended)

### For 6 Crews
| Item | Quantity | Notes |
|------|----------|-------|
| Raspberry Pi 4 (4GB) | 6 | One per crew display |
| 32GB microSD cards | 6 | Plus 2 spares recommended |
| Power supplies | 6 | Official Pi USB-C PSU |
| HDMI cables | 6 | Micro HDMI to standard HDMI |
| Monitors | 6 | 43"+ recommended for visibility |

## Software Stack

- **OS:** Raspberry Pi OS Lite (64-bit)
- **Display Server:** Wayland (wlroots via cage)
- **Browser:** Chromium (kiosk mode)
- **Management:** SSH + optional VNC

## Quick Start

### 1. Prepare the SD Card

1. Download [Raspberry Pi Imager](https://www.raspberrypi.com/software/)
2. Select "Raspberry Pi OS Lite (64-bit)"
3. Click the gear icon to pre-configure:
   - Set hostname (e.g., `crew1-kiosk`)
   - Enable SSH
   - Set username/password
   - Configure WiFi (if not using Ethernet)
   - Set locale/timezone

### 2. First Boot Setup

```bash
# SSH into the Pi
ssh pi@crew1-kiosk.local

# Update the system
sudo apt update && sudo apt upgrade -y

# Clone or copy this project
# (from USB or network share)
```

### 3. Run Installation

```bash
# Make install script executable
chmod +x scripts/install.sh

# Run the installer
sudo ./scripts/install.sh
```

### 4. Configure URLs

Edit `config/urls.conf` with your Smartsheet published URLs:

```bash
sudo nano /opt/kiosk/config/urls.conf
```

### 5. Reboot

```bash
sudo reboot
```

The Pi will boot directly into the kiosk display.

## Project Structure

```
Pi4/
├── README.md                 # This file
├── config/
│   ├── urls.conf            # Smartsheet URLs for each crew
│   ├── kiosk.conf           # Kiosk behavior settings
│   └── network.conf.example # Network configuration template
├── scripts/
│   ├── install.sh           # Main installation script
│   ├── kiosk-start.sh       # Kiosk launcher script
│   ├── refresh.sh           # Page refresh script
│   ├── health-check.sh      # System monitoring script
│   └── update.sh            # Remote update script
├── docs/
│   ├── SETUP.md             # Detailed setup instructions
│   ├── TROUBLESHOOTING.md   # Common issues and solutions
│   ├── MAINTENANCE.md       # Ongoing maintenance guide
│   └── SMARTSHEET.md        # Smartsheet publishing guide
└── images/
    └── (screenshots and diagrams)
```

## Crew Assignments

| Kiosk Hostname | Crew | Monitor Location |
|----------------|------|------------------|
| crew1-kiosk | Crew 1 | Conference Room - North |
| crew2-kiosk | Crew 2 | Conference Room - North |
| crew3-kiosk | Crew 3 | Conference Room - South |
| crew4-kiosk | Crew 4 | Conference Room - South |
| crew5-kiosk | Crew 5 | Conference Room - East |
| crew6-kiosk | Crew 6 | Conference Room - East |

## Configuration

### URLs Configuration (`config/urls.conf`)

```ini
# Crew 1 Smartsheet Published URL
CREW1_URL="https://app.smartsheet.com/b/publish?EQBCT=xxxxx"

# Add rotation URLs (optional)
CREW1_URL_2="https://app.smartsheet.com/b/publish?EQBCT=yyyyy"
```

### Kiosk Settings (`config/kiosk.conf`)

```ini
# Refresh interval in seconds (0 = use Smartsheet auto-refresh)
REFRESH_INTERVAL=300

# Screen rotation (0, 90, 180, 270)
SCREEN_ROTATION=0

# Zoom level (percentage)
ZOOM_LEVEL=100

# URL rotation interval (seconds, 0 = disabled)
URL_ROTATION=0
```

## Remote Management

### SSH Access
```bash
ssh pi@crew1-kiosk.local
```

### Restart Kiosk
```bash
sudo systemctl restart kiosk
```

### View Logs
```bash
journalctl -u kiosk -f
```

### Update All Kiosks
```bash
# From management machine
for i in {1..6}; do
  ssh pi@crew$i-kiosk.local 'sudo /opt/kiosk/scripts/update.sh'
done
```

## Future Enhancements

### Phase 2: Interactive Displays
- Touch screen support for date selection
- Direct Smartsheet integration via API
- Custom web interface for crew-specific views

### Phase 3: Advanced Features
- Dashboard showing all 6 crews on one screen
- Weather integration for outdoor work planning
- Equipment availability overlay

## Support

**Developer Contact:**
Mike Farley - Fructify LLC
[Contact information]

**Documentation:**
See the `docs/` folder for detailed guides.

## License

Proprietary - Cassidy Asphalt & Paving / Fructify LLC

---

*Built with Raspberry Pi 4 and Smartsheet*
