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


    // Settings window (Super + I): open or not, and the section it shows (see settings/SettingsWindow.qml).
    property bool settingsOpen: false
    property string settingsSection: "wifi"
    function openSettings(section) { if (section) settingsSection = section; settingsOpen = true }
    function toggleSettings(section) {
        if (settingsOpen && (!section || section === settingsSection)) settingsOpen = false
        else openSettings(section)
    }

    // Wallpaper: the images found and the one in use, for Settings; wallpaper/Wallpaper.qml fills these in and
    // obeys wallpaperChosen.
    property var wallpaperFiles: []
    property string wallpaperCurrent: ""
    signal wallpaperChosen(string path)

    // Screen recording (home/bin/.local/bin/screenrecord): whether one is running and since when (seconds since 1970).
    // The script reports start and stop through IPC; when the shell starts it asks, in case one is already running.
    property bool recording: false
    property real recordingSince: 0
    readonly property string screenrecord: Quickshell.env("HOME") + "/.local/bin/screenrecord"
    function stopRecording() { Quickshell.execDetached([screenrecord, "stop"]) }

    IpcHandler {
        target: "recording"
        function started(since: string): void { recordingSince = Number(since) || Date.now() / 1000; recording = true }
        function stopped(): void { recording = false }
    }
    Process {
        running: true
        command: [screenrecord, "status"]
        stdout: StdioCollector {
            onStreamFinished: {
                const m = text.match(/^recording (\d+)/)
                if (m) { recordingSince = Number(m[1]); recording = true }
            }
        }
    }

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
