# Hyprland Active Workspaces OSD (Quickshell)

An elegant, smooth-animating Workspace Overview On-Screen Display (OSD) built using **Quickshell** and **QtQuick** for the Hyprland compositor. It slides down gracefully from the top of the screen to show active workspaces, focused states, and a list of running window titles inside each workspace.

## Features

- **Smooth Animations**: Drops down from the top using a cubic ease-out curve.
- **Hyprland Integration**: Tracks real-time active workspaces and focused environments natively.
- **Window Lists**: Displays the `appId` or window title of running applications in each workspace.
- **Visual Glow**: Features an active pulsing ambient border accent.
- **External Toggle Support**: Can be dismissed via an external file flag toggle (`/tmp/overview_exit_flag`).

---

## Installation & Running

Ensure you have `quickshell` installed on your Arch Linux system:

```bash
pacman -S quickshell
