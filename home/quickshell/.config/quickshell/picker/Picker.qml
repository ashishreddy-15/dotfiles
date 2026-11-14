import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Widgets
import qs
import "../ui"

// Reusable Spotlight-style picker: a search field with a list under it, centred in the upper third of
// the focused monitor. The launcher and the clipboard history are both built on it.
//
// The user of this component supplies:
//   items       the rows to show, already filtered and ranked, as many as you like:
//               [{ title, subtitle?, icon? , ...anything else you need back }]
//               maxResults rows are visible at once; longer lists scroll (arrows or wheel).
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
    property int offset: 0              // index of the first visible row when the list is longer than maxResults
    property string placeholder: "Search"
    property string namespace: "quickshell-picker"
    property int maxResults: 8

    signal activated(var item)

    readonly property var visibleItems: items.slice(offset, offset + maxResults)

    readonly property int searchHeight: 54
    readonly property int rowHeight: 40
    readonly property int listPadding: Theme.cardInset
    readonly property int cardWidth: 600
    // The tallest the card gets (search field + a full list), so the window never has to change size.
    readonly property int maxCardHeight: searchHeight + 1 + 2 * listPadding + maxResults * rowHeight

    // Open with text already typed.
    function setQuery(text) { open = true; input.text = text }
    // Same as pressing Enter on the highlighted row.
    function chooseSelected() { choose(items[selected]) }
    function choose(item) {
        if (!item) return
        open = false
        activated(item)
    }

    onOpenChanged: if (open) { query = ""; selected = 0; offset = 0 }

    // Move the highlight by `step` rows (wrapping) and scroll so it stays visible.
    function move(step) {
        const n = items.length
        if (n === 0) return
        selected = (selected + step + n) % n
    }
    // PageUp / PageDown: jump a page and stop at the ends (no wrapping).
    function page(step) {
        if (items.length > 0) selected = Math.max(0, Math.min(items.length - 1, selected + step))
    }
    onSelectedChanged: {
        if (selected < offset) offset = selected
        else if (selected >= offset + maxResults) offset = selected - maxResults + 1
    }
    // The list can shrink or load late (e.g. clipboard history): keep the highlight and window inside it.
    onItemsChanged: {
        if (selected >= items.length) selected = Math.max(0, items.length - 1)
        offset = Math.max(0, Math.min(offset, items.length - maxResults))
    }

    PanelWindow {
        id: win

        // Open on the monitor you're working on.
        screen: Quickshell.screens.find(s => s.name === Hyprland.focusedMonitor?.name) ?? ShellState.mainScreen

        // Stay mapped until the close animation has finished.
        visible: root.open || card.shown > 0

        anchors.top: true                            // top only = horizontally centred
        margins.top: Math.round((screen?.height ?? 1080) * 0.22) - Theme.shadowMargin
        exclusionMode: ExclusionMode.Ignore
        // Fixed size: the card plus room for its shadow on every side. The window never resizes; only the card does.
        implicitWidth: root.cardWidth + 2 * Theme.shadowMargin
        implicitHeight: root.maxCardHeight + 2 * Theme.shadowMargin
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

        Card {
            id: card
            x: Theme.shadowMargin
            y: Theme.shadowMargin
            width: root.cardWidth
            open: root.open
            contentHeight: column.implicitHeight

            WheelHandler { onWheel: e => root.move(e.angleDelta.y > 0 ? -1 : 1) }

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
                        onTextChanged: { root.query = text; root.selected = 0; root.offset = 0 }
                        color: Theme.bright
                        selectionColor: Theme.border
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontXL
                        clip: true
                        focus: true

                        Connections {
                            target: root
                            function onOpenChanged() { if (root.open) { input.text = ""; input.forceActiveFocus() } }
                        }

                        Keys.onPressed: event => {
                            if (event.key === Qt.Key_Escape) {
                                root.open = false
                            } else if (event.key === Qt.Key_Down || event.key === Qt.Key_Tab) {
                                root.move(1)
                            } else if (event.key === Qt.Key_Up || event.key === Qt.Key_Backtab) {
                                root.move(-1)
                            } else if (event.key === Qt.Key_PageDown) {
                                root.page(root.maxResults)
                            } else if (event.key === Qt.Key_PageUp) {
                                root.page(-root.maxResults)
                            } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                                root.chooseSelected()
                            } else {
                                return
                            }
                            event.accepted = true
                        }

                        StyledText {
                            visible: root.items.length > root.maxResults
                            anchors { right: parent.right; verticalCenter: parent.verticalCenter }
                            text: (root.selected + 1) + "/" + root.items.length
                            color: Theme.dim
                        }
                        StyledText {
                            visible: input.text === ""
                            text: root.placeholder
                            color: Theme.dim
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontXL
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

                Item {
                    visible: root.items.length > 0
                    width: parent.width
                    height: list.implicitHeight

                    // One highlight for the whole list: it slides to the selected row instead of each row
                    // lighting up on its own. (Scrolling moves `offset`, and the highlight follows.)
                    Rectangle {
                        x: root.listPadding
                        y: root.listPadding + (root.selected - root.offset) * root.rowHeight
                        width: parent.width - 2 * root.listPadding
                        height: root.rowHeight
                        radius: Theme.radiusRow
                        color: Theme.selected
                        Behavior on y { NumberAnimation { duration: Theme.durBase; easing.type: Theme.easeOut } }

                        // The accent mark makes the selected row obvious on any wallpaper.
                        Rectangle {
                            x: 4
                            anchors.verticalCenter: parent.verticalCenter
                            width: 2
                            height: 16
                            radius: Theme.radiusMark
                            color: Theme.accent
                        }
                    }

                Column {
                    id: list
                    width: parent.width
                    topPadding: root.listPadding
                    bottomPadding: root.listPadding

                    Repeater {
                        model: root.visibleItems

                        Rectangle {
                            id: row
                            required property var modelData
                            required property int index
                            readonly property bool active: index + root.offset === root.selected

                            x: root.listPadding
                            width: parent.width - 2 * root.listPadding
                            height: root.rowHeight
                            radius: Theme.radiusRow
                            color: Theme.clear   // the highlight is drawn behind the list

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
                                        anchors.verticalCenter: parent.verticalCenter
                                        width: Math.min(implicitWidth, parent.width - (sub.visible ? sub.implicitWidth + 10 : 0))
                                        elide: Text.ElideRight
                                        text: row.modelData.title
                                        color: row.active ? Theme.bright : Theme.text
                                        font.pixelSize: Theme.fontLarge
                                    }
                                    StyledText {
                                        id: sub
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
                                onPositionChanged: root.selected = row.index + root.offset
                                onClicked: root.choose(row.modelData)
                            }
                        }
                    }
                }
                }
            }
        }
    }
}
