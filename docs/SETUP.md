# Detailed Setup Guide

Complete step-by-step instructions for setting up a Cassidy Asphalt kiosk display.

## Prerequisites

Before starting, ensure you have:

- [ ] Raspberry Pi 4 (4GB recommended)
- [ ] 32GB+ microSD card
- [ ] Card reader for your computer
- [ ] Power supply (official Pi 5V 3A USB-C)
- [ ] Micro HDMI to HDMI cable
- [ ] Monitor with HDMI input
- [ ] Ethernet cable or WiFi credentials
- [ ] Smartsheet published URLs ready

## Step 1: Prepare the SD Card

### Download Raspberry Pi Imager

1. Go to https://www.raspberrypi.com/software/
2. Download the Imager for your operating system
3. Install and launch the application

### Flash the OS

1. Insert your microSD card into the card reader
2. Open Raspberry Pi Imager
3. Click "CHOOSE OS"
4. Select "Raspberry Pi OS (other)"
5. Select "Raspberry Pi OS Lite (64-bit)"
6. Click "CHOOSE STORAGE" and select your SD card

### Pre-Configure Settings

1. Click the **gear icon** (Advanced options)
2. Configure the following:

```
☑ Set hostname: crew1-kiosk
  (Change number for each crew: crew2-kiosk, crew3-kiosk, etc.)

☑ Enable SSH
  ○ Use password authentication

☑ Set username and password
  Username: pi
  Password: [your secure password]

☑ Configure wireless LAN (if not using Ethernet)
  SSID: [your WiFi network name]
  Password: [your WiFi password]
  Wireless LAN country: US

☑ Set locale settings
  Time zone: [your timezone]
  Keyboard layout: us
```

3. Click "SAVE"
4. Click "WRITE" and wait for completion

## Step 2: First Boot

### Connect Hardware

1. Insert the microSD card into the Pi
2. Connect the HDMI cable to the Pi and monitor
3. Connect Ethernet cable (if using wired network)
4. Connect power supply last

### Wait for Boot

The first boot takes longer (up to 2 minutes). The Pi is:
- Expanding the filesystem
- Generating SSH keys
- Connecting to the network

### Find Your Pi on the Network

**Option A: Using hostname (recommended)**
```bash
ping crew1-kiosk.local
```

**Option B: Check your router's DHCP list**

**Option C: Use network scanner**
```bash
# On Linux/Mac
arp -a | grep raspberry

# Or use nmap
nmap -sn 192.168.1.0/24
```

## Step 3: Connect via SSH

### From Windows

1. Open PowerShell or Command Prompt
2. Connect:
```bash
ssh pi@crew1-kiosk.local
```
3. Accept the fingerprint (type "yes")
4. Enter your password

### From Mac/Linux

```bash
ssh pi@crew1-kiosk.local
```

## Step 4: Transfer Project Files

### Option A: Using SCP (from your computer)

```bash
# From the Pi4 project directory on your computer
scp -r ./* pi@crew1-kiosk.local:~/kiosk-install/
```

### Option B: Using USB Drive

1. Copy the Pi4 folder to a USB drive
2. Insert USB into the Pi
3. Mount and copy:
```bash
sudo mkdir /media/usb
sudo mount /dev/sda1 /media/usb
cp -r /media/usb/Pi4 ~/kiosk-install
sudo umount /media/usb
```

### Option C: Download from network share

```bash
# If you have a network share
mkdir ~/kiosk-install
# Mount your share and copy files
```

## Step 5: Run Installation

```bash
cd ~/kiosk-install
chmod +x scripts/install.sh
sudo ./scripts/install.sh --crew 1
```

Follow the prompts. The installer will:
- Update the system
- Install required packages
- Configure auto-login
- Set up the kiosk service
- Configure the hostname

This takes approximately 10-15 minutes.

## Step 6: Configure Smartsheet URL

### Get Your Published URL

1. Open Smartsheet in your browser
2. Open the sheet/report/dashboard for this crew
3. Click **File** > **Publish**
4. Enable **Read-Only - Full**
5. Copy the generated URL

### Set the URL on the Pi

```bash
sudo nano /opt/kiosk/config/urls.conf
```

Find the line for your crew and paste the URL:
```ini
CREW1_URL="https://app.smartsheet.com/b/publish?EQBCT=your_actual_code_here"
```

Save: `Ctrl+O`, `Enter`, `Ctrl+X`

## Step 7: Reboot and Test

```bash
sudo reboot
```

The Pi will:
1. Boot up (30-45 seconds)
2. Auto-login
3. Start the X server
4. Launch Chromium in kiosk mode
5. Display your Smartsheet

## Verification Checklist

After reboot, verify:

- [ ] Monitor displays the Smartsheet content
- [ ] No browser toolbars or address bar visible
- [ ] Content fills the screen
- [ ] Mouse cursor hides after 3 seconds of inactivity
- [ ] Page auto-refreshes (check after 5 minutes)

### Check Remotely

```bash
ssh pi@crew1-kiosk.local
/opt/kiosk/scripts/health-check.sh
```

## Repeating for Additional Crews

For each additional crew (2-6):

1. Prepare a new SD card using Steps 1-2
   - Change hostname to `crew2-kiosk`, etc.
2. SSH in and transfer files (Step 3-4)
3. Run: `sudo ./scripts/install.sh --crew 2`
4. Configure the URL for that crew
5. Reboot

### Batch Deployment Tip

Once you have one working, you can:

1. Create an image of the configured SD card
2. Write that image to other cards
3. Only change:
   - Hostname
   - Crew URL

## Network Recommendations

### Static IP Addresses

For reliable remote management, consider assigning static IPs:

| Kiosk | Suggested IP |
|-------|--------------|
| crew1-kiosk | 192.168.1.101 |
| crew2-kiosk | 192.168.1.102 |
| crew3-kiosk | 192.168.1.103 |
| crew4-kiosk | 192.168.1.104 |
| crew5-kiosk | 192.168.1.105 |
| crew6-kiosk | 192.168.1.106 |

Configure in your router's DHCP settings (MAC address reservation).

### Firewall Ports

Ensure these ports are open for management:
- SSH: Port 22
- VNC (optional): Port 5900

## Next Steps

- See [MAINTENANCE.md](MAINTENANCE.md) for ongoing care
- See [TROUBLESHOOTING.md](TROUBLESHOOTING.md) for common issues
- See [SMARTSHEET.md](SMARTSHEET.md) for publishing tips
