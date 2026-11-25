pragma Singleton

import QtQuick
import Quickshell

// The one place for colours, shape, depth, type and motion. Every other file reads from here:
// no number or colour for how things look should be written anywhere else.
// Palette: "Carbon & Pewter", in a dark and a light version. `dark` follows the colour scheme (Settings > Appearance,
// `appearance toggle`); Appearance.qml reads it from ~/.local/state/dotfiles/scheme at startup.
// Each colour is written as `dark ? "<dark>" : "<light>"` on one line (scripts/ui-check reads them). The same
// colours are used in:
//   hypr/modules/look.lua (borders), hypr/hyprlock.conf, kitty/kitty.conf, gtk-3.0/dark.css, nvim
// The same shape and motion numbers are repeated in hypr/modules/look.lua (rounding, animation speeds).
Singleton {
    readonly property bool dark: Appearance.dark

    // ---- colour: surfaces, darkest to lightest (in the light scheme: lightest to darkest) ----
    readonly property color bg:      dark ? "#111111" : "#ececea"   // behind everything
    readonly property color surface: dark ? "#141414" : "#f3f3f1"   // solid panels
    readonly property color raised:  dark ? "#1b1b1b" : "#fafaf9"   // solid raised parts
    readonly property color border:  dark ? "#262626" : "#d3d3d0"

    // ---- colour: text ----
    readonly property color text:    dark ? "#adb0b3" : "#3a3f44"
    readonly property color dim:     dark ? "#666a6e" : "#6b7177"
    readonly property color bright:  dark ? "#d0d3d6" : "#15181b"   // the one thing that should stand out (current workspace)

    // ---- colour: accent and status (kept muted on purpose) ----
    readonly property color accent:  dark ? "#6c7f91" : "#4d6379"
    readonly property color ok:      dark ? "#7d9889" : "#3f7359"
    readonly property color warn:    dark ? "#a8976f" : "#80631a"
    readonly property color err:     dark ? "#a67a7e" : "#95434a"

    // ---- floating cards (panel, pickers, indicator): frosted glass ----
    // The surface is slightly see-through; Hyprland blurs what is behind it (hypr/modules/rules.lua).
    readonly property real  cardOpacity: 0.80
    readonly property color card:     Qt.rgba(surface.r, surface.g, surface.b, cardOpacity)   // the surface, see-through
    // A wash over a card for hover and selection: white on a dark card, black on a light one. Works on any wallpaper.
    readonly property color clear:    dark ? Qt.rgba(1, 1, 1, 0)    : Qt.rgba(0, 0, 0, 0)      // "no wash": animates cleanly to hover/selected
    readonly property color hover:    dark ? Qt.rgba(1, 1, 1, 0.07) : Qt.rgba(0, 0, 0, 0.05)
    readonly property color selected: dark ? Qt.rgba(1, 1, 1, 0.12) : Qt.rgba(0, 0, 0, 0.09)
    readonly property color selectedHover: dark ? Qt.rgba(1, 1, 1, 0.17) : Qt.rgba(0, 0, 0, 0.13)   // a selected / "on" item under the pointer
    readonly property color sliderFill: Qt.rgba(accent.r, accent.g, accent.b, 0.55)   // the filled part of a pill slider: accent, half see-through

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
    readonly property color shadow:       Qt.rgba(0, 0, 0, dark ? 0.45 : 0.22)
    readonly property int   shadowBlur:   28
    readonly property int   shadowOffset: 8    // the shadow sits a little below the card
    readonly property int   shadowMargin: 36   // room a window must leave around a card so the shadow is not cut off

    // ---- type ----
    readonly property string fontFamily: "Maple Mono NF"   // the one font used everywhere
    readonly property int barFontWeight: Font.DemiBold    // the bar's text: a step heavier, so it reads over the wallpaper
    readonly property int barFontWeightStrong: Font.Bold       // what leads in the bar (the clock's time)
    readonly property int fontSmall: 11     // secondary text: app names, hints
    readonly property int fontBase:  12     // normal text everywhere, the bar included
    readonly property int fontLarge: 14     // list entries in pickers
    readonly property int fontMark:  8      // the selection dot (a filled circle is heavy at text size)
    readonly property int fontIcon:  28     // the big icons of the power menu
    readonly property int fontXL:    16     // the search field of pickers
    readonly property int fontSize:    fontBase   // (older names, same values)
    readonly property int barFontSize: fontBase

    // ---- glyphs ----
    // One icon set: the FontAwesome symbols that ship inside Maple Mono NF, so every icon has the same weight and
    // sits on the same baseline as the text. Write icons through these names, never as a literal character.
    readonly property string glyphDown:    "\uf107"   // chevron down: expand
    readonly property string glyphUp:      "\uf106"   // chevron up: collapse
    readonly property string glyphNext:    "\uf105"   // chevron right: opens a page / a menu
    readonly property string glyphBack:    "\uf104"   // chevron left: back
    readonly property string glyphClose:   "\uf00d"   // x
    readonly property string glyphMark:    "\uf111"   // filled dot: the chosen item in a list
    readonly property string glyphWifi:      "\uf1eb"
    readonly property string glyphBluetooth: "\uf293"
    readonly property string glyphBell:      "\uf0f3"   // bell: notifications
    readonly property string glyphSilent:    "\uf1f6"   // bell with a line through it: Do Not Disturb
    readonly property string glyphSun:       "\uf185"   // sun: light / dark scheme
    readonly property string glyphNight:     "\uf186"   // moon: night light
    readonly property string glyphAwake:     "\uf0f4"   // coffee cup: keep awake
    readonly property string glyphBright:    "\uf042"   // half-filled circle: brightness
    readonly property string glyphVolume:    "\uf028"
    readonly property string glyphMuted:     "\uf026"
    readonly property string glyphMic:       "\uf130"
    readonly property string glyphMicOff:    "\uf131"
    readonly property string glyphBattery:   "\uf240"
    readonly property string glyphBrush:     "\uf1fc"   // paint brush: appearance
    readonly property string glyphImage:     "\uf03e"   // picture: wallpaper
    readonly property string glyphSearch:    "\uf002"   // magnifying glass
    readonly property string glyphTouchpad:  "\uf25a"   // hand pointer: touchpad
    readonly property string glyphPen:       "\uf040"   // pencil: tablet
    readonly property string glyphInfo:      "\uf05a"   // i in a circle: about
    readonly property string glyphFedora:    "\uf30a"   // the Fedora mark (from the font's logo set, the one icon not from FontAwesome)
    readonly property string glyphGear:    "\uf013"   // the settings button
    readonly property string glyphMinus:   "\uf068"
    readonly property string glyphPlus:    "\uf067"
    readonly property string glyphCheck:   "\uf00c"   // tick: a ticked menu entry
    readonly property string glyphLock:    "\uf023"   // padlock: secured network, lock the screen
    readonly property string glyphLogout:  "\uf08b"   // sign out
    readonly property string glyphSuspend: "\uf236"   // bed
    readonly property string glyphReboot:  "\uf01e"   // circular arrow
    readonly property string glyphPower:   "\uf011"   // power symbol
    readonly property string glyphPrev:    "\uf048"
    readonly property string glyphPlay:    "\uf04b"
    readonly property string glyphPause:   "\uf04c"
    readonly property string glyphForward: "\uf051"
    readonly property string glyphTimes:   "\u00d7"   // ×: a multiplier, e.g. scroll speed 1.5×

    // ---- space ----
    readonly property int pad:        10    // bar edge padding
    readonly property int padContent: 14    // inside a card that holds free-form content (notifications)
    // The control center lines every row up on one grid: a label column, then the value or slider.
    readonly property int labelWidth: 76    // room for "wallpaper" (the longest label)
    readonly property int valueX:     90    // where values and sliders start (10 inset + label column + gap)

    // ---- motion ----
    // Spatial properties (x, y, width, height, scale) use physical springs so retargeting mid-flight keeps momentum.
    // Opacity, colour and dismissals use monotonic durations (durFast / durBase / durAmbient) and never overshoot:
    // an exit moves on the same durFast / easeOut curve as its fade, so the motion is seen before the item is gone.
    // Hyprland's window and workspace animations use matched spring curves in hypr/modules/look.lua.
    // One spring per job. Write them through the presets in ui/ (HighlightMotion, PressMotion, ValueMotion,
    // SmoothMotion), which carry the spring, damping and settling threshold together.
    // (Qt steps a SpringAnimation every 16 ms; measured step responses: overshoot / time to settle within 2%.)
    readonly property real springHighlight:  6.0   // follows a selection (lists, grids, pills, tabs): 0.2% / ~210 ms
    readonly property real dampingHighlight: 0.48
    readonly property real springPress:      5.5   // the press-in scale only: the small bounce (6%) reads as tactile
    readonly property real dampingPress:     0.36
    readonly property real springValue:      5.5   // a fill that shows a value (sliders, OSD, meters): 0% / ~320 ms
    readonly property real dampingValue:     0.55
    readonly property real springSmooth:  3.8     // cards, bar slide, dynamic height, notification re-stacking: 0% / ~300 ms
    readonly property real dampingSmooth: 0.42
    readonly property int  exitDrift:     12      // px a dismissed notification drifts sideways as it fades
    readonly property real epsNorm:       0.004   // settling threshold for 0..1 properties (scale, progress)
    readonly property real epsPx:         0.4     // settling threshold for pixel coordinates (x, y, width, height)
    readonly property real pressScale:    0.94    // tactile press-in scale for round toggles and action tiles

    readonly property int durFast:    90
    readonly property int durBase:    140
    readonly property int durSlow:    240
    readonly property int durAmbient: 400
    readonly property int durPulse:   800     // one half of a slow attention pulse (recording dot, "reading..." text)
    readonly property int easeOut:    Easing.OutCubic
    readonly property int easeInOut:  Easing.InOutCubic

    // ---- behaviour ----
    readonly property real brightnessStep: 0.05   // one press of a brightness key (5%)
    readonly property real idleDimLevel:   0.10   // every screen dims to this when idle (hypr/hypridle.conf)
    readonly property int  handwritingPause: 900  // ms without a new pen stroke before the handwriting popup reads the ink
    readonly property int  handwritingInkWidth:  900  // the handwriting strip: ink area (logical px; 6 px per mm on the 152 mm pad)
    readonly property int  handwritingInkHeight: 300
    readonly property int  handwritingGap:       16   // gap between the pen's last position and the strip
    readonly property int  handwritingButton:    40   // pen-tappable buttons are at least 36 px tall

    // ---- the bar ----
    readonly property int barHeight: 28
    // The bar has no background, so its text must stand out from the wallpaper behind it. When the top edge
    // of the wallpaper is light (measured by Wallpaper.qml), the bar switches to dark text, like the macOS menu bar.
    readonly property real lightWallpaper: 105        // top-edge brightness (0-255) above which the bar text turns dark
    readonly property real wallpaperScrim: 0.35       // darkening along the top edge, under light text
    readonly property real wallpaperScrimLight: 0.42  // whitening along the top edge, under dark text (dim text there: ~4.5:1)
    readonly property bool barOnLight: ShellState.topLuminance > lightWallpaper

    // Bar colours: they follow the WALLPAPER, not the colour scheme. Light text on a dark wallpaper is always the dark
    // palette's text colours (even in the light scheme); dark text on a light wallpaper is a set tuned for photos.
    readonly property color barText:   barOnLight ? "#1b1e21" : "#adb0b3"
    readonly property color barDim:    barOnLight ? "#33393e" : "#666a6e"
    readonly property color barBright: barOnLight ? "#000000" : "#d0d3d6"
    readonly property color barAccent: barOnLight ? "#34495c" : "#6c7f91"
    readonly property color barOk:     barOnLight ? "#2b6249" : "#7d9889"
    readonly property color barWarn:   barOnLight ? "#7a5a0b" : "#a8976f"
    readonly property color barErr:    barOnLight ? "#8a2c33" : "#a67a7e"
    readonly property real barOpacity: 0      // 0 = no background, text sits on the wallpaper; 1 = solid strip

    // ---- screens ----
    // The monitor that gets the full bar. Others get workspaces + clock only,
    // unless this one is unplugged.
    readonly property string mainOutput: "HDMI-A-1"
}
