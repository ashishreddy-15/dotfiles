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
        height: 4
        radius: Theme.radiusSmall
        color: Theme.border

        Rectangle {
            width: parent.width * root.clamp(root.value)
            height: parent.height
            radius: parent.radius
            color: root.muted ? Theme.dim : Theme.accent
        }
    }

    MouseArea {
        anchors { fill: parent; topMargin: -4; bottomMargin: -4 }
        cursorShape: Qt.PointingHandCursor
        onPressed: m => root.moved(root.clamp(m.x / width))
        onPositionChanged: m => { if (pressed) root.moved(root.clamp(m.x / width)) }
    }
    WheelHandler {
        onWheel: e => root.moved(root.clamp(root.value + (e.angleDelta.y > 0 ? 0.05 : -0.05)))
    }
}
