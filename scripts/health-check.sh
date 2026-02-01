#!/bin/bash
# ============================================
# Cassidy Asphalt - Health Check Script
# ============================================
#
# Monitors kiosk health and reports status.
# Can be run manually or via cron for monitoring.
#
# Usage:
#   ./health-check.sh           # Full health check
#   ./health-check.sh --json    # Output as JSON
#   ./health-check.sh --brief   # One-line summary
#
# ============================================

CONFIG_DIR="/opt/kiosk/config"
LOG_DIR="/var/log/kiosk"

# Colors for terminal output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Status tracking
ISSUES=()

check_passed() {
    echo -e "${GREEN}[PASS]${NC} $1"
}

check_failed() {
    echo -e "${RED}[FAIL]${NC} $1"
    ISSUES+=("$1")
}

check_warning() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

# Check functions
check_network() {
    if ping -c 1 8.8.8.8 &> /dev/null; then
        check_passed "Network connectivity"
        return 0
    else
        check_failed "Network connectivity"
        return 1
    fi
}

check_dns() {
    if host app.smartsheet.com &> /dev/null; then
        check_passed "DNS resolution"
        return 0
    else
        check_failed "DNS resolution"
        return 1
    fi
}

check_smartsheet() {
    if curl -s --max-time 10 "https://app.smartsheet.com" > /dev/null; then
        check_passed "Smartsheet reachable"
        return 0
    else
        check_failed "Smartsheet unreachable"
        return 1
    fi
}

check_display() {
    if [ -n "$DISPLAY" ] || xset q &> /dev/null; then
        check_passed "Display server"
        return 0
    else
        check_failed "Display server"
        return 1
    fi
}

check_chromium_running() {
    if pgrep -x "chromium" > /dev/null || pgrep -f "chromium-browser" > /dev/null; then
        check_passed "Chromium running"
        return 0
    else
        check_failed "Chromium not running"
        return 1
    fi
}

check_kiosk_service() {
    if systemctl is-active --quiet kiosk; then
        check_passed "Kiosk service active"
        return 0
    else
        check_failed "Kiosk service not active"
        return 1
    fi
}

check_disk_space() {
    local usage=$(df / | tail -1 | awk '{print $5}' | tr -d '%')
    if [ "$usage" -lt 80 ]; then
        check_passed "Disk space (${usage}% used)"
        return 0
    elif [ "$usage" -lt 90 ]; then
        check_warning "Disk space (${usage}% used)"
        return 0
    else
        check_failed "Disk space critical (${usage}% used)"
        return 1
    fi
}

check_memory() {
    local usage=$(free | grep Mem | awk '{printf "%.0f", $3/$2 * 100}')
    if [ "$usage" -lt 80 ]; then
        check_passed "Memory usage (${usage}%)"
        return 0
    elif [ "$usage" -lt 90 ]; then
        check_warning "Memory usage (${usage}%)"
        return 0
    else
        check_failed "Memory usage critical (${usage}%)"
        return 1
    fi
}

check_cpu_temp() {
    if [ -f /sys/class/thermal/thermal_zone0/temp ]; then
        local temp=$(cat /sys/class/thermal/thermal_zone0/temp)
        local temp_c=$((temp / 1000))
        if [ "$temp_c" -lt 70 ]; then
            check_passed "CPU temperature (${temp_c}C)"
            return 0
        elif [ "$temp_c" -lt 80 ]; then
            check_warning "CPU temperature (${temp_c}C)"
            return 0
        else
            check_failed "CPU temperature critical (${temp_c}C)"
            return 1
        fi
    else
        check_warning "CPU temperature (unable to read)"
        return 0
    fi
}

check_uptime() {
    local uptime_seconds=$(cat /proc/uptime | cut -d' ' -f1 | cut -d'.' -f1)
    local uptime_days=$((uptime_seconds / 86400))
    local uptime_hours=$(((uptime_seconds % 86400) / 3600))
    check_passed "Uptime: ${uptime_days}d ${uptime_hours}h"
}

get_system_info() {
    echo ""
    echo "System Information:"
    echo "==================="
    echo "Hostname: $(hostname)"
    echo "IP Address: $(hostname -I | awk '{print $1}')"
    echo "Kernel: $(uname -r)"
    echo "Pi Model: $(cat /proc/device-tree/model 2>/dev/null || echo 'Unknown')"
}

# JSON output
output_json() {
    local status="healthy"
    if [ ${#ISSUES[@]} -gt 0 ]; then
        status="unhealthy"
    fi

    echo "{"
    echo "  \"hostname\": \"$(hostname)\","
    echo "  \"timestamp\": \"$(date -Iseconds)\","
    echo "  \"status\": \"$status\","
    echo "  \"issues\": ["
    local first=true
    for issue in "${ISSUES[@]}"; do
        if [ "$first" = true ]; then
            first=false
        else
            echo ","
        fi
        echo -n "    \"$issue\""
    done
    echo ""
    echo "  ],"
    echo "  \"uptime_seconds\": $(cat /proc/uptime | cut -d' ' -f1 | cut -d'.' -f1),"
    echo "  \"memory_percent\": $(free | grep Mem | awk '{printf "%.0f", $3/$2 * 100}'),"
    echo "  \"disk_percent\": $(df / | tail -1 | awk '{print $5}' | tr -d '%')"
    echo "}"
}

# Brief output
output_brief() {
    local status="OK"
    if [ ${#ISSUES[@]} -gt 0 ]; then
        status="ISSUES: ${#ISSUES[@]}"
    fi
    echo "$(hostname): $status"
}

# Main
main() {
    case "$1" in
        --json)
            # Run checks silently, output JSON
            exec 3>&1
            exec 1>/dev/null
            check_network
            check_dns
            check_smartsheet
            check_display
            check_chromium_running
            check_kiosk_service
            check_disk_space
            check_memory
            check_cpu_temp
            exec 1>&3
            output_json
            ;;
        --brief)
            exec 3>&1
            exec 1>/dev/null
            check_network
            check_chromium_running
            check_kiosk_service
            check_disk_space
            check_memory
            exec 1>&3
            output_brief
            ;;
        *)
            echo "============================================"
            echo "Cassidy Asphalt Kiosk Health Check"
            echo "$(date)"
            echo "============================================"
            echo ""

            echo "Connectivity:"
            echo "-------------"
            check_network
            check_dns
            check_smartsheet
            echo ""

            echo "Display & Browser:"
            echo "------------------"
            check_display
            check_chromium_running
            check_kiosk_service
            echo ""

            echo "System Resources:"
            echo "-----------------"
            check_disk_space
            check_memory
            check_cpu_temp
            check_uptime

            get_system_info

            echo ""
            echo "============================================"
            if [ ${#ISSUES[@]} -eq 0 ]; then
                echo -e "${GREEN}All checks passed!${NC}"
            else
                echo -e "${RED}Issues found: ${#ISSUES[@]}${NC}"
                for issue in "${ISSUES[@]}"; do
                    echo "  - $issue"
                done
            fi
            echo "============================================"
            ;;
    esac
}

main "$@"
