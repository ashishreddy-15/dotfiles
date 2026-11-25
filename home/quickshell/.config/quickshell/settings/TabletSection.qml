import QtQuick
import Quickshell
import Quickshell.Hyprland
import qs
import "../ui"

// Tablet: which screen a pen tablet covers, its active area, orientation and mode (Tablet.qml applies them live),
// and a test pad to try it. Shows a note instead when no tablet is connected.
Page {
    id: root

    Component.onCompleted: { Tablet.ensureActions(); Tablet.refresh() }

    // The page scrolls by dragging, which would take the pen's strokes away from the test pad (writing would scroll
    // the page instead). Over the pad, or while drawing on it, the page does not scroll.
    interactive: contentHeight > height && !padHover.hovered && !pen.active

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

    // ---- ExpressKeys: the four keys on the tablet, left to right ----
    GroupLabel { visible: Tablet.present; text: "ExpressKeys" }
    StyledText {
        visible: Tablet.present
        width: parent.width
        bottomPadding: 6
        text: Tablet.keysReady
            ? "What each key on the tablet does, left to right. The pen's buttons are set in Xournal++: Edit > Preferences > Input System."
            : "Needs one setup step first: run ./install.sh services (it asks for your password once)."
        color: Tablet.keysReady ? Theme.dim : Theme.warn
        font.pixelSize: Theme.fontSmall
        wrapMode: Text.Wrap
    }
    Repeater {
        model: Tablet.present ? 4 : 0
        SettingRow {
            id: keyRow
            required property int index
            title: "Key " + (index + 1) + (index === 0 ? " (left)" : index === 3 ? " (right)" : "")
            Choice {
                options: Tablet.actions.map(a => ({ label: a.label, value: a.id }))
                value: Tablet.expressKeys[keyRow.index] ?? "none"
                onPicked: v => Tablet.setKey(keyRow.index, v)
            }
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

        HoverHandler { id: padHover }           // a pen hovering above the tablet counts too
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

    // ---- handwriting input (Super + Shift + W): see handwriting/HandwritingPopup.qml, Handwriting.qml ----
    GroupLabel { text: "Handwriting input" }
    SettingRow {
        title: "Handwriting input"
        description: "Open the handwriting strip with Caps Lock, Copilot key, or Super + Shift + W while a tablet is connected. Off: Caps Lock works as normal."
        Switch { checked: Handwriting.enabled; onToggled: Handwriting.set("enabled", !Handwriting.enabled) }
    }
    SettingRow {
        visible: Handwriting.enabled
        title: "Enter does"
        description: "Type: into the window you were in. Copy: to the clipboard. Launcher: search the apps for it. Tab in the popup changes it."
        Segmented { options: Handwriting.deliverModes; value: Handwriting.deliver; onPicked: v => Handwriting.set("deliver", v) }
    }
    SettingRow {
        visible: Handwriting.enabled
        title: "Keep what I write"
        description: "Saves each confirmed line (picture, strokes, final text) in ~/handwriting/usage, on this computer only, to train the model on your hand."
        Switch { checked: Handwriting.logging; onToggled: Handwriting.set("logging", !Handwriting.logging) }
    }
    SettingRow {
        visible: Handwriting.enabled
        title: "Continuous writing"
        description: "Each pause in writing enters the line straight away and clears the ink, so you can keep going. In Type mode the strip does not take the keyboard from the window you write for. Undo with no ink takes the last line back. The strip's Continuous button switches it for one session."
        Switch { checked: Handwriting.continuousDefault; onToggled: Handwriting.set("continuousDefault", !Handwriting.continuousDefault) }
    }
    SettingRow {
        visible: Handwriting.enabled
        title: "A continuous line ends with"
        description: "Space keeps typing on one line. Newline presses Return after each line, so it is off by default (Return can run a command in a terminal)."
        Segmented { options: Handwriting.lineEnds; value: Handwriting.lineEnd; onPicked: v => Handwriting.set("lineEnd", v) }
    }
}
