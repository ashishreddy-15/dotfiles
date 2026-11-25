// Entry point. Each piece of the desktop lives in its own folder and is listed here.
// Quickshell reloads automatically when any of these files is saved.
// Logs: journalctl --user -u quickshell -f

import Quickshell
import "bar"
import "notifications"
import "osd"
import "launcher"
import "clipboard"
import "wallpaper"
import "panel"
import "settings"
import "bluetooth"
import "power"
import "apps"
import "handwriting"

ShellRoot {
    // Singletons start the first time something uses them. These have work to do from the start (applying the tablet
    // settings), so touch them here.
    readonly property bool tabletReady: Tablet.present
    readonly property bool touchpadReady: Touchpad.present
    readonly property bool handwritingReady: Handwriting.active

    Bar {}
    Notifications {}
    NotificationCenter {}
    Osd {}
    Launcher {}
    Clipboard {}
    Wallpaper {}
    QuickPanel {}
    SettingsWindow {}
    PairingPrompt {}
    PowerMenu {}
    AppMenu {}
    HandwritingPopup {}
}
