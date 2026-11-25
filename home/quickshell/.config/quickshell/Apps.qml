pragma Singleton

import QtQuick
import Quickshell

// The installed apps (their .desktop entries, minus hidden ones), how well one matches a search, and how to start one.
// Used by the launcher (Super + Space) and the app menu (Super + A).
Singleton {
    id: root

    readonly property var list: DesktopEntries.applications.values
        .filter(a => !a.noDisplay)
        .sort((a, b) => a.name.localeCompare(b.name))

    // How well `app` matches the typed text `q` (lower case): 0 = not at all, higher = better.
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

    // The apps matching `query`, best first; all of them, A to Z, when it is empty.
    function search(query) {
        const q = query.trim().toLowerCase()
        if (q === "") return list
        return list
            .map(a => ({ app: a, s: score(a, q) }))
            .filter(r => r.s > 0)
            .sort((x, y) => y.s - x.s || x.app.name.length - y.app.name.length)
            .map(r => r.app)
    }

    // Apps start through `uwsm app`, so each runs in its own systemd scope; terminal apps open in kitty.
    function launch(app) {
        const cmd = Array.from(app.command)
        const full = app.runInTerminal ? ["kitty", "--single-instance", "-e", ...cmd] : cmd
        Quickshell.execDetached(["uwsm", "app", "--", ...full])
    }
}
