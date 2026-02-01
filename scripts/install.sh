#!/bin/bash
# ============================================
# Cassidy Asphalt - Kiosk Installation Script
# ============================================
#
# This script installs and configures the kiosk system
# on a fresh Raspberry Pi OS Lite installation.
#
# Usage:
#   sudo ./install.sh
#   sudo ./install.sh --crew 1    # Set crew number
#   sudo ./install.sh --unattended # No prompts
#
# ============================================

set -e

# Configuration
INSTALL_DIR="/opt/kiosk"
SERVICE_USER="pi"
CREW_NUMBER=""
UNATTENDED=false

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_banner() {
    echo -e "${BLUE}"
    echo "============================================"
    echo "  Cassidy Asphalt Kiosk Installer"
    echo "  Raspberry Pi 4 Digital Signage"
    echo "============================================"
    echo -e "${NC}"
}

log() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --crew)
            CREW_NUMBER="$2"
            shift 2
            ;;
        --unattended)
            UNATTENDED=true
            shift
            ;;
        *)
            error "Unknown option: $1"
            exit 1
            ;;
    esac
done

# Check for root
check_root() {
    if [ "$EUID" -ne 0 ]; then
        error "This script must be run as root (sudo)"
        exit 1
    fi
}

# Check for Raspberry Pi
check_platform() {
    if [ ! -f /proc/device-tree/model ]; then
        warn "This doesn't appear to be a Raspberry Pi"
        if [ "$UNATTENDED" = false ]; then
            read -p "Continue anyway? (y/n) " -n 1 -r
            echo
            if [[ ! $REPLY =~ ^[Yy]$ ]]; then
                exit 1
            fi
        fi
    else
        log "Detected: $(cat /proc/device-tree/model)"
    fi
}

# Get crew number if not specified
get_crew_number() {
    if [ -z "$CREW_NUMBER" ]; then
        if [ "$UNATTENDED" = true ]; then
            # Try to extract from hostname
            CREW_NUMBER=$(hostname | grep -oP '\d+' | head -1)
            if [ -z "$CREW_NUMBER" ]; then
                CREW_NUMBER="1"
            fi
        else
            echo ""
            echo "Which crew will this kiosk display?"
            read -p "Enter crew number (1-6): " CREW_NUMBER
        fi
    fi

    # Validate
    if ! [[ "$CREW_NUMBER" =~ ^[1-6]$ ]]; then
        error "Invalid crew number. Must be 1-6."
        exit 1
    fi

    log "Configuring for Crew $CREW_NUMBER"
}

# Set hostname
set_hostname() {
    local new_hostname="crew${CREW_NUMBER}-kiosk"
    local current_hostname=$(hostname)

    if [ "$current_hostname" != "$new_hostname" ]; then
        log "Setting hostname to $new_hostname"
        hostnamectl set-hostname "$new_hostname"
        echo "$new_hostname" > /etc/hostname

        # Update hosts file
        sed -i "s/127.0.1.1.*/127.0.1.1\t$new_hostname/" /etc/hosts
    else
        log "Hostname already set to $new_hostname"
    fi
}

# Update system packages
update_system() {
    log "Updating system packages..."
    apt-get update
    apt-get upgrade -y
}

# Install required packages
install_packages() {
    log "Installing required packages..."

    apt-get install -y \
        xserver-xorg \
        x11-xserver-utils \
        xinit \
        openbox \
        chromium \
        unclutter \
        xdotool \
        curl \
        jq \
        bc \
        dnsutils \
        plymouth \
        plymouth-themes

    log "Packages installed successfully"
}

# Create directory structure
create_directories() {
    log "Creating directory structure..."

    mkdir -p "$INSTALL_DIR"/{config,scripts,html,logs}
    mkdir -p /var/log/kiosk

    # Set ownership
    chown -R $SERVICE_USER:$SERVICE_USER "$INSTALL_DIR"
    chown -R $SERVICE_USER:$SERVICE_USER /var/log/kiosk
}

