#!/bin/bash
# ============================================
# Cassidy Asphalt - Kiosk Start Script
# ============================================
#
# This script launches the kiosk browser in fullscreen mode.
# It is called by the systemd kiosk service on boot.
#
# ============================================

set -e

# Paths
KIOSK_DIR="/opt/kiosk"
CONFIG_DIR="$KIOSK_DIR/config"
LOG_DIR="/var/log/kiosk"

# Create log directory if needed
mkdir -p "$LOG_DIR"

# Load configurations
source "$CONFIG_DIR/kiosk.conf"
source "$CONFIG_DIR/urls.conf"

# Get kiosk identity from hostname or config
if [ -z "$KIOSK_ID" ]; then
    HOSTNAME=$(hostname)
    # Extract crew number from hostname like "crew1-kiosk"
    KIOSK_ID=$(echo "$HOSTNAME" | grep -oP 'crew\d+' || echo "crew1")
fi

# Function to log messages
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_DIR/kiosk.log"
}

log "Starting kiosk for $KIOSK_ID"

# Get the URL for this kiosk
get_url() {
    local crew_num=$(echo "$KIOSK_ID" | grep -oP '\d+')
    local var_name="CREW${crew_num}_URL"
    echo "${!var_name}"
}

URL=$(get_url)

if [ -z "$URL" ] || [ "$URL" == *"REPLACE_WITH"* ]; then
    log "ERROR: No valid URL configured for $KIOSK_ID"
    log "Please edit $CONFIG_DIR/urls.conf"
    # Show error page
    URL="file://$KIOSK_DIR/html/error.html"
fi

log "Display URL: $URL"

# Wait for network
wait_for_network() {
    local retries=${NETWORK_RETRY_COUNT:-5}
    local delay=${NETWORK_RETRY_DELAY:-10}
    local count=0

    while [ $count -lt $retries ]; do
        if ping -c 1 8.8.8.8 &> /dev/null; then
            log "Network is available"
            return 0
        fi
        count=$((count + 1))
        log "Waiting for network... attempt $count/$retries"
        sleep $delay
    done

    log "Network not available after $retries attempts"
    return 1
}

# Wait for display
wait_for_display() {
    local count=0
    while [ $count -lt 30 ]; do
        if [ -n "$DISPLAY" ] || [ -n "$WAYLAND_DISPLAY" ]; then
            log "Display is ready"
            return 0
        fi
        count=$((count + 1))
        sleep 1
    done
    log "Display not ready"
    return 1
}

# Disable screen blanking/power saving
disable_screen_blanking() {
    log "Disabling screen blanking"
    xset s off 2>/dev/null || true
    xset -dpms 2>/dev/null || true
    xset s noblank 2>/dev/null || true
}

# Hide cursor after inactivity
setup_cursor_hiding() {
    if [ "${CURSOR_HIDE_DELAY:-3}" -gt 0 ]; then
        log "Setting cursor hide delay to ${CURSOR_HIDE_DELAY}s"
        unclutter -idle "$CURSOR_HIDE_DELAY" -root &
    fi
}

# Build Chromium arguments
build_chromium_args() {
    local args=(
        "--kiosk"
        "--noerrdialogs"
        "--disable-infobars"
        "--disable-session-crashed-bubble"
        "--disable-restore-session-state"
        "--disable-features=TranslateUI"
        "--disable-features=Translate"
        "--no-first-run"
        "--start-fullscreen"
        "--autoplay-policy=no-user-gesture-required"
        "--check-for-update-interval=31536000"
        "--disable-background-networking"
        "--disable-component-update"
        "--disable-sync"
        "--disable-translate"
        "--disable-default-apps"
        "--disable-extensions"
        "--disable-hang-monitor"
        "--disable-popup-blocking"
        "--disable-prompt-on-repost"
        "--disable-background-timer-throttling"
        "--disable-renderer-backgrounding"
        "--disable-backgrounding-occluded-windows"
        "--force-device-scale-factor=1"
    )

    # Add zoom level if specified
    if [ -n "$ZOOM_LEVEL" ] && [ "$ZOOM_LEVEL" != "100" ]; then
        local scale=$(echo "scale=2; $ZOOM_LEVEL / 100" | bc)
        args+=("--force-device-scale-factor=$scale")
    fi

    echo "${args[@]}"
}

# Main startup sequence
main() {
    log "============================================"
    log "Kiosk startup sequence beginning"
    log "============================================"

    # Wait for network connectivity
    if ! wait_for_network; then
        if [ "${SHOW_OFFLINE_MESSAGE:-true}" == "true" ]; then
            URL="file://$KIOSK_DIR/html/offline.html"
        fi
    fi

    # Setup display environment
    export DISPLAY=:0

    # Disable screen blanking
    disable_screen_blanking

    # Setup cursor hiding
    setup_cursor_hiding

    # Build browser arguments
    CHROMIUM_ARGS=$(build_chromium_args)

    log "Launching Chromium with URL: $URL"

    # Launch Chromium in kiosk mode
    # Use a loop to restart if it crashes
    while true; do
        chromium $CHROMIUM_ARGS "$URL" 2>&1 | tee -a "$LOG_DIR/chromium.log"

        EXIT_CODE=$?
        log "Chromium exited with code $EXIT_CODE"

        # Wait before restarting
        sleep 5
        log "Restarting Chromium..."
    done
}

# Run main function
main
