#!/bin/bash
# float installer — builds xwinwrap from source and symlinks float to PATH

set -e

FLOAT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "=== Float Installer ==="
echo ""

# Check dependencies
for cmd in mpv xrandr git gcc; do
    if ! command -v "$cmd" &>/dev/null; then
        echo "Missing dependency: $cmd"
        if [ "$cmd" = "mpv" ]; then
            echo "  Install: sudo apt install mpv"
        elif [ "$cmd" = "gcc" ]; then
            echo "  Install: sudo apt install build-essential"
        elif [ "$cmd" = "xrandr" ]; then
            echo "  Install: sudo apt install x11-xserver-utils"
        fi
        exit 1
    fi
done

# Build xwinwrap if not installed
if ! command -v xwinwrap &>/dev/null; then
    echo "Building xwinwrap from source..."
    TMPDIR=$(mktemp -d)
    trap 'rm -rf "$TMPDIR"' EXIT
    git clone https://github.com/ujjwal96/xwinwrap.git "$TMPDIR/xwinwrap" 2>/dev/null
    cd "$TMPDIR/xwinwrap"
    make 2>&1
    sudo cp xwinwrap /usr/local/bin/
    sudo chmod +x /usr/local/bin/xwinwrap
    rm -rf "$TMPDIR"
    trap - EXIT
    echo "xwinwrap installed to /usr/local/bin/"
else
    echo "xwinwrap already installed."
fi

# Make float executable
chmod +x "$FLOAT_DIR/float"

# Symlink to ~/bin (assumed on PATH)
mkdir -p "$HOME/bin"
ln -sf "$FLOAT_DIR/float" "$HOME/bin/float"
echo "Symlinked float -> $HOME/bin/float"

echo ""
echo "Installation complete. Run 'float' to get started."
echo ""
echo "Quick start:"
echo "  float ~/Videos --shuffle              # Single video wallpaper"
echo "  float ~/Videos --collage              # Random tiled collage"
echo "  float ~/Videos --collage --opacity 0.1"
echo "  float --stop                          # Kill it"
