#!/bin/bash
# ============================================
# Cassidy Asphalt - Remote Update Script
# ============================================
#
# Updates the kiosk software and configuration.
# Can pull from USB, network share, or git repo.
#
# Usage:
#   ./update.sh                    # Update from default source
#   ./update.sh --usb              # Update from USB drive
#   ./update.sh --url <url>        # Update from URL
#   ./update.sh --config-only      # Only update configuration
#
# ============================================

set -e

KIOSK_DIR="/opt/kiosk"
BACKUP_DIR="/opt/kiosk-backup"
LOG_FILE="/var/log/kiosk/update.log"
USB_MOUNT="/media/usb"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

error_exit() {
    log "ERROR: $1"
    exit 1
}

# Create backup before updating
backup_current() {
    log "Creating backup of current installation..."
    mkdir -p "$BACKUP_DIR"

    local backup_name="backup-$(date +%Y%m%d-%H%M%S)"
    cp -r "$KIOSK_DIR/config" "$BACKUP_DIR/$backup_name-config"

    log "Backup created: $BACKUP_DIR/$backup_name-config"
}

# Update from USB drive
update_from_usb() {
    log "Looking for USB drive..."

    # Try to mount USB if not already mounted
    if [ ! -d "$USB_MOUNT" ]; then
        mkdir -p "$USB_MOUNT"
    fi

    # Find USB device
    USB_DEVICE=$(lsblk -o NAME,TRAN | grep usb | head -1 | awk '{print $1}')
    if [ -z "$USB_DEVICE" ]; then
        error_exit "No USB drive found"
    fi

    mount "/dev/${USB_DEVICE}1" "$USB_MOUNT" 2>/dev/null || true

    if [ ! -f "$USB_MOUNT/kiosk-update/config/urls.conf" ]; then
        error_exit "No kiosk update found on USB drive"
    fi

    log "USB drive found, copying files..."
    cp -r "$USB_MOUNT/kiosk-update/"* "$KIOSK_DIR/"

    umount "$USB_MOUNT" 2>/dev/null || true
    log "USB update complete"
}

# Update from URL (tar.gz archive)
update_from_url() {
    local url="$1"
    log "Downloading update from: $url"

    local temp_dir=$(mktemp -d)
    cd "$temp_dir"

    curl -L -o update.tar.gz "$url" || error_exit "Failed to download update"
    tar -xzf update.tar.gz || error_exit "Failed to extract update"

    if [ -d "kiosk-update" ]; then
        cp -r kiosk-update/* "$KIOSK_DIR/"
    else
        cp -r */ "$KIOSK_DIR/" 2>/dev/null || true
    fi

    rm -rf "$temp_dir"
    log "URL update complete"
}

# Update configuration only
update_config_only() {
    log "Updating configuration only..."

    # Reload configuration
    systemctl daemon-reload

    log "Configuration updated"
}

# Apply updates
apply_updates() {
    log "Applying updates..."

    # Make scripts executable
    chmod +x "$KIOSK_DIR/scripts/"*.sh

    # Reload systemd if service file changed
    if [ -f "$KIOSK_DIR/systemd/kiosk.service" ]; then
        cp "$KIOSK_DIR/systemd/kiosk.service" /etc/systemd/system/
        systemctl daemon-reload
    fi

    log "Updates applied"
}

# Restart kiosk service
restart_kiosk() {
    log "Restarting kiosk service..."
    systemctl restart kiosk
    log "Kiosk service restarted"
}

# Main
main() {
    log "============================================"
    log "Starting kiosk update"
    log "============================================"

    # Require root
    if [ "$EUID" -ne 0 ]; then
        error_exit "This script must be run as root (sudo)"
    fi

    # Create backup first
    backup_current

    case "$1" in
        --usb)
            update_from_usb
            apply_updates
            restart_kiosk
            ;;
        --url)
            if [ -z "$2" ]; then
                error_exit "URL required. Usage: ./update.sh --url <url>"
            fi
            update_from_url "$2"
            apply_updates
            restart_kiosk
            ;;
        --config-only)
            update_config_only
            restart_kiosk
            ;;
        *)
            echo "Usage: $0 [--usb|--url <url>|--config-only]"
            echo ""
            echo "Options:"
            echo "  --usb          Update from USB drive"
            echo "  --url <url>    Update from URL (tar.gz archive)"
            echo "  --config-only  Reload configuration only"
            exit 0
            ;;
    esac

    log "============================================"
    log "Update complete!"
    log "============================================"
}

main "$@"
