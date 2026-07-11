#!/usr/bin/env bash

# Exit immediately if a command exits with a non-zero status
set -e

REPO_RAW_URL="https://raw.githubusercontent.com/ppkcomputers/Wallpaper-Changer/main"
TARGET_DIR="$HOME/.config/Quickshell/WallpaperChanger"
WP_DIR="$HOME/Pictures/Wallpaper"

echo "========================================="
echo "  Quickshell Wallpaper Changer Installer "
echo "========================================="

# 1. Dependency Check: Quickshell
if ! command -v quickshell &> /dev/null; then
    echo "[-] Error: 'quickshell' is not installed or not in your PATH."
    echo "    Please install quickshell for your distribution and try again."
    exit 1
fi
echo "[+] Quickshell detected."

# 2. Dependency Check: Wallpaper Directory
if [ ! -d "$WP_DIR" ]; then
    echo "[-] Error: Wallpaper directory not found at: $WP_DIR"
    echo "    Please create this directory and add your wallpaper files before continuing:"
    echo "    mkdir -p $WP_DIR"
    exit 1
fi
echo "[+] Wallpaper directory verified: $WP_DIR"

# 3. Setup Target Configuration Directory
echo "[+] Creating configuration directory..."
mkdir -p "$TARGET_DIR"

# 4. Fetch Scripts and Assets from GitHub (Skipping state.conf to keep it universal)
FILES=("toggle.sh" "wallpaper-gui.qml" "wp-changer.sh")

echo "[+] Downloading source assets from GitHub..."
for file in "${FILES[@]}"; do
    echo "    -> Fetching $file..."
    curl -sSf "$REPO_RAW_URL/$file" -o "$TARGET_DIR/$file"
done

# 5. Generate a User-Universal state.conf locally
echo "[+] Generating universal local state configuration..."
cat << EOF > "$TARGET_DIR/state.conf"
AUTOMATE=false
LAST_WP=
EOF

# 6. Fix Script Execution Permissions
echo "[+] Finalizing script executable permissions..."
chmod +x "$TARGET_DIR/toggle.sh"
chmod +x "$TARGET_DIR/wp-changer.sh"

echo "========================================="
echo "[+] Installation completed successfully!"
echo "========================================="
echo "To launch and test the OSD interface from your terminal, run:"
echo "    $TARGET_DIR/toggle.sh"
echo "========================================="
