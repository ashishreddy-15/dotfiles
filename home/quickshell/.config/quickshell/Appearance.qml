pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// How the shell and GTK apps look: colour scheme (dark or light), GTK / icon / cursor theme, font and sizes. The work is done by the `appearance`
// script (home/bin/.local/bin/appearance), which writes gsettings and the settings.ini files in the dotfiles repo.
// This file only holds the current values and the lists to choose from, for the appearance window (appearance/AppearanceWindow.qml).
Singleton {
    id: root

    readonly property string bin: Quickshell.env("HOME") + "/.local/bin/appearance"

    property string scheme: "prefer-dark"       // default | prefer-dark | prefer-light (as in gsettings)

    // What the shell itself looks like (Theme.dark). Read from the state file the script writes, synchronously, so
    // the first frame already has the right colours. Everything but "light" and "default" is dark; a missing file is dark.
    readonly property string stateFile: Quickshell.env("HOME") + "/.local/state/dotfiles/scheme"
    property bool dark: true
    FileView {
        id: stateView
        path: root.stateFile
        blockLoading: true
        printErrors: false
    }
    function setShade(value) { dark = (String(value).trim() !== "light" && value !== "prefer-light" && value !== "default") }
    Component.onCompleted: {
        const v = stateView.text().trim()
        setShade(v)
        scheme = dark ? "prefer-dark" : "prefer-light"
    }

    // qs ipc call appearance scheme dark|light     (the script calls this after a change from a terminal)
    // qs ipc call appearance toggle
    IpcHandler {
        target: "appearance"
        function scheme(value: string): void { root.setShade(value); root.scheme = root.dark ? "prefer-dark" : "prefer-light" }
        function toggle(): void { root.set("color-scheme", root.dark ? "prefer-light" : "prefer-dark") }
    }
    property string gtkTheme: ""
    property string iconTheme: ""
    property string cursorTheme: ""
    property int    cursorSize: 24
    property string font: ""
    property int    fontSize: 10

    property var gtkThemes: []
    property var iconThemes: []
    property var cursorThemes: []
    property var fonts: []

    function refresh() { if (!loader.running) loader.running = true }

    // Change one setting. The page updates at once; the script applies it, and changes are applied one at a time.
    property var queue: []
    function set(key, value) {
        value = String(value)
        switch (key) {
        case "color-scheme": scheme = value; setShade(value); break
        case "gtk-theme":    gtkTheme = value; break
        case "icon-theme":   iconTheme = value; break
        case "cursor-theme": cursorTheme = value; break
        case "cursor-size":  cursorSize = Number(value); break
        case "font":         font = value; break
        case "font-size":    fontSize = Number(value); break
        }
        // A newer value for the same key replaces one still waiting.
        queue = queue.filter(q => q[0] !== key).concat([[key, value]])
        next()
    }
    function next() {
        if (setter.running || queue.length === 0) return
        setter.command = [bin, "set", queue[0][0], queue[0][1]]
        queue = queue.slice(1)
        setter.running = true
    }

    Process {
        id: setter
        onExited: root.next()
    }

    Process {
        id: loader
        command: [root.bin, "dump"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const d = JSON.parse(text)
                    root.gtkThemes = d.gtk
                    root.iconThemes = d.icons
                    root.cursorThemes = d.cursors
                    root.fonts = d.fonts
                    const c = d.current
                    root.scheme = c["color-scheme"]
                    root.gtkTheme = c["gtk-theme"]
                    root.iconTheme = c["icon-theme"]
                    root.cursorTheme = c["cursor-theme"]
                    root.cursorSize = Number(c["cursor-size"]) || 24
                    root.font = c["font"]
                    root.fontSize = Number(c["font-size"]) || 10
                } catch (e) { console.log("appearance: could not read settings:", e) }
            }
        }
    }

}
