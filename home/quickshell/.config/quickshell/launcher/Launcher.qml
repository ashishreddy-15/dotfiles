import QtQuick
import Quickshell
import Quickshell.Io
import qs
import "../picker"

// App launcher (Super+Space -> `qs ipc call launcher toggle`). The window, animations and keys
// come from Picker; this file only decides what to show and what to do with the choice.
// The app list, the matching and the starting are in Apps.qml (shared with the app menu, Super + A).
Scope {
    id: root

    IpcHandler {
        target: "launcher"
        function toggle(): void { picker.open = !picker.open }
        // Open with text already typed, e.g. `qs ipc call launcher search fire` (also used for testing).
        function search(text: string): void { picker.setQuery(text) }
    }

    // Nothing is listed until something is typed (Apps.qml does the matching and the starting).
    readonly property var results: {
        if (picker.query.trim() === "") return []
        return Apps.search(picker.query).slice(0, 40).map(a => ({
            title: a.name,
            subtitle: a.genericName !== a.name ? a.genericName : "",
            icon: a.icon,
            app: a
        }))
    }

    Picker {
        id: picker
        namespace: "quickshell-launcher"
        placeholder: "Search apps"
        items: root.results
        onActivated: item => Apps.launch(item.app)
    }
}
