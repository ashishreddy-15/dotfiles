pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Shared on/off switches, controllable from keybinds:
//   qs ipc call bar toggle        (bound to Super+B; also: on, off)
Singleton {
    property bool barVisible: true

    // How bright the top edge of the wallpaper is, 0 (black) to 255 (white). Measured by Wallpaper.qml.
    // The bar uses it to switch on a background when the wallpaper is too light for its text.
    property real topLuminance: 0

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
