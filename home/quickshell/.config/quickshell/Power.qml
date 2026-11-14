pragma Singleton

import QtQuick
import Quickshell

// The session and power actions, in one place for the control center's footer (panel/PowerSection.qml) and the power
// menu (power/PowerMenu.qml, Super + X). The ones that end your session (`ask`) want a second press to confirm.
Singleton {
    readonly property var actions: [
        { name: "lock",     label: "Lock",      key: Qt.Key_L, glyph: Theme.glyphLock,    ask: false, command: ["loginctl", "lock-session"] },
        { name: "logout",   label: "Log out",   key: Qt.Key_O, glyph: Theme.glyphLogout,  ask: true,  command: ["uwsm", "stop"] },
        { name: "suspend",  label: "Suspend",   key: Qt.Key_S, glyph: Theme.glyphSuspend, ask: false, command: ["systemctl", "suspend"] },
        { name: "reboot",   label: "Reboot",    key: Qt.Key_R, glyph: Theme.glyphReboot,  ask: true,  command: ["systemctl", "reboot"] },
        { name: "shutdown", label: "Shut down", key: Qt.Key_P, glyph: Theme.glyphPower,   ask: true,  command: ["systemctl", "poweroff"] }
    ]

    function run(action) { Quickshell.execDetached(action.command) }
}
