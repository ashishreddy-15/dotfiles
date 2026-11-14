import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Widgets
import qs

// Reusable Spotlight-style picker: a search field with a list under it, centred in the upper third of
// the focused monitor. The launcher and the clipboard history are both built on it.
//
// The user of this component supplies:
//   items       the rows to show, already filtered and ranked (at most maxResults):
//               [{ title, subtitle?, icon? , ...anything else you need back }]
//   onActivated called with the chosen item when Enter is pressed or a row is clicked
// and reads `query` (what is typed) to compute items.
//
// Keys: Up/Down or Tab/Shift+Tab move, Enter chooses, Esc or a click outside closes.
//
// Animation notes (why it is built this way):
//  - The window is a fixed size and never resized. Only the card inside it grows and shrinks.
//    Resizing a layer-shell window per keystroke makes the compositor stretch and smear the old frame.
//  - Hyprland's own fade must be switched off for this window's namespace (hypr/modules/rules.lua);
//    the open/close fade and the height change are animated here, inside the window.
Scope {
    id: root

    property bool open: false
    property string query: ""
    property var items: []
    property int selected: 0
    property string placeholder: "Search"
    property string namespace: "quickshell-picker"
    property int maxResults: 8

    signal activated(var item)

    readonly property int searchHeight: 54
    readonly property int rowHeight: 40
    readonly property int listPadding: 6

    // Open with text already typed.
    function setQuery(text) { open = true; input.text = text }
    // Same as pressing Enter on the highlighted row.
    function chooseSelected() { choose(items[selected]) }
    function choose(item) {
        if (!item) return
        open = false
        activated(item)
    }

    onOpenChanged: if (open) { query = ""; selected = 0 }

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
        WlrLayershell.namespace: root.namespace
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
                            const n = root.items.length
                            if (event.key === Qt.Key_Escape) {
                                root.open = false
                            } else if (event.key === Qt.Key_Down || (event.key === Qt.Key_Tab && n)) {
                                root.selected = (root.selected + 1) % Math.max(n, 1)
                            } else if (event.key === Qt.Key_Up || event.key === Qt.Key_Backtab) {
                                root.selected = (root.selected - 1 + Math.max(n, 1)) % Math.max(n, 1)
                            } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                                root.chooseSelected()
                            } else {
                                return
                            }
                            event.accepted = true
                        }

                        StyledText {
                            mono: false
                            visible: input.text === ""
                            text: root.placeholder
                            color: Theme.dim
                            font.pixelSize: 18
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }
                }

                // Results
                Rectangle {
                    visible: root.items.length > 0
                    width: parent.width
                    height: 1
                    color: Theme.border
                }

                Column {
                    visible: root.items.length > 0
                    width: parent.width
                    topPadding: root.listPadding
                    bottomPadding: root.listPadding

                    Repeater {
                        model: root.items

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

                            RowLayout {
                                anchors { fill: parent; leftMargin: 14; rightMargin: 14 }
                                spacing: 12

                                IconImage {
                                    visible: !!row.modelData.icon
                                    implicitSize: 22
                                    source: Quickshell.iconPath(row.modelData.icon ?? "", "application-x-executable")
                                }

                                // Title, with an optional dim subtitle right after it. Long titles are cut with "…".
                                Item {
                                    Layout.fillWidth: true
                                    Layout.fillHeight: true

                                    StyledText {
                                        id: title
                                        mono: false
                                        anchors.verticalCenter: parent.verticalCenter
                                        width: Math.min(implicitWidth, parent.width - (sub.visible ? sub.implicitWidth + 10 : 0))
                                        elide: Text.ElideRight
                                        text: row.modelData.title
                                        color: row.active ? Theme.bright : Theme.text
                                        font.pixelSize: 15
                                    }
                                    StyledText {
                                        id: sub
                                        mono: false
                                        anchors { left: title.right; leftMargin: 10; verticalCenter: parent.verticalCenter }
                                        visible: text !== ""
                                        text: row.modelData.subtitle ?? ""
                                        color: Theme.dim
                                    }
                                }
                            }

                            // Only a real mouse move changes the highlight. (A list that re-lays out under a
                            // resting pointer must not steal the keyboard selection.)
                            MouseArea {
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onPositionChanged: root.selected = row.index
                                onClicked: root.choose(row.modelData)
                            }
                        }
                    }
                }
            }
        }
    }
}
