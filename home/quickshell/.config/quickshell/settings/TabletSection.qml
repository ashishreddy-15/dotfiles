import QtQuick
import Quickshell
import Quickshell.Hyprland
import qs
import "../ui"

// Tablet: which screen a pen tablet covers, its active area, orientation and mode (Tablet.qml applies them live),
// and a test pad to try it. Shows a note instead when no tablet is connected.
Page {
    id: root

    Component.onCompleted: Tablet.refresh()

    readonly property var screens: [{ label: "Working screen", value: "current" }]
        .concat(Hyprland.monitors.values.map(m => ({ label: Brightness.isInternal(m.name) ? "Laptop" : "Monitor", value: m.name })))
        .concat([{ label: "All", value: "all" }])

    StyledText {
        visible: !Tablet.present
        width: parent.width
        topPadding: 8
        text: "No tablet connected. Plug it in (or connect it by Bluetooth) and it shows up here."
        color: Theme.dim
        wrapMode: Text.Wrap
    }

    SettingRow {
        visible: Tablet.present
        title: Tablet.model
        description: Tablet.battery < 0 ? "Connected"
                   : "Battery " + Tablet.battery + "%" + (Tablet.batteryState === "Charging" ? ", charging" : Tablet.batteryState === "Full" ? ", full" : "")
    }
    SettingRow {
        visible: Tablet.present
        title: "Screen"
        description: "Which screen the tablet covers. Working screen follows you from screen to screen."
        Segmented { options: root.screens; value: Tablet.screen; onPicked: v => Tablet.set("screen", v) }
    }
    SettingRow {
        visible: Tablet.present
        title: "Keep proportions"
        description: "Use only the part of the tablet that has the screen's shape, so circles stay round."
        Switch { checked: Tablet.keepRatio; onToggled: Tablet.set("keepRatio", !Tablet.keepRatio) }
    }
    SettingRow {
        visible: Tablet.present
        title: "Orientation"
        description: "180° is for left-handed use (the buttons on the right)."
        Segmented {
            options: [{ label: "0°", value: 0 }, { label: "90°", value: 90 }, { label: "180°", value: 180 }, { label: "270°", value: 270 }]
            value: Tablet.orientation
            onPicked: v => Tablet.set("orientation", v)
        }
    }
    SettingRow {
        visible: Tablet.present
        title: "Mode"
        description: "Pen: the pointer is where the pen is. Mouse: the pen moves the pointer, like a mouse."
        Segmented {
            options: [{ label: "Pen", value: "pen" }, { label: "Mouse", value: "mouse" }]
            value: Tablet.mode
            onPicked: v => Tablet.set("mode", v)
        }
    }

    // ---- test pad: draw with the pen; the line gets thicker the harder you press ----
    GroupLabel { visible: Tablet.present; text: "Try it (press harder for a thicker line)" }
    Rectangle {
        id: pad
        visible: Tablet.present
        width: parent.width
        height: 150
        radius: Theme.radiusCard
        color: Theme.hover
        border.width: 1
        border.color: Theme.border

        property var last: null

        Canvas {
            id: ink
            anchors.fill: parent
            property var segments: []          // [x1, y1, x2, y2, width]
            property int count: 0              // segments.length, as a property the page notices (push() alone does not)
            function clear() { segments = []; count = 0; requestPaint() }
            onPaint: {
                const ctx = getContext("2d")
                ctx.clearRect(0, 0, width, height)
                ctx.strokeStyle = Theme.bright
                ctx.lineCap = "round"
                for (const s of segments) {
                    ctx.lineWidth = s[4]
                    ctx.beginPath(); ctx.moveTo(s[0], s[1]); ctx.lineTo(s[2], s[3]); ctx.stroke()
                }
            }
        }

        PointHandler {
            id: pen
            acceptedDevices: PointerDevice.Stylus | PointerDevice.Mouse | PointerDevice.TouchPad
            onActiveChanged: if (!active) pad.last = null
            onPointChanged: {
                if (!active) return
                const p = point.position
                // A mouse has no pressure: draw it at half.
                const pressure = point.pressure > 0 && point.device.type === PointerDevice.Stylus ? point.pressure : 0.5
                if (pad.last) { ink.segments.push([pad.last.x, pad.last.y, p.x, p.y, 1 + pressure * 7]); ink.count++ }
                pad.last = { x: p.x, y: p.y }
                ink.requestPaint()
            }
        }

        StyledText {
            visible: ink.count === 0
            anchors.centerIn: parent
            text: "Write here"
            color: Theme.dim
        }
        Rectangle {
            id: clearPad
            anchors { right: parent.right; top: parent.top; margins: 8 }
            width: clearText.implicitWidth + 20
            height: 26
            radius: Theme.radiusRow
            color: clearArea.containsMouse ? Theme.selected : Theme.surface
            opacity: ink.count > 0 ? 1 : 0.5          // always there; brighter once there is something to clear
            Behavior on opacity { NumberAnimation { duration: Theme.durFast } }
            StyledText { id: clearText; anchors.centerIn: parent; text: "Clear"; font.pixelSize: Theme.fontSmall }
            MouseArea { id: clearArea; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: ink.clear() }
        }
    }
}
