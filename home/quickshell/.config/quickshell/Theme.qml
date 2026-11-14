pragma Singleton

import QtQuick
import Quickshell

// The one place for colours, fonts and sizes. Every other file reads from here.
// Palette: "Carbon & Ice". The same colours are used in:
//   hypr/modules/look.lua (borders), hypr/hyprlock.conf, kitty/kitty.conf
Singleton {
    // Surfaces, darkest to lightest
    readonly property color bg:      "#111111"   // behind everything
    readonly property color surface: "#141414"   // bar, panels
    readonly property color raised:  "#1b1b1b"   // pop-ups, hovered items
    readonly property color border:  "#262626"

    // Text
    readonly property color text:    "#adb0b3"
    readonly property color dim:     "#666a6e"

    // Accent and status (kept muted on purpose)
    readonly property color accent:  "#8a9fab"
    readonly property color ok:      "#7d9889"
    readonly property color warn:    "#a8976f"
    readonly property color err:     "#a67a7e"

    // Fonts
    readonly property string uiFont:   "Asap"            // panels, notifications, launcher
    readonly property string monoFont: "Maple Mono NF"   // bar, numbers, icons
    readonly property int uiWidth:  92    // Asap width axis: 75 (narrow) .. 100 (normal) .. 125 (wide)
    readonly property int fontSize: 13

    // Sizes
    readonly property int barHeight: 30
    readonly property int radius:    6
    readonly property int pad:       10

    // The monitor that gets the full bar. Others get workspaces + clock only,
    // unless this one is unplugged.
    readonly property string mainOutput: "HDMI-A-1"
}
