import QtQuick
import Quickshell
import Quickshell.Hyprland
import qs

// The workspaces that live on this bar's monitor. Click to switch, scroll to cycle.
Row {
    id: root

    required property var screen
    readonly property var monitor: Hyprland.monitorFor(screen)

    spacing: 4

    Repeater {
        model: Hyprland.workspaces.values
            .filter(ws => ws.id > 0 && ws.monitor === root.monitor)   // id < 0 are special workspaces
            .sort((a, b) => a.id - b.id)

        Rectangle {
            id: pill

            required property var modelData
            readonly property bool current: modelData.active   // shown on this monitor right now

            width: 24
            height: 20
            radius: 4
            color: current ? Theme.accent
                 : hover.hovered ? Theme.raised
                 : "transparent"

            StyledText {
                anchors.centerIn: parent
                text: pill.modelData.id
                color: pill.current ? Theme.bg
                     : pill.modelData.urgent ? Theme.warn
                     : Theme.text
                font.weight: pill.current ? Font.DemiBold : Font.Normal
            }

            HoverHandler { id: hover }
            TapHandler { onTapped: pill.modelData.activate() }
        }
    }
}
