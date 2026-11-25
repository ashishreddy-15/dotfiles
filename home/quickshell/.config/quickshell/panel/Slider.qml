import QtQuick
import qs

// A thin slider. Click or drag to set; scroll to nudge. It reports changes through `moved`;
// the owner decides what to do with them.
Item {
    id: root

    property real value: 0          // 0..1
    property bool muted: false

    signal moved(real value)

    implicitHeight: 32

    function clamp(v) { return Math.max(0, Math.min(1, v)) }

    Rectangle {
        id: track
        anchors { left: parent.left; right: parent.right; verticalCenter: parent.verticalCenter }
        height: mouse.pressed ? 6 : 4       // a little thicker under the pointer, thicker still while dragging
        Behavior on height { SpringAnimation { spring: Theme.springSnappy; damping: Theme.dampingSnappy; epsilon: Theme.epsPx } }
        radius: Theme.radiusSmall
        color: Theme.border

        Rectangle {
            width: parent.width * root.clamp(root.value)
            height: parent.height
            radius: parent.radius
            color: root.muted ? Theme.dim : Theme.accent
            Behavior on width { enabled: !mouse.pressed; SpringAnimation { spring: Theme.springSnappy; damping: Theme.dampingSnappy; epsilon: Theme.epsPx } }
        }

        // Knob: appears when the pointer is over the slider.
        Rectangle {
            x: parent.width * root.clamp(root.value) - width / 2
            anchors.verticalCenter: parent.verticalCenter
            width: mouse.pressed ? 14 : 12
            height: width
            radius: width / 2
            color: Theme.bright
            opacity: mouse.containsMouse || mouse.pressed ? 1 : 0
            Behavior on x { enabled: !mouse.pressed; SpringAnimation { spring: Theme.springSnappy; damping: Theme.dampingSnappy; epsilon: Theme.epsPx } }
            Behavior on opacity { NumberAnimation { duration: Theme.durFast } }
            Behavior on width { SpringAnimation { spring: Theme.springSnappy; damping: Theme.dampingSnappy; epsilon: Theme.epsPx } }
        }
    }

    MouseArea {
        id: mouse
        hoverEnabled: true
        anchors { fill: parent; topMargin: -4; bottomMargin: -4 }
        cursorShape: Qt.PointingHandCursor
        onPressed: m => root.moved(root.clamp(m.x / width))
        onPositionChanged: m => { if (pressed) root.moved(root.clamp(m.x / width)) }
    }
    WheelHandler {
        onWheel: e => root.moved(root.clamp(root.value + (e.angleDelta.y > 0 ? 0.05 : -0.05)))
    }
}
