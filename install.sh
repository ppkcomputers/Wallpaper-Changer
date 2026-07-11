#!/usr/bin/env bash

REPO_RAW_URL="https://raw.githubusercontent.com/ppkcomputers/Wallpaper-Changer/main"
TARGET_DIR="$HOME/.config/Quickshell/WallpaperChanger"
WP_DIR="$HOME/Pictures/Wallpaper"

echo "========================================="
echo "  Quickshell Wallpaper Changer Installer "
echo "========================================="

# 1. Dependency Check: Quickshell (Hard requirement to run the app)
if ! command -v quickshell &> /dev/null; then
    echo "[-] Error: 'quickshell' is not installed or not in your PATH."
    echo "    Please install quickshell for your distribution and try again."
    exit 1
fi
echo "[+] Quickshell detected."

# 2. Setup Target Configuration Directory
echo "[+] Creating configuration directory..."
mkdir -p "$TARGET_DIR"

# 3. Fetch Scripts and Assets from GitHub
FILES=("toggle.sh" "wallpaper-gui.qml" "wp-changer.sh")

echo "[+] Downloading source assets from GitHub..."
for file in "${FILES[@]}"; do
    echo "    -> Fetching $file..."
    curl -sSf "$REPO_RAW_URL/$file" -o "$TARGET_DIR/$file"
done

# 4. Generate a User-Universal state.conf locally
echo "[+] Generating universal local state configuration..."
cat << EOF > "$TARGET_DIR/state.conf"
AUTOMATE=false
LAST_WP=
EOF

# 5. Fix Script Execution Permissions
echo "[+] Finalizing script executable permissions..."
chmod +x "$TARGET_DIR/toggle.sh"
chmod +x "$TARGET_DIR/wp-changer.sh"

# 6. Dependency Check: Wallpaper Directory (Soft warning, doesn't halt install)
echo "-----------------------------------------"
if [ ! -d "$WP_DIR" ]; then
    echo "[!] Warning: Wallpaper directory not found at: $WP_DIR"
    echo "    The OSD requires this directory to function."
    echo "    Please create it and add your images before opening the menu:"
    echo "    mkdir -p $WP_DIR"
else
    echo "[+] Wallpaper directory verified: $WP_DIR"
fi

echo "========================================="
echo "[+] Installation completed successfully!"
echo "========================================="
echo "To launch and test the OSD interface from your terminal, run:"
echo "    $TARGET_DIR/toggle.sh"
echo "========================================="
