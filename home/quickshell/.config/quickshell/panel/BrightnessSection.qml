import QtQuick
import Quickshell
import Quickshell.Hyprland
import qs

// One brightness slider per screen we can control (the laptop panel, an external monitor over DDC),
// and a short dim line for an external monitor we can't reach, saying why.
Column {
    id: root

    // External screens that are connected but have no brightness control.
    readonly property var missing: Hyprland.monitors.values
        .map(m => m.name)
        .filter(n => !Brightness.isInternal(n) && !Brightness.displays.some(d => d.name === n))

    function reason() {
        switch (Brightness.ddcStatus) {
        case "unknown":     return "looking…"
        case "no-access":   return "no DDC access (see README)"
        case "unsupported": return "DDC/CI off or unsupported"
        case "missing":     return "ddcutil not installed"
        default:            return "not controllable"
        }
    }

    Repeater {
        model: Brightness.displays

        Item {
            id: row
            required property var modelData
            width: root.width
            height: 32

            StyledText {
                x: 10
                width: 64
                anchors.verticalCenter: parent.verticalCenter
                text: row.modelData.label
                color: Theme.dim
            }
            Slider {
                x: 78
                width: parent.width - 78 - 54
                height: parent.height
                value: row.modelData.level
                onMoved: v => row.modelData.set(v)
            }
            StyledText {
                anchors { right: parent.right; rightMargin: 10; verticalCenter: parent.verticalCenter }
                text: Math.round(row.modelData.level * 100) + "%"
            }
        }
    }

    Repeater {
        model: root.missing

        Item {
            required property string modelData
            width: root.width
            height: 32

            StyledText {
                x: 10
                width: 64
                anchors.verticalCenter: parent.verticalCenter
                text: "monitor"
                color: Theme.dim
            }
            StyledText {
                x: 78
                width: parent.width - 78 - 10
                anchors.verticalCenter: parent.verticalCenter
                text: root.reason()
                color: Theme.dim
                elide: Text.ElideRight
            }
        }
    }
}
