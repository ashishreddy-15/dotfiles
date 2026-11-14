pragma Singleton

import QtQuick
import Quickshell

// The one place for colours, fonts and sizes. Every other file reads from here.
// Palette: "Carbon & Pewter". The same colours are used in:
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
    readonly property color bright:  "#d0d3d6"   // the one thing that should stand out (current workspace)

    // Accent and status (kept muted on purpose)
    readonly property color accent:  "#6c7f91"
    readonly property color ok:      "#7d9889"
    readonly property color warn:    "#a8976f"
    readonly property color err:     "#a67a7e"

    // Fonts
    readonly property string fontFamily: "Maple Mono NF"   // the one font used everywhere
    readonly property int fontSize: 12      // notifications, panels, indicators
    readonly property int barFontSize: 12   // the bar (Maple Mono)

    // Sizes
    readonly property int barHeight: 28
    // The bar has no background, so its text must stand out from the wallpaper behind it. When the top edge
    // of the wallpaper is light (measured by Wallpaper.qml), the bar switches to dark text, like the macOS menu bar.
    readonly property real lightWallpaper: 105        // top-edge brightness (0-255) above which the bar text turns dark
    readonly property real wallpaperScrim: 0.35       // darkening along the top edge, under light text
    readonly property real wallpaperScrimLight: 0.30  // whitening along the top edge, under dark text
    readonly property bool barOnLight: ShellState.topLuminance > lightWallpaper

    // Bar colours: the normal palette, or darker versions of it for light wallpapers.
    readonly property color barText:   barOnLight ? "#1b1e21" : text
    readonly property color barDim:    barOnLight ? "#4e555b" : dim
    readonly property color barBright: barOnLight ? "#000000" : bright
    readonly property color barAccent: barOnLight ? "#34495c" : accent
    readonly property color barOk:     barOnLight ? "#2b6249" : ok
    readonly property color barWarn:   barOnLight ? "#7a5a0b" : warn
    readonly property color barErr:    barOnLight ? "#8a2c33" : err
    readonly property real barOpacity: 0      // 0 = no background, text sits on the wallpaper; 1 = solid strip
    readonly property int radius:    6
    readonly property int pad:       10

    // The monitor that gets the full bar. Others get workspaces + clock only,
    // unless this one is unplugged.
    readonly property string mainOutput: "HDMI-A-1"
}
