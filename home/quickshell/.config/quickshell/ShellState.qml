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
    // Small copies of the images, made once and kept in a cache folder, so Settings does not decode the full photos each
    // time it opens. wallpaperThumbsReady turns true when they exist; the file for an image is <dir>/<md5 of its path>.jpg.
    property string wallpaperThumbDir: ""
    property bool wallpaperThumbsReady: false
    signal wallpaperChosen(string path)
    // Folders searched for images, besides the built-in ones (Wallpaper.qml keeps and saves the list).
    property var wallpaperBuiltinFolders: []
    property var wallpaperFolders: []
    signal wallpaperAddFolder()                    // asks with a folder dialog
    signal wallpaperRemoveFolder(string path)

    // Notification centre (notifications/NotificationCenter.qml): the bell in the bar and Super + N toggle it.
    property bool centerOpen: false

    // The control center's power button asks the power menu (power/PowerMenu.qml) to open.
    signal openPowerMenu()

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

    // --- Launcher / handwriting contract -------------------------------------------------------------
    // launcherSearchRect: null while the launcher is hidden, else {visible, screen (monitor name), x, y, w, h}:
    // the search field in that monitor's logical pixels. Written by launcher/Launcher.qml.
    property var launcherSearchRect: null
    // Set true (by the handwriting popup while docked under the search field) so the launcher ignores outside clicks.
    property bool launcherKeepOpen: false
    // --- end launcher / handwriting contract ---------------------------------------------------------

    IpcHandler {
        target: "bar"
        function toggle(): void { barVisible = !barVisible }
        function on(): void     { barVisible = true }
        function off(): void    { barVisible = false }
    }
}
