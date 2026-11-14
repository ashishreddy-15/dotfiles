import QtQuick
import Quickshell
import Quickshell.Hyprland
import qs

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

            StyledText { text: "["; color: Theme.accent; opacity: item.current ? 1 : 0 }
            StyledText {
                text: item.modelData.id
                color: item.current ? Theme.bright
                     : item.modelData.urgent ? Theme.warn
                     : hover.hovered ? Theme.text
                     : Theme.dim
            }
            StyledText { text: "]"; color: Theme.accent; opacity: item.current ? 1 : 0 }

            HoverHandler { id: hover; cursorShape: Qt.PointingHandCursor }
            TapHandler { onTapped: item.modelData.activate() }
        }
    }
}
