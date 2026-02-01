#!/bin/bash
#
# Float - macOS Source Runner
#
# NOTE: Float requires X11 (xwinwrap). On macOS, you need XQuartz installed.
# This script is provided for completeness but Float is primarily a Linux tool.
#
set -e
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

echo "=== Float - macOS Source Runner ==="
echo ""
echo "WARNING: Float requires X11 via xwinwrap. On macOS, install XQuartz first."
echo "Float is designed for Linux desktops. macOS support is experimental."
echo ""

# Check dependencies
for cmd in mpv socat python3; do
    if ! command -v "$cmd" &>/dev/null; then
        echo "Missing: $cmd (install via brew: brew install $cmd)"
        exit 1
    fi
done

if ! command -v xwinwrap &>/dev/null; then
    echo "xwinwrap not found. Run ./install.sh first (requires XQuartz)."
    exit 1
fi

if [ $# -eq 0 ]; then
    ./float
else
    ./float "$@"
fi
