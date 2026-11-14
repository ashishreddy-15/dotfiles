pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland

// The touchpad: your choices (Settings > Touchpad), kept in ~/.local/state/dotfiles/touchpad.json and applied to
// Hyprland live with `hyprctl eval` (again after every config reload). hypr/modules/input.lua is the baseline.
//   tapToClick, naturalScroll, disableWhileTyping, tapAndDrag   on / off
//   twoFingerRightClick   on: two fingers click = right click; off: the bottom-right corner is the right button
//   speed                 -1 .. 1, the touchpad's pointer speed only (0 = normal)
//   scroll                0.25 .. 2, how far a scroll moves (1 = normal)
Singleton {
    id: root

    property bool tapToClick: true
    property bool naturalScroll: false
    property bool disableWhileTyping: true
    property bool tapAndDrag: true
    property bool twoFingerRightClick: false      // Hyprland's own default: the corner
    property real speed: 0
    property real scroll: 1

    property var devices: []                 // Hyprland's names for the touchpads
    readonly property bool present: devices.length > 0

    readonly property string stateFile: Quickshell.env("HOME") + "/.local/state/dotfiles/touchpad.json"
    readonly property var keys: ["tapToClick", "naturalScroll", "disableWhileTyping", "tapAndDrag", "twoFingerRightClick", "speed", "scroll"]

    FileView { id: saved; path: root.stateFile; blockLoading: true; printErrors: false }
    Process {
        id: writer
        property string json
        command: ["sh", "-c", 'mkdir -p "$(dirname "$1")" && printf "%s" "$2" > "$1"', "sh", root.stateFile, json]
    }
    function set(key, value) {
        root[key] = value
        const d = {}
        for (const k of keys) d[k] = root[k]
        writer.json = JSON.stringify(d)
        writer.running = true
        apply()
    }

    Process {
        id: lister
        command: ["hyprctl", "devices", "-j"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    root.devices = JSON.parse(text).mice.map(m => m.name).filter(n => n.endsWith("-touchpad"))
                    root.apply()
                } catch (e) { root.devices = [] }
            }
        }
    }

    function apply() {
        const b = v => v ? "true" : "false"
        let lua = 'hl.config({ input = { touchpad = { tap_to_click = ' + b(tapToClick) + ', natural_scroll = ' + b(naturalScroll) +
            ', disable_while_typing = ' + b(disableWhileTyping) + ', tap_and_drag = ' + b(tapAndDrag) +
            ', clickfinger_behavior = ' + b(twoFingerRightClick) + ', scroll_factor = ' + scroll.toFixed(2) + ' } } })'
        for (const n of devices) lua += '; hl.device({ name = "' + n + '", sensitivity = ' + speed.toFixed(2) + ' })'
        lastApplied = lua
        applier.command = ["hyprctl", "eval", lua]
        applier.running = true
    }
    Process { id: applier }

    // What was applied last, to check: `qs ipc call touchpad status`.
    property string lastApplied: ""
    IpcHandler {
        target: "touchpad"
        function status(): string { return root.lastApplied }
    }

    Connections {
        target: Hyprland
        function onRawEvent(event) { if (event.name === "configreloaded") root.apply() }
    }

    Component.onCompleted: {
        try {
            const d = JSON.parse(saved.text())
            for (const k of keys) if (d[k] !== undefined) root[k] = d[k]
        } catch (e) { /* first run: the defaults */ }
        lister.running = true
    }
}
