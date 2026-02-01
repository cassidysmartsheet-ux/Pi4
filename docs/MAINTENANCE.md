# Maintenance Guide

Ongoing maintenance procedures for the Cassidy Asphalt kiosk displays.

## Daily Operations

The kiosks are designed to run unattended. Daily operations are automatic:

- **3:00 AM**: Automatic system reboot (clears memory, applies updates)
- **Every 5 minutes**: Page refresh (configurable)
- **Every 15 minutes**: Health check logged

No daily manual intervention should be required.

---

## Weekly Checks

Perform these checks weekly (Monday morning recommended):

### Remote Health Check

Run from any computer on the network:

```bash
# Check all 6 kiosks
for i in {1..6}; do
  echo "=== Crew $i ==="
  ssh pi@crew$i-kiosk.local '/opt/kiosk/scripts/health-check.sh --brief'
done
```

### Visual Inspection

Walk by each display and verify:
- [ ] Correct crew schedule is showing
- [ ] Data appears current (check date on displayed content)
- [ ] No error messages or blank screens
- [ ] No physical damage to equipment

---

## Monthly Maintenance

### System Updates

Update each kiosk monthly:

```bash
ssh pi@crew1-kiosk.local

# Update system packages
sudo apt update && sudo apt upgrade -y

# Reboot to apply updates
sudo reboot
```

**Batch update all kiosks:**
```bash
for i in {1..6}; do
  echo "Updating crew $i..."
  ssh pi@crew$i-kiosk.local 'sudo apt update && sudo apt upgrade -y && sudo reboot'
  sleep 120  # Wait for reboot before next
done
```

### Log Cleanup

Logs auto-rotate but verify disk space:

```bash
ssh pi@crew1-kiosk.local 'df -h /'
```

If disk usage > 80%:
```bash
# Clear old logs
sudo journalctl --vacuum-time=7d
sudo rm /var/log/kiosk/*.log.* 2>/dev/null
```

### Browser Cache Clear

Clear Chrome cache monthly to prevent bloat:

```bash
ssh pi@crew1-kiosk.local
sudo systemctl stop kiosk
rm -rf /home/pi/.cache/chromium
sudo systemctl start kiosk
```

---

## Quarterly Tasks

### SD Card Health Check

SD cards degrade over time. Check for errors:

```bash
# Check filesystem
sudo fsck -n /dev/mmcblk0p2

# Check for read-only mount (sign of SD failure)
mount | grep mmcblk0
```

### Backup Configuration

Backup each kiosk's configuration:

```bash
# Run from management computer
mkdir -p ~/kiosk-backups/$(date +%Y%m)

for i in {1..6}; do
  scp pi@crew$i-kiosk.local:/opt/kiosk/config/* \
      ~/kiosk-backups/$(date +%Y%m)/crew$i/
done
```

### Firmware Update

Check for Pi firmware updates:

```bash
ssh pi@crew1-kiosk.local
sudo rpi-update
```

**Note:** Only update firmware if experiencing hardware issues. Stable systems don't need frequent firmware updates.

---

## URL Updates

When Smartsheet published URLs change:

### Update Single Kiosk

```bash
ssh pi@crew1-kiosk.local
sudo nano /opt/kiosk/config/urls.conf
# Update the URL
sudo systemctl restart kiosk
```

### Update All Kiosks

If URLs are stored centrally:

```bash
# Copy new urls.conf to all kiosks
for i in {1..6}; do
  scp urls.conf pi@crew$i-kiosk.local:/opt/kiosk/config/
  ssh pi@crew$i-kiosk.local 'sudo systemctl restart kiosk'
done
```

---

## Hardware Replacement

### Replacing a Failed Pi

1. **Prepare new SD card** (see SETUP.md)

2. **Copy configuration from backup**
   ```bash
   scp ~/kiosk-backups/latest/crew$N/* newpi:/opt/kiosk/config/
   ```

3. **Or manually configure**
   - Set hostname
   - Set crew URL
   - Run installer

4. **Swap hardware**
   - Power down old Pi
   - Disconnect cables
   - Connect new Pi
   - Power on

### Replacing SD Card

1. **Create image of working card** (if possible)
   ```bash
   # On Linux/Mac with card reader
   sudo dd if=/dev/sdX of=kiosk-backup.img bs=4M status=progress
   ```

2. **Flash new card**
   - Use Raspberry Pi Imager
   - Or restore from backup image

3. **Copy configuration**
   - URLs and settings need to be restored

### Replacing Monitor

1. Power down Pi
2. Disconnect old monitor
3. Connect new monitor
4. Power on Pi
5. Check resolution settings if display is different size

---

## Power Outage Recovery

After a power outage, kiosks should auto-recover:

1. Wait 5 minutes after power restoration
2. Displays should show Smartsheet content

**If kiosks don't recover:**

```bash
# Check which are online
for i in {1..6}; do
  ping -c 1 crew$i-kiosk.local && echo "Crew $i: UP" || echo "Crew $i: DOWN"
done

# Manual restart for any that are down
# (requires physical access to unplug/replug power)
```

---

## Network Changes

### WiFi Password Change

1. SSH into each kiosk
2. Update WiFi:
   ```bash
   sudo nmcli device wifi connect "NewSSID" password "NewPassword"
   ```

Or use wpa_supplicant:
```bash
sudo nano /etc/wpa_supplicant/wpa_supplicant.conf
```

### Network Migration (Office Move)

1. Pre-configure new network on SD cards
2. Or connect temporarily via Ethernet at new location
3. Update WiFi settings
4. Disconnect Ethernet

---

## Monitoring Dashboard

For proactive monitoring, set up a simple dashboard:

### Option 1: Cron-based Email Alerts

On a management server:

```bash
# /etc/cron.daily/kiosk-check

#!/bin/bash
ISSUES=""

for i in {1..6}; do
  if ! ping -c 1 crew$i-kiosk.local &>/dev/null; then
    ISSUES="$ISSUES\nCrew $i kiosk is offline"
  fi
done

if [ -n "$ISSUES" ]; then
  echo -e "Kiosk Issues Detected:\n$ISSUES" | mail -s "Kiosk Alert" admin@company.com
fi
```

### Option 2: Health Check Aggregation

Collect health data centrally:

```bash
# Run hourly via cron
for i in {1..6}; do
  ssh pi@crew$i-kiosk.local '/opt/kiosk/scripts/health-check.sh --json' \
    >> /var/log/kiosk-central/crew$i.json
done
```

---

## Contact Information

**System Developer:**
Mike Farley
Fructify LLC

**Emergency Procedures:**
1. Check if issue affects one or all kiosks
2. Try remote restart: `ssh pi@crewX-kiosk.local 'sudo reboot'`
3. If unreachable, power cycle physically
4. Contact developer if issue persists

---

## Maintenance Log Template

Keep a log of maintenance activities:

| Date | Kiosk | Action | Performed By | Notes |
|------|-------|--------|--------------|-------|
| 2026-02-01 | All | Initial install | Mike F | v1.0.0 |
| | | | | |
| | | | | |
