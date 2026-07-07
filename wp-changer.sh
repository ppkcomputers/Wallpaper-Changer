#!/usr/bin/env bash

WP_DIR="$HOME/Pictures/Wallpaper"
SOCKET_FILE="/run/user/$(id -u)/wayland-1-awww-daemon.sock"

# Handle clean exit on Ctrl+C for the script loop only
cleanup() {
    echo -e "\nScript stopped. The background daemon will keep running your wallpaper."
    exit 0
}
trap cleanup SIGINT SIGTERM

# Check if the folder exists; if not, create it
if [ ! -d "$WP_DIR" ]; then
    mkdir -p "$WP_DIR"
fi

# Ensure the actual awww-daemon binary is running cleanly
if [ ! -S "$SOCKET_FILE" ] && ! pgrep -x "awww-daemon" > /dev/null; then
    echo "awww-daemon not detected. Launching in an isolated session..."
    # setsid completely detaches the daemon from the terminal's Ctrl+C signals
    setsid /usr/bin/awww-daemon > /dev/null 2>&1 &
    sleep 1
fi

# Initialize an empty array for our shuffled playlist queue
playlist=()

while true; do
    # If our playlist queue is empty, rebuild it by shuffling all current files
    if [ ${#playlist[@]} -eq 0 ]; then
        mapfile -t playlist < <(find "$WP_DIR" -type f \( -name "*.jpg" -o -name "*.jpeg" -o -name "*.png" -o -name "*.webp" \) | shuf)
    fi

    # Only proceed if we actually found files to play
    if [ ${#playlist[@]} -gt 0 ]; then
        # Pop the first wallpaper off our shuffled queue
        NEXT_WP="${playlist[0]}"
        playlist=("${playlist[@]:1}")

        if [ -f "$NEXT_WP" ]; then
            /usr/bin/awww img "$NEXT_WP" --transition-type random --transition-duration 1.5
        fi
    fi

    # Set to 3600 for 1 hour. Change to 5 for rapid testing.
    sleep 3600
done
