# Troubleshooting Guide

Common issues and solutions for the Cassidy Asphalt kiosk displays.

## Quick Diagnostics

### Run Health Check
```bash
ssh pi@crew1-kiosk.local
/opt/kiosk/scripts/health-check.sh
```

### Check Service Status
```bash
sudo systemctl status kiosk
```

### View Live Logs
```bash
journalctl -u kiosk -f
```

---

## Display Issues

### Black Screen After Boot

**Symptoms:** Pi boots but monitor shows no signal or black screen.

**Solutions:**

1. **Check HDMI connection**
   - Ensure cable is in the correct Micro HDMI port (use the one closest to USB-C power)
   - Try a different HDMI cable

2. **Force HDMI output**
   ```bash
   sudo nano /boot/config.txt
   ```
   Add/modify:
   ```
   hdmi_force_hotplug=1
   hdmi_drive=2
   ```
   Reboot.

3. **Check display service**
   ```bash
   sudo systemctl status kiosk
   journalctl -u kiosk -n 50
   ```

### Wrong Resolution / Overscan

**Symptoms:** Content doesn't fill screen, or edges are cut off.

**Solutions:**

1. **Disable overscan**
   ```bash
   sudo nano /boot/config.txt
   ```
   Add:
   ```
   disable_overscan=1
   ```

2. **Set specific resolution**
   ```bash
   sudo nano /boot/config.txt
   ```
   Add (example for 1920x1080):
   ```
   hdmi_group=1
   hdmi_mode=16
   ```

3. **Use TV settings** - Check your monitor's "picture size" or "aspect ratio" settings

### Screen Goes Black After Inactivity

**Symptoms:** Display turns off after some time.

**Solutions:**

1. **Verify blanking is disabled**
   ```bash
   DISPLAY=:0 xset q
   ```
   Should show: `DPMS is Disabled`

2. **Manually disable**
   ```bash
   DISPLAY=:0 xset s off
   DISPLAY=:0 xset -dpms
   DISPLAY=:0 xset s noblank
   ```

3. **Check kiosk script** - Ensure `disable_screen_blanking` function runs

---

## Network Issues

### Cannot Connect via SSH

**Symptoms:** `ssh: connect to host crew1-kiosk.local port 22: Connection refused`

**Solutions:**

1. **Ping the Pi**
   ```bash
   ping crew1-kiosk.local
   ```

2. **Try IP address directly**
   - Check your router for the Pi's IP
   - `ssh pi@192.168.1.xxx`

3. **mDNS not working**
   - Windows may need Bonjour installed
   - Try: `ping crew1-kiosk` (without .local)

4. **SSH not enabled**
   - Connect monitor/keyboard directly
   - Run: `sudo systemctl enable ssh && sudo systemctl start ssh`

### "Network Unavailable" on Display

**Symptoms:** Kiosk shows offline message, can't load Smartsheet.

**Solutions:**

1. **Check network cable** (if wired)

2. **Check WiFi**
   ```bash
   iwconfig wlan0
   nmcli device wifi list
   ```

3. **Test connectivity**
   ```bash
   ping 8.8.8.8
   ping app.smartsheet.com
   ```

4. **Restart networking**
   ```bash
   sudo systemctl restart NetworkManager
   ```

5. **Check DNS**
   ```bash
   nslookup app.smartsheet.com
   ```

### Smartsheet Page Won't Load

**Symptoms:** Browser opens but page doesn't load or shows error.

**Solutions:**

1. **Verify URL is correct**
   ```bash
   cat /opt/kiosk/config/urls.conf | grep CREW
   ```

2. **Test URL in browser** (from another computer)

3. **Check if published link is still active**
   - Published links can expire or be revoked
   - Re-publish in Smartsheet if needed

4. **Clear browser cache**
   ```bash
   rm -rf /home/pi/.cache/chromium
   sudo systemctl restart kiosk
   ```

---

## Browser Issues

### Chromium Keeps Crashing

**Symptoms:** Browser closes and restarts repeatedly.

**Solutions:**

1. **Check memory**
   ```bash
   free -h
   ```
   If low, consider using 4GB Pi model

2. **Check temperature**
   ```bash
   vcgencmd measure_temp
   ```
   Should be under 70°C. Add heatsink/fan if high.

3. **Check for GPU memory**
   ```bash
   sudo nano /boot/config.txt
   ```
   Add:
   ```
   gpu_mem=128
   ```

