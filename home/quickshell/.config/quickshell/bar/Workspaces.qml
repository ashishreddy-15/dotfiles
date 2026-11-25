import QtQuick
import Quickshell
import Quickshell.Hyprland
import qs
import "../ui"

// The workspaces that live on this bar's monitor, terminal style:  1 [2] 3
// Click to switch. Brackets are always there (just invisible), so nothing shifts.
Row {
    id: root

    required property var screen
    readonly property var monitor: Hyprland.monitorFor(screen)

    spacing: 2

    Repeater {
        model: Hyprland.workspaces.values
            .filter(ws => ws.id > 0 && ws.monitor === root.monitor)   // id < 0 are special workspaces
            .sort((a, b) => a.id - b.id)

        Row {
            id: item

            required property var modelData
            readonly property bool current: modelData.active   // shown on this monitor right now

            BarText {
                id: openBracket
                text: "["
                color: Theme.barAccent
                opacity: item.current ? 1 : 0
                property real slide: item.current ? 0 : 2
                Behavior on opacity { NumberAnimation { duration: Theme.durFast } }
                HighlightMotion on slide {}
                transform: Translate { x: openBracket.slide }
            }
            BarText {
                text: item.modelData.id
                color: item.current ? Theme.barBright
                     : item.modelData.urgent ? Theme.barWarn
                     : hover.hovered ? Theme.barText
                     : Theme.barDim
            }
            BarText {
                id: closeBracket
                text: "]"
                color: Theme.barAccent
                opacity: item.current ? 1 : 0
                property real slide: item.current ? 0 : -2
                Behavior on opacity { NumberAnimation { duration: Theme.durFast } }
                HighlightMotion on slide {}
                transform: Translate { x: closeBracket.slide }
            }

            HoverHandler { id: hover; cursorShape: Qt.PointingHandCursor }
            TapHandler { onTapped: item.modelData.activate() }
        }
    }
}
