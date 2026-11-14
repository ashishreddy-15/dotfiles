pragma Singleton

import QtQuick
import Quickshell

// The one place for colours, fonts and sizes. Every other file reads from here.
// Palette: "Abyss & Ice". The same colours are used in:
//   hypr/modules/look.lua (borders), hypr/hyprlock.conf, kitty/kitty.conf
Singleton {
    // Surfaces, darkest to lightest
    readonly property color bg:      "#0f1114"   // behind everything
    readonly property color surface: "#15181c"   // bar, panels
    readonly property color raised:  "#1d2126"   // pop-ups, hovered items
    readonly property color border:  "#2a3037"

    // Text
    readonly property color text:    "#c0c6cc"
    readonly property color dim:     "#6f7882"

    // Accent and status (kept muted on purpose)
    readonly property color accent:  "#a3b9c4"
    readonly property color ok:      "#8aa79a"
    readonly property color warn:    "#b7a57f"
    readonly property color err:     "#b48488"

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
