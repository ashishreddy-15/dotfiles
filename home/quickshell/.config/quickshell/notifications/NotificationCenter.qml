import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
import qs
import "../ui"
import "../settings"

// The notification centre: the notifications you have not dealt with yet (Notifs.history), on a full-height panel at
// the right edge, under the bar. Grouped by app, newest first; an app with several shows its newest and "n more".
// Each card: title, time, text, the app's action buttons, and x to dismiss. The header has Silence and "Clear all".
// Older ones, dismissed ones too, are in the archive: Settings > Notifications.
//   Super + N or the bell in the bar opens it (qs ipc call notifications toggle); Esc or a click outside closes it.
// Opening it clears the pop-ups on screen: they are all here.
Scope {
    id: root

    readonly property int panelWidth: 380
    property var expanded: ({})                  // app name -> true when all of its notifications are shown

    IpcHandler {
        target: "notifications"
        function toggle(): void { ShellState.centerOpen = !ShellState.centerOpen }
        function open(): void { ShellState.centerOpen = true }
        function close(): void { ShellState.centerOpen = false }
    }

    Connections {
        target: ShellState
        function onCenterOpenChanged() {
            if (!ShellState.centerOpen) return
            for (let i = Notifs.popups.count - 1; i >= 0; i--) Notifs.hidePopup(Notifs.popups.get(i).nid)
            root.expanded = ({})
            card.forceActiveFocus()
        }
    }

    // Notifs.history grouped by app, the app with the newest notification first: [{ app, items: [record...] }]
    readonly property var groups: {
        const order = [], byApp = {}
        for (let i = 0; i < Notifs.history.count; i++) {
            const r = Notifs.history.get(i)
            const app = r.appName || "Notification"
            if (!byApp[app]) { byApp[app] = []; order.push(app) }
            byApp[app].push({ nid: r.nid, summary: r.summary, body: r.body, time: r.time, urgency: r.urgency, actionsJson: r.actionsJson })
        }
        return order.map(app => ({ app: app, items: byApp[app] }))
    }

    function ago(ms) {
        const m = Math.floor((Date.now() - ms) / 60000)
        if (m < 1) return "now"
        if (m < 60) return m + "m"
        const h = Math.floor(m / 60)
        return h < 24 ? h + "h" : Math.floor(h / 24) + "d"
    }

    PanelWindow {
        id: win

        // On the monitor you are working on.
        screen: Quickshell.screens.find(s => s.name === Hyprland.focusedMonitor?.name) ?? ShellState.mainScreen
        visible: ShellState.centerOpen || card.shown > 0

        readonly property int wantedTop: Theme.barHeight + 4
        readonly property int wantedRight: 8
        anchors { top: true; right: true; bottom: true }
        margins.top: Math.max(0, wantedTop - Theme.shadowMargin)
        margins.right: Math.max(0, wantedRight - Theme.shadowMargin)
        exclusionMode: ExclusionMode.Ignore
        implicitWidth: root.panelWidth + 2 * Theme.shadowMargin
        color: "transparent"
        mask: Region { item: card }
        WlrLayershell.namespace: "quickshell-center"
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: ShellState.centerOpen ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

        HyprlandFocusGrab {
            active: ShellState.centerOpen
            windows: [win]
            onCleared: ShellState.centerOpen = false
        }

        Card {
            id: card
            x: win.width - root.panelWidth - (win.wantedRight - win.margins.right)
            y: win.wantedTop - win.margins.top
            width: root.panelWidth
            open: ShellState.centerOpen
            origin: Item.TopRight
            contentHeight: win.height - y - 8

            focus: true
            Keys.onPressed: event => {
                if (event.key === Qt.Key_Escape) ShellState.centerOpen = false
                else if (event.key === Qt.Key_Down || event.key === Qt.Key_Tab) { const n = (card.Window.activeFocusItem ?? card).nextItemInFocusChain(true); if (n) n.forceActiveFocus() }
                else if (event.key === Qt.Key_Up || event.key === Qt.Key_Backtab) { const n = (card.Window.activeFocusItem ?? card).nextItemInFocusChain(false); if (n) n.forceActiveFocus() }
                else return
                event.accepted = true
            }

            // ---- header ----
            Item {
                id: header
                anchors { left: parent.left; right: parent.right; top: parent.top; margins: 16 }
                height: 34

                StyledText {
                    anchors { left: parent.left; verticalCenter: parent.verticalCenter }
                    text: "Notifications"
                    color: Theme.bright
                    font.pixelSize: Theme.fontLarge
                }
                Row {
                    anchors { right: parent.right; verticalCenter: parent.verticalCenter }
                    spacing: 12

                    StyledText { anchors.verticalCenter: parent.verticalCenter; text: Theme.glyphSilent; color: Modes.dnd ? Theme.bright : Theme.dim }
                    Switch { anchors.verticalCenter: parent.verticalCenter; checked: Modes.dnd; onToggled: Modes.toggleDnd() }

                    Rectangle {
                        id: clearAll
                        visible: Notifs.count > 0
                        anchors.verticalCenter: parent.verticalCenter
                        width: clearText.implicitWidth + 20
                        height: 28
                        radius: Theme.radiusRow
                        color: clearArea.containsMouse ? Theme.hover : Theme.clear
                        border.width: 1
                        border.color: Theme.border
                        Behavior on color { ColorAnimation { duration: Theme.durFast } }
                        activeFocusOnTab: true
                        Keys.onPressed: event => {
                            if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter || event.key === Qt.Key_Space) { Notifs.clearAll(); event.accepted = true }
                        }
                        StyledText { id: clearText; anchors.centerIn: parent; text: "Clear all"; font.pixelSize: Theme.fontSmall }
                        MouseArea { id: clearArea; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: Notifs.clearAll() }
                        FocusRing { visible: clearAll.activeFocus; anchors.margins: -3 }
                    }
                }
            }

            // ---- nothing new ----
            Column {
                visible: Notifs.count === 0
                anchors.centerIn: parent
                spacing: 10
                StyledText { anchors.horizontalCenter: parent.horizontalCenter; text: Theme.glyphBell; color: Theme.dim; font.pixelSize: Theme.fontIcon }
                StyledText { anchors.horizontalCenter: parent.horizontalCenter; text: "No new notifications"; color: Theme.dim }
                StyledText { anchors.horizontalCenter: parent.horizontalCenter; text: "Older ones: Settings > Notifications"; color: Theme.dim; font.pixelSize: Theme.fontSmall }
            }

            // ---- the groups ----
            Flickable {
                anchors { left: parent.left; right: parent.right; top: header.bottom; bottom: parent.bottom; leftMargin: 12; rightMargin: 12; topMargin: 10; bottomMargin: 12 }
                contentHeight: list.implicitHeight
                clip: true
                boundsBehavior: Flickable.StopAtBounds
                interactive: contentHeight > height

                Column {
                    id: list
                    width: parent.width
                    spacing: 14

                    Repeater {
                        model: root.groups

                        Column {
                            id: group
                            required property var modelData
                            readonly property bool open: root.expanded[modelData.app] === true
                            readonly property var shownItems: open ? modelData.items : modelData.items.slice(0, 1)
                            width: list.width
                            spacing: 6

                            // App name, and "n more" to show the rest
                            Item {
                                width: parent.width
                                height: 22
                                StyledText {
                                    anchors { left: parent.left; leftMargin: 4; verticalCenter: parent.verticalCenter }
                                    text: group.modelData.app
                                    color: Theme.dim
                                    font.pixelSize: Theme.fontSmall
                                }
                                StyledText {
                                    id: more
                                    visible: group.modelData.items.length > 1
                                    anchors { right: parent.right; rightMargin: 4; verticalCenter: parent.verticalCenter }
                                    text: group.open ? "show less  " + Theme.glyphUp : (group.modelData.items.length - 1) + " more  " + Theme.glyphDown
                                    color: moreArea.containsMouse ? Theme.text : Theme.dim
                                    font.pixelSize: Theme.fontSmall
                                    MouseArea {
                                        id: moreArea
                                        anchors { fill: parent; margins: -4 }
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            const e = Object.assign({}, root.expanded)
                                            e[group.modelData.app] = !group.open
                                            root.expanded = e
                                        }
                                    }
                                }
                            }

                            Repeater {
                                model: group.shownItems

                                // One notification
                                Rectangle {
                                    id: note
                                    required property var modelData
                                    readonly property var actions: JSON.parse(modelData.actionsJson || "[]")
                                    width: group.width
                                    height: body.implicitHeight + 24
                                    radius: Theme.radiusCard
                                    color: noteHover.hovered ? Theme.selected : Theme.hover
                                    border.width: modelData.urgency === 2 ? 1 : 0
                                    border.color: Theme.err
                                    Behavior on color { ColorAnimation { duration: Theme.durFast } }
                                    HoverHandler { id: noteHover }

                                    // Keyboard: Delete or Backspace dismisses it; Enter runs its first action.
                                    activeFocusOnTab: true
                                    Keys.onPressed: event => {
                                        if (event.key === Qt.Key_Delete || event.key === Qt.Key_Backspace) Notifs.dismiss(note.modelData.nid)
                                        else if ((event.key === Qt.Key_Return || event.key === Qt.Key_Enter) && note.actions.length > 0) Notifs.invoke(note.modelData.nid, note.actions[0].id)
                                        else return
                                        event.accepted = true
                                    }
                                    FocusRing { visible: note.activeFocus; radius: note.radius }

                                    Column {
                                        id: body
                                        x: 14
                                        y: 12
                                        width: parent.width - 28
                                        spacing: 4

                                        Item {
                                            width: parent.width
                                            height: title.implicitHeight
                                            StyledText {
                                                id: title
                                                anchors { left: parent.left; right: when.left; rightMargin: 8 }
                                                text: note.modelData.summary
                                                color: Theme.bright
                                                elide: Text.ElideRight
                                            }
                                            StyledText {
                                                id: when
                                                anchors { right: closeX.left; rightMargin: 10; verticalCenter: title.verticalCenter }
                                                text: root.ago(note.modelData.time)
                                                color: Theme.dim
                                                font.pixelSize: Theme.fontSmall
                                            }
                                            StyledText {
                                                id: closeX
                                                anchors { right: parent.right; verticalCenter: title.verticalCenter }
                                                text: Theme.glyphClose
                                                color: closeArea.containsMouse ? Theme.bright : Theme.dim
                                                MouseArea {
                                                    id: closeArea
                                                    anchors { fill: parent; margins: -6 }
                                                    hoverEnabled: true
                                                    cursorShape: Qt.PointingHandCursor
                                                    onClicked: Notifs.dismiss(note.modelData.nid)
                                                }
                                            }
                                        }
                                        StyledText {
                                            width: parent.width
                                            visible: text !== ""
                                            text: note.modelData.body
                                            textFormat: Text.PlainText
                                            wrapMode: Text.Wrap
                                            maximumLineCount: 3
                                            elide: Text.ElideRight
                                            color: Theme.text
                                        }
                                        // The app's buttons
                                        Flow {
                                            visible: note.actions.length > 0
                                            width: parent.width
                                            spacing: 6
                                            topPadding: 4
                                            Repeater {
                                                model: note.actions
                                                Rectangle {
                                                    id: actionButton
                                                    required property var modelData
                                                    width: actionText.implicitWidth + 20
                                                    height: 26
                                                    radius: Theme.radiusRow
                                                    color: actionArea.containsMouse ? Theme.hover : Theme.clear
                                                    border.width: 1
                                                    border.color: Theme.border
                                                    StyledText { id: actionText; anchors.centerIn: parent; text: actionButton.modelData.text; font.pixelSize: Theme.fontSmall }
                                                    MouseArea { id: actionArea; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: Notifs.invoke(note.modelData.nid, actionButton.modelData.id) }
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
