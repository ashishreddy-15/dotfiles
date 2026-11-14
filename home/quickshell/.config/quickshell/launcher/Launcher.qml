import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Widgets
import qs

// Spotlight-style app launcher (Super+Space -> `qs ipc call launcher toggle`).
// Type to search installed apps; Up/Down or Tab to move, Enter to open, Esc or click outside to close.
// Apps start through `uwsm app` so each runs in its own systemd scope.
//
// Animation notes (why it is built this way):
//  - The window is a fixed size and never resized. Only the card inside it grows and shrinks.
//    Resizing a layer-shell window per keystroke makes the compositor stretch and smear the old frame.
//  - Hyprland's own fade is switched off for this window (hypr/modules/rules.lua); the open/close
//    fade and the height change are animated here, inside the window.
Scope {
    id: root

    property bool open: false
    property string query: ""
    property int selected: 0
    readonly property int maxResults: 8

    readonly property int searchHeight: 54
    readonly property int rowHeight: 40
    readonly property int listPadding: 6

    IpcHandler {
        target: "launcher"
        function toggle(): void { root.open = !root.open }
        // Open with text already typed, e.g. `qs ipc call launcher search fire` (also used for testing).
        function search(text: string): void { root.open = true; input.text = text }
    }

    onOpenChanged: if (open) { query = ""; selected = 0 }

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

    readonly property var results: {
        const q = query.trim().toLowerCase()
        if (q === "") return []
        return apps
            .map(a => ({ app: a, s: score(a, q) }))
            .filter(r => r.s > 0)
            .sort((x, y) => y.s - x.s || x.app.name.length - y.app.name.length)
            .slice(0, maxResults)
            .map(r => r.app)
    }

    function launch(app) {
        if (!app) return
        open = false
        const cmd = Array.from(app.command)
        const full = app.runInTerminal ? ["kitty", "-e", ...cmd] : cmd
        Quickshell.execDetached(["uwsm", "app", "--", ...full])
    }

    // ---- window ----
    PanelWindow {
        id: win

        // Open on the monitor you're working on.
        screen: Quickshell.screens.find(s => s.name === Hyprland.focusedMonitor?.name) ?? ShellState.mainScreen

        // Stay mapped until the close animation has finished.
        visible: root.open || card.shown > 0

        anchors.top: true                            // top only = horizontally centred
        margins.top: Math.round((screen?.height ?? 1080) * 0.22)
        exclusionMode: ExclusionMode.Ignore
        implicitWidth: 600
        // Always tall enough for the longest list, so the window itself never changes size.
        implicitHeight: root.searchHeight + 1 + 2 * root.listPadding + root.maxResults * root.rowHeight
        color: "transparent"
        mask: Region { item: card }                  // only the card takes clicks; the rest is see-through
        WlrLayershell.namespace: "quickshell-launcher"
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: root.open ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

        // Close when clicking anywhere else.
        HyprlandFocusGrab {
            active: root.open
            windows: [win]
            onCleared: root.open = false
        }

        Rectangle {
            id: card

            // 0 = hidden, 1 = fully shown. Drives the fade, the slight zoom and the slide.
            property real shown: root.open ? 1 : 0
            Behavior on shown { NumberAnimation { duration: root.open ? 140 : 90; easing.type: Easing.OutCubic } }

            width: parent.width
            height: column.implicitHeight
            Behavior on height { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }

            opacity: shown
            scale: 0.97 + 0.03 * shown
            transformOrigin: Item.Top
            y: (1 - shown) * -8

            clip: true                               // list rows are revealed as the card grows
            radius: Theme.radius + 4
            color: Theme.surface
            border.width: 1
            border.color: Theme.border

            Column {
                id: column
                width: parent.width

                // Search field
                Item {
                    width: parent.width
                    height: root.searchHeight

                    TextInput {
                        id: input
                        anchors { left: parent.left; right: parent.right; verticalCenter: parent.verticalCenter; leftMargin: 20; rightMargin: 20 }
                        text: root.query
                        onTextChanged: { root.query = text; root.selected = 0 }
                        color: Theme.bright
                        selectionColor: Theme.border
                        font.family: Theme.uiFont
                        font.variableAxes: ({ "wdth": Theme.uiWidth })
                        font.pixelSize: 18
                        clip: true
                        focus: true

                        Connections {
                            target: root
                            function onOpenChanged() { if (root.open) { input.text = ""; input.forceActiveFocus() } }
                        }

                        Keys.onPressed: event => {
                            const n = root.results.length
                            if (event.key === Qt.Key_Escape) {
                                root.open = false
                            } else if (event.key === Qt.Key_Down || (event.key === Qt.Key_Tab && n)) {
                                root.selected = (root.selected + 1) % Math.max(n, 1)
                            } else if (event.key === Qt.Key_Up || event.key === Qt.Key_Backtab) {
                                root.selected = (root.selected - 1 + Math.max(n, 1)) % Math.max(n, 1)
                            } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                                root.launch(root.results[root.selected])
                            } else {
                                return
                            }
                            event.accepted = true
                        }

                        StyledText {
                            mono: false
                            visible: input.text === ""
                            text: "Search apps"
                            color: Theme.dim
                            font.pixelSize: 18
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }
                }

                // Results
                Rectangle {
                    visible: root.results.length > 0
                    width: parent.width
                    height: 1
                    color: Theme.border
                }

                Column {
                    visible: root.results.length > 0
                    width: parent.width
                    topPadding: root.listPadding
                    bottomPadding: root.listPadding

                    Repeater {
                        model: root.results

                        Rectangle {
                            id: row
                            required property var modelData
                            required property int index
                            readonly property bool active: index === root.selected

                            x: root.listPadding
                            width: parent.width - 2 * root.listPadding
                            height: root.rowHeight
                            radius: Theme.radius
                            color: active ? Theme.raised : "transparent"

                            Row {
                                anchors { left: parent.left; leftMargin: 14; verticalCenter: parent.verticalCenter }
                                spacing: 12

                                IconImage {
                                    implicitSize: 22
                                    source: Quickshell.iconPath(row.modelData.icon, "application-x-executable")
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                                StyledText {
                                    mono: false
                                    text: row.modelData.name
                                    color: row.active ? Theme.bright : Theme.text
                                    font.pixelSize: 15
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                                StyledText {
                                    mono: false
                                    visible: text !== "" && text !== row.modelData.name
                                    text: row.modelData.genericName
                                    color: Theme.dim
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                            }

                            // Only a real mouse move changes the highlight. (A list that re-lays out under a
                            // resting pointer must not steal the keyboard selection.)
                            MouseArea {
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onPositionChanged: root.selected = row.index
                                onClicked: root.launch(row.modelData)
                            }
                        }
                    }
                }
            }
        }
    }
}
