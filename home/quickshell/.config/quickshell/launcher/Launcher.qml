import QtQuick
import Quickshell
import Quickshell.Io
import qs
import "../picker"

// App launcher (Super+Space -> `qs ipc call launcher toggle`). The window, animations and keys
// come from Picker; this file only decides what to show and what to do with the choice.
// Apps start through `uwsm app` so each runs in its own systemd scope.
Scope {
    id: root

    IpcHandler {
        target: "launcher"
        function toggle(): void { picker.open = !picker.open }
        // Open with text already typed, e.g. `qs ipc call launcher search fire` (also used for testing).
        function search(text: string): void { picker.setQuery(text) }
    }

    // ---- search ----
    readonly property var apps: DesktopEntries.applications.values.filter(a => !a.noDisplay)

    function score(app, q) {
        const name = app.name.toLowerCase()
        if (name === q) return 100
        if (name.startsWith(q)) return 80
        if (name.split(/[\s\-_.]+/).some(w => w.startsWith(q))) return 60
        if (name.includes(q)) return 40
        const extra = (app.genericName + " " + app.keywords + " " + app.comment).toLowerCase()
        if (extra.includes(q)) return 20
        // letters in order, e.g. "ntl" -> "NauTiLus"
        let i = 0
        for (const ch of name) if (ch === q[i]) i++
        return i === q.length ? 10 : 0
    }

    // Nothing is listed until something is typed.
    readonly property var results: {
        const q = picker.query.trim().toLowerCase()
        if (q === "") return []
        return apps
            .map(a => ({ app: a, s: score(a, q) }))
            .filter(r => r.s > 0)
            .sort((x, y) => y.s - x.s || x.app.name.length - y.app.name.length)
            .slice(0, 40)
            .map(r => ({
                title: r.app.name,
                subtitle: r.app.genericName !== r.app.name ? r.app.genericName : "",
                icon: r.app.icon,
                app: r.app
            }))
    }

    function launch(app) {
        const cmd = Array.from(app.command)
        const full = app.runInTerminal ? ["kitty", "-e", ...cmd] : cmd
        Quickshell.execDetached(["uwsm", "app", "--", ...full])
    }

    Picker {
        id: picker
        namespace: "quickshell-launcher"
        placeholder: "Search apps"
        items: root.results
        onActivated: item => root.launch(item.app)
    }
}
