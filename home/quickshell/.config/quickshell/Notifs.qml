pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.Notifications

// The notification centre: receives notifications (this is the D-Bus notification server) and keeps two lists.
//   history  every notification until you dismiss it, newest first (the control center shows it)
//   popups   the ones currently shown on screen (a few seconds each, or until clicked if critical)
// A pop-up going away does not remove the notification from the history. Do Not Disturb (Modes.dnd) keeps
// pop-ups away, except critical ones.
Singleton {
    id: root

    property alias history: historyModel
    property alias popups: popupModel
    readonly property int count: historyModel.count

    readonly property int maxHistory: 50
    readonly property int maxPopups: 4

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
        else historyModel.insert(0, rec)
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
