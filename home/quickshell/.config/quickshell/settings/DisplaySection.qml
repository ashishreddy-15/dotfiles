import QtQuick
import Quickshell
import Quickshell.Hyprland
import qs
import "../panel"

// Display: brightness of each screen that can be controlled, and the night light (warmer colours at night).
Page {
    id: root

    // External screens that are connected but have no brightness control, and why.
    readonly property var uncontrollable: Hyprland.monitors.values
        .map(m => m.name)
        .filter(n => !Brightness.isInternal(n) && !Brightness.displays.some(d => d.name === n))
    function reason() {
        switch (Brightness.ddcStatus) {
        case "unknown":     return "Looking for a way to control it…"
        case "no-access":   return "No DDC access (see the README)"
        case "unsupported": return "DDC/CI is off or not supported"
        case "missing":     return "ddcutil is not installed"
        default:            return "Not controllable"
        }
    }

    Component.onCompleted: Brightness.refresh()    // show the real levels

    Repeater {
        model: Brightness.displays
        SettingRow {
            required property var modelData
            title: "Brightness"
            description: modelData.label
            Row {
                spacing: 14
                Slider { width: 200; value: modelData.level; onMoved: v => modelData.set(v) }
                StyledText { width: 44; height: 32; horizontalAlignment: Text.AlignRight; text: Math.round(modelData.level * 100) + "%" }
            }
        }
    }
    Repeater {
        model: root.uncontrollable
        SettingRow {
            required property string modelData
            title: "Brightness"
            description: modelData + ": " + root.reason()
        }
    }

    GroupLabel { text: "Night light" }
    SettingRow {
        title: "Night light"
        description: "Makes the screen warmer so it is easier on the eyes at night."
        Switch { checked: Modes.nightLight; onToggled: Modes.toggleNight() }
    }
    SettingRow {
        title: "Warmth"
        description: "Right is warmer."
        Row {
            spacing: 14
            Slider {
                width: 200
                value: (Modes.kelvinMax - Modes.kelvin) / (Modes.kelvinMax - Modes.kelvinMin)
                onMoved: v => Modes.setWarmth(Modes.kelvinMax - v * (Modes.kelvinMax - Modes.kelvinMin))
            }
            StyledText { width: 60; height: 32; horizontalAlignment: Text.AlignRight; text: Modes.kelvin + " K" }
        }
    }
}