# Copy project files
copy_files() {
    log "Copying project files..."

    # Get the script's directory (where the project files are)
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

    # Copy configuration files
    cp -r "$PROJECT_DIR/config/"* "$INSTALL_DIR/config/"

    # Copy scripts
    cp -r "$PROJECT_DIR/scripts/"* "$INSTALL_DIR/scripts/"

    # Make scripts executable
    chmod +x "$INSTALL_DIR/scripts/"*.sh

    # Set kiosk identity in config
    echo "KIOSK_ID=\"crew${CREW_NUMBER}\"" >> "$INSTALL_DIR/config/kiosk.conf"
}

# Create error/offline HTML pages
create_html_pages() {
    log "Creating fallback HTML pages..."

    # Error page
    cat > "$INSTALL_DIR/html/error.html" << 'EOF'
<!DOCTYPE html>
<html>
<head>
    <title>Kiosk Error</title>
    <style>
        body {
            background: #1a1a2e;
            color: #eee;
            font-family: Arial, sans-serif;
            display: flex;
            justify-content: center;
            align-items: center;
            height: 100vh;
            margin: 0;
        }
        .container {
            text-align: center;
            padding: 40px;
        }
        h1 { color: #e94560; font-size: 3em; }
        p { font-size: 1.5em; color: #aaa; }
        .code {
            background: #16213e;
            padding: 20px;
            border-radius: 8px;
            font-family: monospace;
            margin-top: 20px;
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>Configuration Required</h1>
        <p>The Smartsheet URL has not been configured for this kiosk.</p>
        <div class="code">
            Edit: /opt/kiosk/config/urls.conf
        </div>
        <p style="margin-top: 40px;">Then restart: sudo systemctl restart kiosk</p>
    </div>
</body>
</html>
EOF

    # Offline page
    cat > "$INSTALL_DIR/html/offline.html" << 'EOF'
<!DOCTYPE html>
<html>
<head>
    <title>Network Offline</title>
    <meta http-equiv="refresh" content="30">
    <style>
        body {
            background: #1a1a2e;
            color: #eee;
            font-family: Arial, sans-serif;
            display: flex;
            justify-content: center;
            align-items: center;
            height: 100vh;
            margin: 0;
        }
        .container {
            text-align: center;
            padding: 40px;
        }
        h1 { color: #f39c12; font-size: 3em; }
        p { font-size: 1.5em; color: #aaa; }
        .spinner {
            border: 4px solid #16213e;
            border-top: 4px solid #f39c12;
            border-radius: 50%;
            width: 50px;
            height: 50px;
            animation: spin 1s linear infinite;
            margin: 30px auto;
        }
        @keyframes spin {
            0% { transform: rotate(0deg); }
            100% { transform: rotate(360deg); }
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>Network Unavailable</h1>
        <div class="spinner"></div>
        <p>Waiting for network connection...</p>
        <p style="font-size: 1em; color: #666;">This page will refresh automatically</p>
    </div>
</body>
</html>
EOF
}

# Create systemd service
create_service() {
    log "Creating systemd service..."

    cat > /etc/systemd/system/kiosk.service << EOF
[Unit]
Description=Cassidy Asphalt Kiosk Display
After=network-online.target graphical.target
Wants=network-online.target

[Service]
Type=simple
User=$SERVICE_USER
Environment=DISPLAY=:0
ExecStartPre=/bin/sleep 5
ExecStart=$INSTALL_DIR/scripts/kiosk-start.sh
Restart=always
RestartSec=10

[Install]
WantedBy=graphical.target
EOF

    systemctl daemon-reload
    systemctl enable kiosk.service
}

# Configure auto-login and X startup
configure_autologin() {
    log "Configuring auto-login..."

    # Create getty override for auto-login
    mkdir -p /etc/systemd/system/getty@tty1.service.d
    cat > /etc/systemd/system/getty@tty1.service.d/autologin.conf << EOF
[Service]
ExecStart=
ExecStart=-/sbin/agetty --autologin $SERVICE_USER --noclear %I \$TERM
EOF

    # Create .xinitrc for X startup
    cat > /home/$SERVICE_USER/.xinitrc << 'EOF'
#!/bin/bash
# Disable screen blanking
xset s off
xset -dpms
xset s noblank

# Start window manager
exec openbox-session
EOF
    chown $SERVICE_USER:$SERVICE_USER /home/$SERVICE_USER/.xinitrc

    # Auto-start X on login
    cat >> /home/$SERVICE_USER/.bash_profile << 'EOF'

# Auto-start X if on tty1
if [ -z "$DISPLAY" ] && [ "$(tty)" = "/dev/tty1" ]; then
    startx
fi
EOF
}

# Configure Openbox to start kiosk
configure_openbox() {
    log "Configuring Openbox..."

    mkdir -p /home/$SERVICE_USER/.config/openbox
    cat > /home/$SERVICE_USER/.config/openbox/autostart << EOF
# Disable screen blanking
xset s off &
xset -dpms &
xset s noblank &

# Hide cursor
unclutter -idle 3 -root &

# Start kiosk service (handled by systemd)
EOF

    chown -R $SERVICE_USER:$SERVICE_USER /home/$SERVICE_USER/.config
}

# Setup auto-reboot cron
setup_cron() {
    log "Setting up scheduled tasks..."

    # Add cron job for nightly reboot (3 AM)
    (crontab -l 2>/dev/null | grep -v "kiosk-reboot"; echo "0 3 * * * /sbin/reboot") | crontab -

    # Add cron job for health check logging
    (crontab -l 2>/dev/null | grep -v "health-check"; echo "*/15 * * * * $INSTALL_DIR/scripts/health-check.sh --json >> /var/log/kiosk/health.log 2>&1") | crontab -
}

# Optimize boot time
optimize_boot() {
    log "Optimizing boot configuration..."

    # Disable unnecessary services
    systemctl disable bluetooth.service 2>/dev/null || true
    systemctl disable hciuart.service 2>/dev/null || true
    systemctl disable triggerhappy.service 2>/dev/null || true

    # Add boot config optimizations
    if ! grep -q "disable_splash" /boot/config.txt; then
        cat >> /boot/config.txt << EOF

# Kiosk optimizations
disable_splash=1
boot_delay=0
EOF
    fi
}

# Print completion message
print_completion() {
    echo ""
    echo -e "${GREEN}============================================${NC}"
    echo -e "${GREEN}  Installation Complete!${NC}"
    echo -e "${GREEN}============================================${NC}"
    echo ""
    echo "Kiosk configured for: Crew $CREW_NUMBER"
    echo "Hostname: crew${CREW_NUMBER}-kiosk"
    echo ""
    echo -e "${YELLOW}Next Steps:${NC}"
    echo "1. Edit the Smartsheet URL:"
    echo "   sudo nano $INSTALL_DIR/config/urls.conf"
    echo ""
    echo "2. Set CREW${CREW_NUMBER}_URL to your published Smartsheet URL"
    echo ""
    echo "3. Reboot the Pi:"
    echo "   sudo reboot"
    echo ""
    echo "The kiosk will start automatically on boot."
    echo ""
    echo -e "${BLUE}Management Commands:${NC}"
    echo "  Status:    sudo systemctl status kiosk"
    echo "  Restart:   sudo systemctl restart kiosk"
    echo "  Logs:      journalctl -u kiosk -f"
    echo "  Health:    $INSTALL_DIR/scripts/health-check.sh"
    echo ""
}

# Main installation flow
main() {
    print_banner
    check_root
    check_platform
    get_crew_number

    log "Starting installation..."

    update_system
    install_packages
    create_directories
    copy_files
    create_html_pages
    create_service
    configure_autologin
    configure_openbox
    setup_cron
    optimize_boot

    print_completion
}

# Run main
main
