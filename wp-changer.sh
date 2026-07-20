#!/usr/bin/env bash

WP_DIR="$HOME/Pictures/Wallpaper"
CONFIG_DIR="$HOME/.config/Quickshell/WallpaperChanger"
STATE_FILE="$CONFIG_DIR/state.conf"

# Updated to point directly to Brave-Origin-Beta Profile 2
BRAVE_DIR="$HOME/.config/BraveSoftware/Brave-Origin-Beta/Profile 2/sanitized_background_images"

SOCKET_FILE="${XDG_RUNTIME_DIR}/awww-${WAYLAND_DISPLAY:-wayland-0}.socket"

mkdir -p "$WP_DIR" "$CONFIG_DIR"
touch "$STATE_FILE"

[[ ! $(grep "AUTOMATE=" "$STATE_FILE") ]] && echo "AUTOMATE=false" >> "$STATE_FILE"
[[ ! $(grep "LAST_WP=" "$STATE_FILE") ]] && echo "LAST_WP=" >> "$STATE_FILE"

# Robust sync function that handles format conversion
sync_brave() {
    local wp="$1"
    if [ -d "$BRAVE_DIR" ] && [ -f "$wp" ]; then
        local brave_target
        brave_target=$(ls "$BRAVE_DIR" 2>/dev/null | head -n 1)
        if [ -n "$brave_target" ]; then
            if command -v magick &>/dev/null; then
                magick "$wp" "$BRAVE_DIR/$brave_target"
            else
                cp "$wp" "$BRAVE_DIR/$brave_target"
            fi
        fi
    fi
}

verify_backend() {
    mkdir -p "$HOME/.cache/awww"
    if [ ! -S "$SOCKET_FILE" ] && ! pgrep -x "awww-daemon" > /dev/null; then
        setsid /usr/bin/awww-daemon > /dev/null 2>&1 &
        sleep 0.5
    fi
}

save_state() {
    local wp="$1"
    local auto="$2"
    sed -i "s|LAST_WP=.*|LAST_WP=$wp|" "$STATE_FILE"
    sed -i "s|AUTOMATE=.*|AUTOMATE=$auto|" "$STATE_FILE"
}

init_systemd_units() {
    local service_dir="$HOME/.config/systemd/user"
    local service_file="$service_dir/wp-automate.service"
    local timer_file="$service_dir/wp-automate.timer"

    mkdir -p "$service_dir"

    local tmp_service=$(mktemp)
    local tmp_timer=$(mktemp)

    cat << 'INNER_EOF' > "$tmp_service"
[Unit]
Description=Rotate wallpaper via awww
After=graphical-session.target

[Service]
Type=oneshot
ExecStart=%h/.config/Quickshell/WallpaperChanger/wp-changer.sh --step-loop
INNER_EOF

    cat << 'INNER_EOF' > "$tmp_timer"
[Unit]
Description=Run wallpaper automation loops

[Timer]
OnActiveSec=1s
OnUnitActiveSec=30min
AccuracySec=100ms

[Install]
WantedBy=timers.target
INNER_EOF

    local reload_needed=0

    if ! cmp -s "$tmp_service" "$service_file"; then
        mv "$tmp_service" "$service_file"
        reload_needed=1
    else
        rm "$tmp_service"
    fi

    if ! cmp -s "$tmp_timer" "$timer_file"; then
        mv "$tmp_timer" "$timer_file"
        reload_needed=1
    else
        rm "$tmp_timer"
    fi

    if [ "$reload_needed" -eq 1 ]; then
        systemctl --user daemon-reload
    fi
}

verify_backend

if [[ "$1" == "--boot" ]]; then
    init_systemd_units
    LAST_WP=$(grep "LAST_WP=" "$STATE_FILE" | cut -d'=' -f2)
    AUTOMATE_STATE=$(grep "AUTOMATE=" "$STATE_FILE" | cut -d'=' -f2)

    if [[ -f "$LAST_WP" ]]; then
        /usr/bin/awww img "$LAST_WP" --transition-type none
        sync_brave "$LAST_WP"
    fi

    if [[ "$AUTOMATE_STATE" == "true" ]]; then
        systemctl --user start wp-automate.timer
    fi
    exit 0
fi

if [[ "$1" == "--set" && -f "$2" ]]; then
    /usr/bin/awww img "$2" --transition-type random --transition-duration 1.5
    sync_brave "$2"
    AUTOMATE_STATE=$(grep "AUTOMATE=" "$STATE_FILE" | cut -d'=' -f2)
    save_state "$2" "$AUTOMATE_STATE"
    exit 0
fi

if [[ "$1" == "--start-auto" || "$1" == "--save-auto" && "$2" == "true" ]]; then
    systemctl --user start wp-automate.timer
    CURRENT_LAST=$(grep 'LAST_WP=' "$STATE_FILE" | cut -d'=' -f2)
    save_state "$CURRENT_LAST" "true"
    exit 0
fi

if [[ "$1" == "--stop-auto" || "$1" == "--save-auto" && "$2" == "false" ]]; then
    systemctl --user stop wp-automate.timer
    CURRENT_LAST=$(grep 'LAST_WP=' "$STATE_FILE" | cut -d'=' -f2)
    save_state "$CURRENT_LAST" "false"
    exit 0
fi

if [[ "$1" == "--step-loop" ]]; then
    mapfile -t playlist < <(find "$WP_DIR" -type f \( -name "*.jpg" -o -name "*.jpeg" -o -name "*.png" -o -name "*.webp" \) | shuf)

    if [ ${#playlist[@]} -gt 0 ]; then
        NEXT_WP="${playlist[0]}"
        /usr/bin/awww img "$NEXT_WP" --transition-type random --transition-duration 1.5
        sync_brave "$NEXT_WP"
        save_state "$NEXT_WP" "true"
    fi
    exit 0
fi
