pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Shared on/off switches, controllable from keybinds:
//   qs ipc call bar toggle        (bound to Super+B; also: on, off)
Singleton {
    property bool barVisible: true
    // 0 = hidden, 1 = shown; eases between them so the bar slides and fades instead of popping.
    property real barShown: barVisible ? 1 : 0
    Behavior on barShown { NumberAnimation { duration: barVisible ? Theme.durBase : Theme.durFast; easing.type: Theme.easeOut } }

    // How bright the top edge of the wallpaper is, 0 (black) to 255 (white). Measured by Wallpaper.qml.
    // The bar uses it to switch on a background when the wallpaper is too light for its text.
    property real topLuminance: 0

    // Quick-settings panel (click the clock, or Super+A). It opens on the monitor named here.
    property bool panelOpen: false
    property string panelScreen: ""
    function togglePanel(screenName) { panelScreen = screenName; panelOpen = !panelOpen }

    // Wallpaper: its name for the panel, and a request from the panel to open the picker.
    property string wallpaperName: ""
    signal pickWallpaper()
    // The appearance page asks for the font picker.
    signal pickFont()

    // Where pop-ups (notifications, volume/brightness) appear: the main monitor,
    // or the first one if the main monitor is unplugged.
    readonly property var mainScreen: Quickshell.screens.find(s => s.name === Theme.mainOutput)
                                      ?? Quickshell.screens[0]

    IpcHandler {
        target: "bar"
        function toggle(): void { barVisible = !barVisible }
        function on(): void     { barVisible = true }
        function off(): void    { barVisible = false }
    }
}
