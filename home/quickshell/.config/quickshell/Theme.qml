pragma Singleton

import QtQuick
import Quickshell

// The one place for colours, shape, depth, type and motion. Every other file reads from here:
// no number or colour for how things look should be written anywhere else.
// Palette: "Carbon & Pewter". The same colours are used in:
//   hypr/modules/look.lua (borders), hypr/hyprlock.conf, kitty/kitty.conf
// The same shape and motion numbers are repeated in hypr/modules/look.lua (rounding, animation speeds).
Singleton {
    // ---- colour: surfaces, darkest to lightest ----
    readonly property color bg:      "#111111"   // behind everything
    readonly property color surface: "#141414"   // solid panels
    readonly property color raised:  "#1b1b1b"   // solid raised parts
    readonly property color border:  "#262626"

    // ---- colour: text ----
    readonly property color text:    "#adb0b3"
    readonly property color dim:     "#666a6e"
    readonly property color bright:  "#d0d3d6"   // the one thing that should stand out (current workspace)

    // ---- colour: accent and status (kept muted on purpose) ----
    readonly property color accent:  "#6c7f91"
    readonly property color ok:      "#7d9889"
    readonly property color warn:    "#a8976f"
    readonly property color err:     "#a67a7e"

    // ---- floating cards (panel, pickers, indicator): frosted glass ----
    // The surface is slightly see-through; Hyprland blurs what is behind it (hypr/modules/rules.lua).
    readonly property real  cardOpacity: 0.80
    readonly property color card:     Qt.rgba(0.078, 0.078, 0.078, cardOpacity)   // #141414, see-through
    // Light wash over a card for hover and selection. White on a dark card works on any wallpaper.
    readonly property color clear:    Qt.rgba(1, 1, 1, 0)      // "no wash": animates cleanly to hover/selected
    readonly property color hover:    Qt.rgba(1, 1, 1, 0.07)
    readonly property color selected: Qt.rgba(1, 1, 1, 0.12)
    readonly property color selectedHover: Qt.rgba(1, 1, 1, 0.17)   // a selected / "on" item under the pointer

    // ---- shape ----
    // One rule: a row inside a card has radius = card radius - the gap to the card's edge (10 - 4 = 6),
    // so the curves stay parallel. Hyprland's window rounding uses the card radius too.
    readonly property int radiusCard:  10    // windows and floating cards
    readonly property int radiusRow:   6     // rows, buttons and inputs inside a card
    readonly property int radiusSmall: 3     // slider tracks, small marks
    readonly property int segmentInset: 3    // gap between a segmented control's outline and its choices (radiusRow - 3 = radiusSmall)
    readonly property int radiusMark:  1     // 2 px accent marks (selection, timeout, tile)
    readonly property int cardInset:   4     // gap between a card's edge and the rows inside it

    // ---- depth ----
    readonly property color shadow:       Qt.rgba(0, 0, 0, 0.45)
    readonly property int   shadowBlur:   28
    readonly property int   shadowOffset: 8    // the shadow sits a little below the card
    readonly property int   shadowMargin: 36   // room a window must leave around a card so the shadow is not cut off

    // ---- type ----
    readonly property string fontFamily: "Maple Mono NF"   // the one font used everywhere
    readonly property int fontSmall: 11     // secondary text: app names, hints
    readonly property int fontBase:  12     // normal text everywhere, the bar included
    readonly property int fontLarge: 14     // list entries in pickers
    readonly property int fontMark:  8      // the selection dot (a filled circle is heavy at text size)
    readonly property int fontXL:    16     // the search field of pickers
    readonly property int fontSize:    fontBase   // (older names, same values)
    readonly property int barFontSize: fontBase

    // ---- glyphs ----
    // One icon set: the FontAwesome symbols that ship inside Maple Mono NF, so every icon has the same weight and
    // sits on the same baseline as the text. Write icons through these names, never as a literal character.
    readonly property string glyphNext:    "\uf105"   // chevron right: opens a page / a menu
    readonly property string glyphBack:    "\uf104"   // chevron left: back
    readonly property string glyphClose:   "\uf00d"   // x
    readonly property string glyphMark:    "\uf111"   // filled dot: the chosen item in a list
    readonly property string glyphGear:    "\uf013"   // the settings button
    readonly property string glyphMinus:   "\uf068"
    readonly property string glyphPlus:    "\uf067"
    readonly property string glyphCheck:   "\uf00c"   // tick: a ticked menu entry
    readonly property string glyphLock:    "\uf023"   // padlock: secured network
    readonly property string glyphPrev:    "\uf048"
    readonly property string glyphPlay:    "\uf04b"
    readonly property string glyphPause:   "\uf04c"
    readonly property string glyphForward: "\uf051"

    // ---- space ----
    readonly property int pad:        10    // bar edge padding
    readonly property int padContent: 14    // inside a card that holds free-form content (notifications)
    // The control center lines every row up on one grid: a label column, then the value or slider.
    readonly property int labelWidth: 76    // room for "wallpaper" (the longest label)
    readonly property int valueX:     90    // where values and sliders start (10 inset + label column + gap)

    // ---- motion ----
    // Enter: durBase, ease out. Exit: durFast, ease out. Resizing a card: durBase. Hover and selection: durFast.
    // Slow, ambient changes (wallpaper, bar colours): durAmbient. Hyprland's window animations use the same numbers.
    readonly property int durFast:    90
    readonly property int durBase:    140
    readonly property int durSlow:    240
    readonly property int durAmbient: 400
    readonly property int easeOut:    Easing.OutCubic
    readonly property int easeInOut:  Easing.InOutCubic

    // ---- behaviour ----
    readonly property real brightnessStep: 0.05   // one press of a brightness key (5%)

    // ---- the bar ----
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

    // ---- screens ----
    // The monitor that gets the full bar. Others get workspaces + clock only,
    // unless this one is unplugged.
    readonly property string mainOutput: "HDMI-A-1"
}
