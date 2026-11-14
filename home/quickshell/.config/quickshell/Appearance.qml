pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// How GTK apps look: colour scheme, GTK / icon / cursor theme, font and sizes. The work is done by the `appearance`
// script (home/bin/.local/bin/appearance), which writes gsettings and the settings.ini files in the dotfiles repo.
// This file only holds the current values and the lists to choose from, for the appearance window (appearance/AppearanceWindow.qml).
Singleton {
    id: root

    readonly property string bin: Quickshell.env("HOME") + "/.local/bin/appearance"

    property string scheme: "default"            // default | prefer-dark | prefer-light
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
        case "color-scheme": scheme = value; break
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

    Component.onCompleted: refresh()
}
