#!/usr/bin/env bash

# Expand the home directory cleanly
TARGET_QML="$HOME/.config/Quickshell/WallpaperChanger/wallpaper-gui.qml"

# Check if Quickshell is already running this specific file
if pgrep -f "quickshell.*$TARGET_QML" >/dev/null; then
    pkill -f "quickshell.*$TARGET_QML"
else
    # Launch it in the background using your software rendering backend
    QT_QUICK_BACKEND=software quickshell -p "$TARGET_QML" &
fi
