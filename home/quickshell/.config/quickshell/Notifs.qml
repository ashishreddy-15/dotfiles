pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Notifications

// The notification centre: receives notifications (this is the D-Bus notification server) and keeps two lists.
//   history  every notification until you dismiss it, newest first (the control center shows it)
//   popups   the ones currently shown on screen (a few seconds each, or until clicked if critical)
// A pop-up going away does not remove the notification from the history. Do Not Disturb (Modes.dnd) keeps
// pop-ups away, except critical ones.
// Every notification is also written to a log on disk (the archive: Settings > Notifications), kept for
// `archiveDays` days and readable only by you; `archive` holds it, newest first.
Singleton {
    id: root

    property alias history: historyModel
    property alias popups: popupModel
    readonly property int count: historyModel.count

    readonly property int maxHistory: 50
    readonly property int maxPopups: 4

    // ---- the archive: a log on disk, one JSON object per line ----
    readonly property int archiveDays: 7
    readonly property string logFile: Quickshell.env("HOME") + "/.local/state/dotfiles/notifications.jsonl"
    property var archive: []                  // [{ time, app, summary, body, urgency }], newest first
    property bool archiveActive: false        // only loaded while Settings > Notifications is open
    property bool pruned: false

    function openArchive() {
        archiveActive = true
        if (!pruned) { pruned = true; pruner.running = true }
        else logView.reload()
    }
    function closeArchive() {
        archiveActive = false
        archive = []
    }

    FileView {
        id: logView
        path: root.archiveActive ? root.logFile : ""
        watchChanges: root.archiveActive
        printErrors: false
        onFileChanged: if (root.archiveActive) reload()
        onLoaded: if (root.archiveActive) root.readArchive()
        onLoadFailed: root.archive = []
    }
    function readArchive() {
        const list = []
        for (const line of logView.text().split("\n")) {
            if (line.trim() === "") continue
            try { list.push(JSON.parse(line)) } catch (e) { /* a broken line: skip it */ }
        }
        list.sort((a, b) => b.time - a.time)
        archive = list
    }

    // Lines are appended one at a time (a queue, so two arriving together cannot interleave).
    property var pendingLines: []
    function log(entry) {
        pendingLines = pendingLines.concat([JSON.stringify(entry)])
        writeNext()
    }
    function writeNext() {
        if (writer.running || pendingLines.length === 0) return
        writer.command = ["sh", "-c", 'umask 077; mkdir -p "$(dirname "$1")" && printf "%s\\n" "$2" >> "$1"', "sh", logFile, pendingLines[0]]
        pendingLines = pendingLines.slice(1)
        writer.running = true
    }
    Process { id: writer; onExited: root.writeNext() }

    function clearArchive() {
        clearer.running = true
    }
    Process {
        id: clearer
        command: ["sh", "-c", 'umask 077; : > "$1"', "sh", root.logFile]
        onExited: { root.archive = []; if (root.archiveActive) logView.reload() }
    }

    // Drop entries older than archiveDays the first time the archive is opened in a session.
    Process {
        id: pruner
        command: ["python3", "-I", "-c",
            "import json, os, sys, time\n" +
            "path, days = sys.argv[1], float(sys.argv[2])\n" +
            "if not os.path.exists(path): sys.exit()\n" +
            "cutoff = (time.time() - days * 86400) * 1000\n" +
            "keep = []\n" +
            "for line in open(path, encoding='utf-8', errors='replace'):\n" +
            "    try:\n" +
            "        if json.loads(line)['time'] >= cutoff: keep.append(line)\n" +
            "    except Exception: pass\n" +
            "tmp = path + '.tmp'\n" +
            "os.umask(0o077)\n" +
            "open(tmp, 'w', encoding='utf-8').writelines(keep)\n" +
            "os.replace(tmp, path)\n",
            root.logFile, String(root.archiveDays)]
        onExited: if (root.archiveActive) logView.reload()
    }

    // id -> the live Notification object (to dismiss it or invoke an action)
    property var live: ({})

    ListModel { id: historyModel }
    ListModel { id: popupModel }

    NotificationServer {
        id: server

        keepOnReload: true
        bodySupported: true
        bodyMarkupSupported: true
        actionsSupported: true
        imageSupported: true

        onNotification: n => root.add(n)
    }

    // ---- helpers ----
    function indexOfNid(model, nid) {
        for (let i = 0; i < model.count; i++) if (model.get(i).nid === nid) return i
        return -1
    }
    function drop(model, nid) {
        const i = indexOfNid(model, nid)
        if (i >= 0) model.remove(i)
    }

    function record(n) {
        const actions = []
        for (let i = 0; i < n.actions.length; i++) actions.push({ id: n.actions[i].identifier, text: n.actions[i].text })
        return {
            nid: n.id,
            appName: n.appName ?? "",
            summary: n.summary ?? "",
            body: n.body ?? "",
            image: n.image ?? "",
            urgency: n.urgency,                       // 0 low, 1 normal, 2 critical
            time: Date.now(),
            actionsJson: JSON.stringify(actions)
        }
    }

    // ---- a notification arrives ----
    function add(n) {
        n.tracked = true
        live[n.id] = n
        n.closed.connect(() => root.withdrawn(n.id))      // the app took it back

        const rec = record(n)
        const h = indexOfNid(historyModel, n.id)
        if (h >= 0) historyModel.set(h, rec)              // an update of one we already have
        else {
            historyModel.insert(0, rec)
            // The archive keeps plain text: no markup, no images.
            log({ time: rec.time, app: rec.appName, summary: rec.summary.replace(/<[^>]*>/g, ""),
                  body: rec.body.replace(/<[^>]*>/g, ""), urgency: rec.urgency })
        }
        while (historyModel.count > maxHistory) dismiss(historyModel.get(historyModel.count - 1).nid)

        const p = indexOfNid(popupModel, n.id)
        if (p >= 0) popupModel.set(p, rec)                // updated while still on screen
        else if (!Modes.dnd || n.urgency === NotificationUrgency.Critical) {
            popupModel.insert(0, rec)
            while (popupModel.count > maxPopups) popupModel.remove(popupModel.count - 1)
        }
    }

    // ---- things people do ----
    function hidePopup(nid) { drop(popupModel, nid) }          // off the screen, kept in the history

    function dismiss(nid) {                                    // gone for good
        drop(popupModel, nid)
        drop(historyModel, nid)
        const n = live[nid]
        delete live[nid]
        if (n) n.dismiss()
    }

    function clearAll() {
        const ids = []
        for (let i = 0; i < historyModel.count; i++) ids.push(historyModel.get(i).nid)
        for (const id of ids) dismiss(id)
    }

    function invoke(nid, actionId) {
        const n = live[nid]
        if (n) for (let i = 0; i < n.actions.length; i++) if (n.actions[i].identifier === actionId) n.actions[i].invoke()
        dismiss(nid)
    }

    // The app withdrew a notification: it is gone from both lists, and there is nothing to dismiss.
    function withdrawn(nid) {
        drop(popupModel, nid)
        drop(historyModel, nid)
        delete live[nid]
    }

    // Turning Do Not Disturb on clears the pop-ups that are showing (critical ones stay).
    Connections {
        target: Modes
        function onDndChanged() {
            if (!Modes.dnd) return
            for (let i = popupModel.count - 1; i >= 0; i--) if (popupModel.get(i).urgency !== NotificationUrgency.Critical) popupModel.remove(i)
        }
    }
}
