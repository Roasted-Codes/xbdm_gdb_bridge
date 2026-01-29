#!/bin/bash
# XBDM Relay for Windows Native Applications
#
# This script runs a socat relay that allows Windows applications
# to connect to XBDM through WSL.
#
# HOW IT WORKS:
#   1. socat listens on a high port (no root needed) inside WSL
#   2. Windows netsh portproxy maps port 731 to WSL
#   3. socat forwards traffic to xemu
#
# Ports:
#   XBDM: 7310 (WSL) -> 731 (xemu)
#
# Usage:
#   ./start_relay.sh           # Start relay
#   ./start_relay.sh --status  # Check if relay is running
#
# On Windows, use relay.bat (Run as Administrator)

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="$SCRIPT_DIR/xbdm_config.ini"

# High port - no root needed
XBDM_LOCAL_PORT="7310"

# Target port on xemu
XBDM_REMOTE_PORT="731"

# Default values
XBOX_IP=""

# Get WSL's IP address (visible to Windows)
get_wsl_ip() {
    hostname -I | awk '{print $1}'
}

# Parse config file (strip Windows line endings)
if [[ -f "$CONFIG_FILE" ]]; then
    while IFS='=' read -r key value; do
        [[ "$key" =~ ^[[:space:]]*# ]] && continue
        [[ -z "$key" ]] && continue
        key=$(echo "$key" | tr -d '\r' | xargs)
        value=$(echo "$value" | tr -d '\r' | xargs)
        case "$key" in
            xbox_ip) XBOX_IP="$value" ;;
        esac
    done < "$CONFIG_FILE"
fi

# Check for socat
check_socat() {
    if ! command -v socat &> /dev/null; then
        echo "Error: socat is not installed."
        echo ""
        echo "Install it with:"
        echo "  sudo apt install socat"
        exit 1
    fi
}

# Check status
check_status() {
    local wsl_ip=$(get_wsl_ip)
    local xbdm_running=false

    if ss -tlnp 2>/dev/null | grep -q ":$XBDM_LOCAL_PORT"; then
        xbdm_running=true
    fi

    if $xbdm_running; then
        echo "Relay status:"
        echo "  XBDM (port $XBDM_LOCAL_PORT): running"
        echo ""
        echo "WSL IP: $wsl_ip"
        return 0
    fi

    echo "Relay is not running"
    echo ""
    echo "Start with: relay.bat (Run as Administrator)"
    return 1
}

# Cleanup on exit
cleanup() {
    echo ""
    echo "Stopping relay..."
    kill $XBDM_PID 2>/dev/null
    exit 0
}

# Start relays
start_relay() {
    local wsl_ip=$(get_wsl_ip)

    if [[ -z "$XBOX_IP" ]]; then
        echo "Error: No Xbox IP configured."
        echo "Run setup.ps1 or create xbdm_config.ini first."
        exit 1
    fi

    check_socat

    # Check if already running
    if ss -tlnp 2>/dev/null | grep -q ":$XBDM_LOCAL_PORT"; then
        echo "XBDM relay already running on port $XBDM_LOCAL_PORT"
        exit 1
    fi

    echo ""
    echo "========================================"
    echo "  XBDM Relay"
    echo "========================================"
    echo ""
    echo "WSL listening on:"
    echo "  XBDM: port $XBDM_LOCAL_PORT -> $XBOX_IP:$XBDM_REMOTE_PORT"
    echo ""
    echo "WSL IP: $wsl_ip"
    echo ""
    echo "Keep this window open! Press Ctrl+C to stop."
    echo ""

    # Set up cleanup trap
    trap cleanup SIGINT SIGTERM

    # Start XBDM relay
    socat TCP-LISTEN:$XBDM_LOCAL_PORT,bind=0.0.0.0,fork,reuseaddr TCP:$XBOX_IP:$XBDM_REMOTE_PORT &
    XBDM_PID=$!

    echo "Relay started (PID: $XBDM_PID)"
    echo ""

    # Wait for exit
    wait
}

# Main
case "${1:-}" in
    --status)
        check_status
        ;;
    --help|-h)
        echo "XBDM Relay - Allows Windows apps to connect to xemu"
        echo ""
        echo "Usage:"
        echo "  ./start_relay.sh           Start relay"
        echo "  ./start_relay.sh --status  Check relay status"
        echo ""
        echo "On Windows, use relay.bat (Run as Administrator)"
        ;;
    *)
        start_relay
        ;;
esac
