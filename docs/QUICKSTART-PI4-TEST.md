# Pi 4 Quick Start - First Test

Step-by-step guide to get your first Pi 4 kiosk running for testing.

## What You Need

- [ ] Raspberry Pi 4 (4GB RAM)
- [ ] 32GB microSD card
- [ ] USB card reader
- [ ] Power supply (5V 3A USB-C)
- [ ] Micro HDMI to HDMI cable
- [ ] Monitor
- [ ] Computer to flash the SD card

## Step 1: Download Raspberry Pi Imager

1. Go to: https://www.raspberrypi.com/software/
2. Download for your OS (Windows/Mac/Linux)
3. Install and open it

## Step 2: Flash the SD Card

1. Insert microSD card into your computer
2. Open **Raspberry Pi Imager**
3. Click **CHOOSE OS**
4. Select **Raspberry Pi OS (other)** → **Raspberry Pi OS Lite (64-bit)**
5. Click **CHOOSE STORAGE** → Select your SD card

### Configure Settings (IMPORTANT)

6. Click the **gear icon** (⚙️) for advanced options
7. Fill in:

```
☑ Set hostname: pi4-test

☑ Enable SSH
   ● Use password authentication

☑ Set username and password
   Username: pi
   Password: cassidy2026

☑ Configure wireless LAN
   SSID: FarlsFast
   Password: dad111965
   Wireless LAN country: US

☑ Set locale settings
   Time zone: America/New_York (or your timezone)
   Keyboard layout: us
```

8. Click **SAVE**
9. Click **WRITE**
10. Wait for completion (5-10 minutes)
11. Remove SD card

## Step 3: Boot the Pi

1. Insert SD card into Pi 4
2. Connect HDMI cable to monitor (use port closest to USB-C)
3. Connect power supply **last**
4. Wait 2-3 minutes for first boot

You should see a login prompt on the monitor.

## Step 4: Connect via SSH

From your computer (same WiFi network):

**Windows PowerShell:**
```powershell
ssh pi@pi4-test.local
```

**Password:** `cassidy2026`

If `pi4-test.local` doesn't work, check your router for the Pi's IP address.

## Step 5: Install Kiosk Software

Once connected via SSH:

```bash
# Update system
sudo apt update && sudo apt upgrade -y

# Install git
sudo apt install -y git

# Clone the project
git clone https://github.com/cassidysmartsheet-ux/Pi4.git

# Run installer
cd Pi4
chmod +x scripts/install.sh
sudo ./scripts/install.sh --crew 1
```

Follow the prompts. Installation takes 10-15 minutes.

## Step 6: Verify URL Configuration

The installer already has the Smartsheet URL configured. Verify:

```bash
cat /opt/kiosk/config/urls.conf | grep CREW1
```

Should show:
```
CREW1_URL="https://app.smartsheet.com/b/publish?EQBCT=4126bae0d0d748d69983228bb51f9e34"
```

## Step 7: Reboot and Test

```bash
sudo reboot
```

**Watch the monitor.** After 1-2 minutes you should see:

1. Pi boot sequence
2. Black screen briefly
3. Chromium launches fullscreen
4. "Please stand by while Smartsheet is loading..."
5. **Smartsheet calendar appears** (may take 30-60 seconds)

## Success Criteria

- [ ] Smartsheet page loads (not stuck on "loading")
- [ ] Calendar view displays (or grid view - see known issues)
- [ ] Content is readable on screen
- [ ] No timeout errors
- [ ] Mouse cursor hides after 3 seconds

## If It Doesn't Work

### Stuck on "Smartsheet is loading"

Wait up to 90 seconds. If still stuck:

```bash
# SSH back in
ssh pi@pi4-test.local

# Check memory
free -h

# Check temperature
vcgencmd measure_temp

# View browser logs
cat /var/log/kiosk/chromium.log
```

### Shows Grid View Instead of Calendar

This is a known Smartsheet limitation. The URL was published in Calendar view but may not persist. Options:

1. Accept grid view for now
2. Re-publish in Smartsheet while viewing Calendar
3. Create a Dashboard with Calendar widget (most reliable)

### Black Screen / No Display

```bash
# Force HDMI output
sudo nano /boot/config.txt
```

Add:
```
hdmi_force_hotplug=1
hdmi_drive=2
```

Reboot.

### Can't Connect via SSH

- Try IP address instead: Check router for Pi's IP
- Make sure you're on the same WiFi (FarlsFast)
- Wait longer - first boot can take 3+ minutes

## Next Steps

Once this test Pi works:

1. Note any issues for documentation
2. Test browser zoom if text too small (`/opt/kiosk/config/kiosk.conf`)
3. Decide on view type (Calendar vs Grid vs Dashboard)
4. Proceed to set up remaining 5 crew kiosks

## Test Network Info

```
SSID: FarlsFast
Password: dad111965
```

## Smartsheet Test URL

```
https://app.smartsheet.com/b/publish?EQBCT=4126bae0d0d748d69983228bb51f9e34
```