4. **View crash logs**
   ```bash
   cat /var/log/kiosk/chromium.log
   ```

### "Restore Pages" Popup Appears

**Symptoms:** Chrome shows "Restore pages?" dialog on startup.

**Solutions:**

1. **Clear session data**
   ```bash
   rm -rf /home/pi/.config/chromium/Default/Session*
   rm -rf /home/pi/.config/chromium/Default/Current*
   ```

2. **Verify kiosk flags** - Check that `--disable-session-crashed-bubble` is in kiosk-start.sh

### Page Not Refreshing

**Symptoms:** Smartsheet data is stale, not updating.

**Solutions:**

1. **Manual refresh**
   ```bash
   /opt/kiosk/scripts/refresh.sh
   ```

2. **Check refresh interval**
   ```bash
   cat /opt/kiosk/config/kiosk.conf | grep REFRESH
   ```

3. **Smartsheet auto-refresh**
   - Published views have their own refresh
   - May take 1-5 minutes to sync

---

## Service Issues

### Kiosk Service Won't Start

**Symptoms:** `systemctl status kiosk` shows failed.

**Solutions:**

1. **Check detailed error**
   ```bash
   journalctl -u kiosk -n 100 --no-pager
   ```

2. **Verify script permissions**
   ```bash
   ls -la /opt/kiosk/scripts/
   chmod +x /opt/kiosk/scripts/*.sh
   ```

3. **Check user exists**
   ```bash
   id pi
   ```

4. **Test script manually**
   ```bash
   sudo -u pi /opt/kiosk/scripts/kiosk-start.sh
   ```

### Service Starts Too Early

**Symptoms:** Kiosk fails because network/display not ready.

**Solutions:**

1. **Increase startup delay**
   ```bash
   sudo nano /etc/systemd/system/kiosk.service
   ```
   Change `ExecStartPre=/bin/sleep 5` to `sleep 15`

2. **Reload and restart**
   ```bash
   sudo systemctl daemon-reload
   sudo systemctl restart kiosk
   ```

---

## Performance Issues

### Sluggish Display / Slow Scrolling

**Solutions:**

1. **Reduce content complexity** in Smartsheet
2. **Disable animations** in Smartsheet view settings
3. **Check CPU usage**
   ```bash
   top
   ```

4. **Check temperature**
   ```bash
   vcgencmd measure_temp
   ```

### High Memory Usage

**Solutions:**

1. **Check processes**
   ```bash
   ps aux --sort=-%mem | head -10
   ```

2. **Restart browser periodically** - Already configured for 3 AM reboot

3. **Reduce Chrome processes**
   - Use single tab
   - Avoid heavy dashboards

---

## Hardware Issues

### Pi Won't Boot At All

**Symptoms:** No lights, or only red light, on Pi.

**Solutions:**

1. **Power supply** - Must be 5V 3A USB-C, official recommended
2. **SD card** - Try re-flashing, try different card
3. **Bad Pi** - Try with minimal setup (just power, no HDMI/USB)

### Pi Keeps Rebooting

**Symptoms:** Boot loop, rainbow screen, or kernel panic.

**Solutions:**

1. **Power supply insufficient**
2. **Corrupted SD card** - Re-flash
3. **Overheating** - Check temp, add cooling

### Lightning Bolt Icon on Screen

**Symptoms:** Yellow lightning bolt in corner of screen.

**Cause:** Under-voltage (power supply issue)

**Solution:** Use official 5V 3A USB-C power supply

---

## Maintenance Commands

### Restart Kiosk
```bash
sudo systemctl restart kiosk
```

### Reboot Pi
```bash
sudo reboot
```

### Force Refresh Page
```bash
/opt/kiosk/scripts/refresh.sh --hard
```

### View All Logs
```bash
journalctl -u kiosk --since today
```

### Check Disk Space
```bash
df -h
```

### Check Temperature
```bash
vcgencmd measure_temp
```

### Update System
```bash
sudo apt update && sudo apt upgrade -y
```

---

## Getting Help

If issues persist:

1. Run the full health check and save output:
   ```bash
   /opt/kiosk/scripts/health-check.sh > health-report.txt
   ```

2. Collect logs:
   ```bash
   journalctl -u kiosk --since "1 hour ago" > kiosk-logs.txt
   ```

3. Contact: Mike Farley - Fructify LLC
