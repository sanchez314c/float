#!/bin/bash
#
# Float - Linux Source Runner
#
set -e
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

echo "=== Float - Linux Source Runner ==="
echo ""

# Check dependencies
for cmd in mpv xrandr socat python3; do
    if ! command -v "$cmd" &>/dev/null; then
        echo "Missing: $cmd"
        exit 1
    fi
done

# Check xwinwrap
if ! command -v xwinwrap &>/dev/null; then
    echo "xwinwrap not found. Run ./install.sh first."
    exit 1
fi

echo "All dependencies OK."
echo ""

# Run float with provided args, or show usage
if [ $# -eq 0 ]; then
    ./float
else
    ./float "$@"
fi
