#!/bin/bash
# ============================================
# Cassidy Asphalt - Page Refresh Script
# ============================================
#
# This script forces a page refresh in the kiosk browser.
# Can be run manually or via cron for scheduled refreshes.
#
# Usage:
#   ./refresh.sh          # Refresh current page
#   ./refresh.sh --hard   # Full page reload (clears cache)
#
# ============================================

LOG_FILE="/var/log/kiosk/refresh.log"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
}

# Check for xdotool
if ! command -v xdotool &> /dev/null; then
    log "ERROR: xdotool is not installed"
    echo "Error: xdotool required. Install with: sudo apt install xdotool"
    exit 1
fi

export DISPLAY=:0

# Find the Chromium window
WINDOW_ID=$(xdotool search --onlyvisible --class chromium | head -1)

if [ -z "$WINDOW_ID" ]; then
    log "ERROR: No Chromium window found"
    echo "Error: Chromium window not found. Is the kiosk running?"
    exit 1
fi

log "Found Chromium window: $WINDOW_ID"

# Activate the window
xdotool windowactivate --sync "$WINDOW_ID"

# Perform refresh
if [ "$1" == "--hard" ]; then
    # Hard refresh (Ctrl+Shift+R) - clears cache
    log "Performing hard refresh (cache clear)"
    xdotool key --clearmodifiers ctrl+shift+r
else
    # Normal refresh (F5)
    log "Performing normal refresh"
    xdotool key --clearmodifiers F5
fi

log "Refresh command sent successfully"
echo "Page refresh triggered"
