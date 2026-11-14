import QtQuick
import Quickshell
import Quickshell.Io
import qs
import "../picker"

// Clipboard history (Super+V -> `qs ipc call clipboard toggle`).
// History comes from cliphist, which hypr/modules/autostart.lua feeds with `wl-paste --watch`.
// Shows the most recent entries; typing filters the whole history. Enter copies the entry back to the
// clipboard, then paste it with Ctrl+V as usual.
Scope {
    id: root

    property var entries: []        // newest first: [{ line, text }]

    IpcHandler {
        target: "clipboard"
        function toggle(): void { picker.open = !picker.open }
        function search(text: string): void { picker.setQuery(text) }
        // Same as pressing Enter on the highlighted entry (used for testing).
        function pick(): void { picker.chooseSelected() }
    }

    // `cliphist list` prints one line per entry: "<id><TAB><text>". Images show as "[[ binary data ... ]]".
    Process {
        id: loader
        command: ["cliphist", "list"]
        stdout: StdioCollector {
            onStreamFinished: root.entries = text.split("\n").filter(l => l !== "").map(l => ({
                line: l,
                text: l.slice(l.indexOf("\t") + 1).replace(/\s+/g, " ").trim()
            }))
        }
    }

    readonly property var shown: {
        const q = picker.query.trim().toLowerCase()
        const list = q === "" ? entries : entries.filter(e => e.text.toLowerCase().includes(q))
        return list.slice(0, picker.maxResults).map(e => ({ title: e.text || "(blank)", entry: e }))
    }

    Picker {
        id: picker
        namespace: "quickshell-clipboard"
        placeholder: "Search clipboard history"
        items: root.shown
        onOpenChanged: if (open && !loader.running) loader.running = true
        // cliphist wants the original list line back; it only uses the id in front of the tab.
        onActivated: item => Quickshell.execDetached(
            ["sh", "-c", 'printf "%s\\n" "$1" | cliphist decode | wl-copy', "sh", item.entry.line])
    }
}
