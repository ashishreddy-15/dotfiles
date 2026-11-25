import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Widgets
import qs
import "../ui"

// The app menu (Super + A): every app as an icon with its name, A to Z, in a grid under a search field.
// Typing filters (best match first). Arrows move, Enter or a click starts the app, Esc or a click outside closes.
// The app list, the matching and the starting are in Apps.qml (shared with the launcher, Super + Space).
Scope {
    id: root

    property bool open: false
    property bool mounted: false
    onOpenChanged: if (open) mounted = true; else if (!loader.item || !loader.item.alive) mounted = false

    readonly property int columns: 6
    readonly property int cellWidth: 112
    readonly property int cellHeight: 108
    readonly property int visibleRows: 4
    readonly property int pad: 16
    readonly property int searchHeight: 44
    readonly property int cardWidth: columns * cellWidth + 2 * pad
    readonly property int cardHeight: searchHeight + visibleRows * cellHeight + 3 * pad        // the most it gets

    IpcHandler {
        target: "apps"
        function toggle(): void { root.open = !root.open }
        function open(): void { root.open = true }
        function close(): void { root.open = false }
    }

    function start(app) {
        if (!app) return
        open = false
        Apps.launch(app)
    }

    LazyLoader {
        id: loader
        active: root.open || root.mounted

        PanelWindow {
            id: win

            property bool ready: false
            readonly property bool alive: card.shown > 0
            readonly property var shown: Apps.search(search.text)
            // As many rows as there are apps to show (at least one, for "no match"; at most visibleRows, then it scrolls).
            readonly property int rows: Math.max(1, Math.min(root.visibleRows, Math.ceil(shown.length / root.columns)))

            onAliveChanged: if (!alive && !root.open) Qt.callLater(() => { if (!root.open && (!loader.item || !loader.item.alive)) root.mounted = false })

            Component.onCompleted: Qt.callLater(() => { ready = true; search.forceActiveFocus() })
            Connections {
                target: root
                function onOpenChanged() {
                    if (root.open) { search.text = ""; grid.currentIndex = 0; Qt.callLater(() => search.forceActiveFocus()) }
                }
            }

            screen: Quickshell.screens.find(s => s.name === Hyprland.focusedMonitor?.name) ?? ShellState.mainScreen
            visible: root.open || card.shown > 0

            // No anchors: centred.
            exclusionMode: ExclusionMode.Ignore
            implicitWidth: root.cardWidth + 2 * Theme.shadowMargin
            implicitHeight: root.cardHeight + 2 * Theme.shadowMargin
            color: "transparent"
            mask: Region { item: card }
            WlrLayershell.namespace: "quickshell-apps"
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: root.open ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

            HyprlandFocusGrab {
                active: root.open
                windows: [win]
                onCleared: root.open = false
            }

            Card {
                id: card
                x: Theme.shadowMargin
                y: Theme.shadowMargin
                width: root.cardWidth
                open: root.open && win.ready
                contentHeight: root.searchHeight + win.rows * root.cellHeight + 3 * root.pad

                // ---- search ----
                Rectangle {
                    id: field
                    x: root.pad
                    y: root.pad
                    width: parent.width - 2 * root.pad
                    height: root.searchHeight
                    radius: Theme.radiusRow
                    color: Theme.hover
                    border.width: 1
                    border.color: search.activeFocus ? Theme.border : Theme.clear

                    StyledText {
                        id: lens
                        anchors { left: parent.left; leftMargin: 14; verticalCenter: parent.verticalCenter }
                        text: Theme.glyphSearch
                        color: Theme.dim
                    }
                    TextInput {
                        id: search
                        anchors { left: lens.right; leftMargin: 12; right: parent.right; rightMargin: 14; verticalCenter: parent.verticalCenter }
                        color: Theme.bright
                        selectionColor: Theme.border
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontLarge
                        clip: true
                        onTextChanged: grid.currentIndex = 0

                        // Keyboard: the arrows move over the grid while you type.
                        Keys.onPressed: event => {
                            const n = grid.count, c = root.columns
                            if (event.key === Qt.Key_Escape) root.open = false
                            else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) root.start(win.shown[grid.currentIndex])
                            else if (event.key === Qt.Key_Right || event.key === Qt.Key_Tab) grid.currentIndex = Math.min(n - 1, grid.currentIndex + 1)
                            else if (event.key === Qt.Key_Left || event.key === Qt.Key_Backtab) grid.currentIndex = Math.max(0, grid.currentIndex - 1)
                            else if (event.key === Qt.Key_Down) grid.currentIndex = Math.min(n - 1, grid.currentIndex + c)
                            else if (event.key === Qt.Key_Up) grid.currentIndex = Math.max(0, grid.currentIndex - c)
                            else if (event.key === Qt.Key_PageDown) grid.currentIndex = Math.min(n - 1, grid.currentIndex + c * root.visibleRows)
                            else if (event.key === Qt.Key_PageUp) grid.currentIndex = Math.max(0, grid.currentIndex - c * root.visibleRows)
                            else return
                            event.accepted = true
                        }

                        StyledText {
                            visible: search.text === ""
                            anchors.verticalCenter: parent.verticalCenter
                            text: "Search apps"
                            color: Theme.dim
                            font.pixelSize: Theme.fontLarge
                        }
                    }
                }

                // ---- the apps ----
                GridView {
                    id: grid
                    x: root.pad
                    anchors { top: field.bottom; topMargin: root.pad; bottom: parent.bottom; bottomMargin: root.pad }
                    width: root.columns * root.cellWidth
                    cellWidth: root.cellWidth
                    cellHeight: root.cellHeight
                    clip: true
                    boundsBehavior: Flickable.StopAtBounds
                    model: win.shown
                    highlightFollowsCurrentItem: false
                    onCurrentIndexChanged: positionViewAtIndex(currentIndex, GridView.Contain)

                    highlight: Item {
                        z: -1
                        width: root.cellWidth
                        height: root.cellHeight
                        visible: grid.count > 0 && grid.currentIndex >= 0
                        x: grid.currentItem ? grid.currentItem.x : (grid.currentIndex >= 0 ? (grid.currentIndex % root.columns) * root.cellWidth : 0)
                        y: grid.currentItem ? grid.currentItem.y : (grid.currentIndex >= 0 ? Math.floor(grid.currentIndex / root.columns) * root.cellHeight : 0)
                        Behavior on x { SpringAnimation { spring: Theme.springSnappy; damping: Theme.dampingSnappy; epsilon: Theme.epsPx } }
                        Behavior on y { SpringAnimation { spring: Theme.springSnappy; damping: Theme.dampingSnappy; epsilon: Theme.epsPx } }

                        Rectangle {
                            anchors { fill: parent; margins: 4 }
                            radius: Theme.radiusCard
                            color: Theme.selected
                        }
                    }

                    delegate: Item {
                        id: cell
                        required property var modelData
                        required property int index
                        readonly property bool current: GridView.isCurrentItem

                        width: root.cellWidth
                        height: root.cellHeight

                        Rectangle {
                            anchors { fill: parent; margins: 4 }
                            radius: Theme.radiusCard
                            color: area.containsMouse ? Theme.hover : Theme.clear
                            Behavior on color { ColorAnimation { duration: Theme.durFast } }
                        }

                        Column {
                            anchors.centerIn: parent
                            width: parent.width - 16
                            spacing: 8
                            scale: area.pressed ? Theme.pressScale : 1
                            Behavior on scale { SpringAnimation { spring: Theme.springSnappy; damping: Theme.dampingSnappy; epsilon: Theme.epsNorm } }

                            IconImage {
                                anchors.horizontalCenter: parent.horizontalCenter
                                implicitSize: 44
                                source: Quickshell.iconPath(cell.modelData.icon ?? "", "application-x-executable")
                            }
                            StyledText {
                                width: parent.width
                                horizontalAlignment: Text.AlignHCenter
                                text: cell.modelData.name
                                color: cell.current ? Theme.bright : Theme.text
                                font.pixelSize: Theme.fontSmall
                                wrapMode: Text.Wrap
                                maximumLineCount: 2
                                elide: Text.ElideRight
                            }
                        }

                        MouseArea {
                            id: area
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.start(cell.modelData)
                        }
                    }
                }

                StyledText {
                    visible: grid.count === 0
                    anchors { horizontalCenter: parent.horizontalCenter; top: field.bottom; topMargin: root.pad + root.cellHeight / 2 - height / 2 }
                    text: "No app matches \u201c" + search.text + "\u201d"
                    color: Theme.dim
                }
            }
        }
    }
}
