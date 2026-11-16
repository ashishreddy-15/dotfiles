import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
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
        function search(text: string): void { picker.setQuery(text) }   // opens if needed, then sets the query
        function setQuery(text: string): void { if (picker.open) picker.setQuery(text) }   // only if already open
        function activate(): void { if (picker.open) picker.chooseSelected() }   // same as Enter
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

    // Contract with the handwriting popup (see ShellState.qml). The picker window opens on the focused monitor,
    // centred, with its top at 22% of the screen height (see picker/Picker.qml), so the rect is derived here.
    readonly property var searchScreen: Quickshell.screens.find(s => s.name === Hyprland.focusedMonitor?.name) ?? ShellState.mainScreen
    Binding {
        target: ShellState
        property: "launcherSearchRect"
        value: (picker.open && root.searchScreen) ? {
            visible: true, screen: root.searchScreen.name,
            x: Math.round((root.searchScreen.width - picker.cardWidth) / 2),
            y: Math.round(root.searchScreen.height * 0.22),
            w: picker.cardWidth, h: picker.searchHeight
        } : null
    }

    Picker {
        id: picker
        namespace: "quickshell-launcher"
        placeholder: "Search apps"
        keepOpen: ShellState.launcherKeepOpen
        items: root.results
        onActivated: item => Apps.launch(item.app)
    }
}
