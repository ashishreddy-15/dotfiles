import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Widgets
import qs
import "../ui"

// The right-click menu of a tray icon, drawn with our own Card instead of the toolkit's grey popup.
// Entries come from the app (D-Bus menu); a submenu opens as a page with a back row, like the control center.
//
//   TrayMenu { id: menu; window: bar }
//   menu.openFor(trayItem, iconCentreX)      // x in the bar window's coordinates
//
// Like the pickers it is a fixed-size layer window with the card inside, mapped until the exit animation is over
// (the blur and the "no compositor fade" rules for its namespace are in hypr/modules/rules.lua).
Scope {
    id: root

    required property var window            // the bar window: gives the screen and where the menu sits

    property bool open: false
    property bool mounted: false
    onOpenChanged: if (open) mounted = true; else if (!loader.item || !loader.item.alive) mounted = false
    property var trayItem: null
    property real anchorX: 0
    // The submenus we have stepped into, as positions in each parent's list (outermost first). Positions, not the
    // entry objects: the app rebuilds its menu entries whenever it refreshes them, which would leave stale objects.
    property var path: []

    readonly property int cardWidth: 300
    readonly property int maxHeight: 460
    readonly property int rowHeight: 28

    function openFor(item, centreX) {
        trayItem = item
        anchorX = centreX
        path = []
        open = true
    }
    function close() { if (loader.item) loader.item.leave(path.length); open = false }

    LazyLoader {
        id: loader
        active: root.open || root.mounted

        PanelWindow {
            id: win

            property bool ready: false
            readonly property bool alive: card.shown > 0
            onAliveChanged: if (!alive && !root.open) Qt.callLater(() => { if (!root.open && (!loader.item || !loader.item.alive)) root.mounted = false })

            // Apps such as nm-applet fill a submenu only when told it is being shown (D-Bus "AboutToShow"),
            // so tell them when we step into one and when we leave it.
            function entryAt(op, i) { return op && op.children && i >= 0 && i < op.children.values.length ? op.children.values[i] : null }
            function enter(i) {
                const e = entryAt(opener, i)
                if (!e) return
                e.opened()
                root.path = root.path.concat([i])
            }
            function leave(count) {
                for (let n = 0; n < count && root.path.length > 0; n++) {
                    entryAt(openers[root.path.length - 1], root.path[root.path.length - 1])?.closed()
                    root.path = root.path.slice(0, -1)
                }
            }

            Component.onCompleted: Qt.callLater(() => { ready = true; keys.forceActiveFocus() })
            Connections {
                target: root
                function onOpenChanged() { if (root.open) Qt.callLater(() => keys.forceActiveFocus()) }
            }

            // One opener per level (a menu three submenus deep is the most we support): each one opens the entry chosen in the previous.
            QsMenuOpener { id: o0; menu: root.trayItem ? root.trayItem.menu : null }
            QsMenuOpener { id: o1; menu: root.path.length > 0 ? win.entryAt(o0, root.path[0]) : null }
            QsMenuOpener { id: o2; menu: root.path.length > 1 ? win.entryAt(o1, root.path[1]) : null }
            QsMenuOpener { id: o3; menu: root.path.length > 2 ? win.entryAt(o2, root.path[2]) : null }
            readonly property var openers: [o0, o1, o2, o3]
            readonly property var opener: openers[Math.min(root.path.length, 3)]

            screen: root.window.screen
            visible: root.open || card.shown > 0

            anchors { top: true; left: true; right: true }
            margins.top: Theme.barHeight + 4 - Theme.shadowMargin
            exclusionMode: ExclusionMode.Ignore
            implicitHeight: root.maxHeight + 2 * Theme.shadowMargin
            color: "transparent"
            mask: Region { item: card }
            WlrLayershell.namespace: "quickshell-traymenu"
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: root.open ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

            // Click anywhere else to close.
            HyprlandFocusGrab {
                active: root.open
                windows: [win]
                onCleared: root.close()
            }

            Item {
                id: keys
                focus: true
                Keys.onEscapePressed: root.path.length > 0 ? win.leave(1) : root.close()
            }

            Card {
                id: card
                // Centred under the icon, kept inside the screen.
                x: Math.max(8, Math.min(win.width - root.cardWidth - 8, root.anchorX - root.cardWidth / 2))
                y: Theme.shadowMargin
                width: root.cardWidth
                maxHeight: root.maxHeight
                open: root.open && win.ready
                contentHeight: column.implicitHeight + 2 * Theme.cardInset

                Flickable {
                    anchors.fill: parent
                    contentHeight: column.implicitHeight + 2 * Theme.cardInset
                    boundsBehavior: Flickable.StopAtBounds
                    interactive: contentHeight > height

                    Column {
                        id: column
                        x: Theme.cardInset
                        y: Theme.cardInset
                        width: parent.width - 2 * Theme.cardInset

                        // Back row, inside a submenu
                        Row {
                            id: backRow
                            visible: root.path.length > 0
                            height: visible ? root.rowHeight : 0
                            MouseArea {
                                width: column.width
                                height: root.rowHeight
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: win.leave(1)
                                Rectangle {
                                    anchors.fill: parent
                                    radius: Theme.radiusRow
                                    color: parent.containsMouse ? Theme.hover : Theme.clear
                                    Behavior on color { ColorAnimation { duration: Theme.durFast } }
                                }
                                StyledText {
                                    x: 10
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: Theme.glyphBack + "  " + (win.entryAt(win.openers[root.path.length - 1], root.path[root.path.length - 1])?.text ?? "")
                                    color: Theme.bright
                                }
                            }
                        }

                        Repeater {
                            model: win.opener.children

                            Item {
                                id: entry
                                required property var modelData
                                required property int index
                                readonly property bool separator: modelData.isSeparator

                                width: column.width
                                height: separator ? 9 : root.rowHeight

                                Rectangle {
                                    visible: entry.separator
                                    anchors { left: parent.left; right: parent.right; verticalCenter: parent.verticalCenter; leftMargin: 6; rightMargin: 6 }
                                    height: 1
                                    color: Theme.border
                                }

                                Rectangle {
                                    visible: !entry.separator
                                    anchors.fill: parent
                                    radius: Theme.radiusRow
                                    color: area.containsMouse && entry.modelData.enabled ? Theme.hover : Theme.clear
                                    Behavior on color { ColorAnimation { duration: Theme.durFast } }
                                }

                                // tick / dot column
                                StyledText {
                                    visible: !entry.separator
                                    x: 10
                                    width: 14
                                    anchors.verticalCenter: parent.verticalCenter
                                    color: Theme.accent
                                    text: entry.modelData.checkState === Qt.Checked
                                          ? (entry.modelData.buttonType === 2 ? Theme.glyphMark : Theme.glyphCheck) : ""
                                }
                                IconImage {
                                    visible: !entry.separator && (entry.modelData.icon ?? "") !== ""
                                    x: 28
                                    anchors.verticalCenter: parent.verticalCenter
                                    implicitSize: 16
                                    source: entry.modelData.icon ?? ""
                                }
                                StyledText {
                                    visible: !entry.separator
                                    x: (entry.modelData.icon ?? "") !== "" ? 50 : 28
                                    width: parent.width - x - (entry.modelData.hasChildren ? 30 : 12)
                                    anchors.verticalCenter: parent.verticalCenter
                                    elide: Text.ElideRight
                                    // D-Bus menus mark the keyboard accelerator with an underscore: "_Quit".
                                    text: (entry.modelData.text ?? "").replace(/_(.)/g, "$1")
                                    color: entry.modelData.enabled ? Theme.text : Theme.dim
                                }
                                StyledText {
                                    visible: entry.modelData.hasChildren
                                    anchors { right: parent.right; rightMargin: 12; verticalCenter: parent.verticalCenter }
                                    text: Theme.glyphNext
                                    color: Theme.dim
                                }

                                MouseArea {
                                    id: area
                                    visible: !entry.separator
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    enabled: entry.modelData.enabled
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        if (entry.modelData.hasChildren && root.path.length < 3) win.enter(entry.index)
                                        else { entry.modelData.triggered(); root.close() }
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
