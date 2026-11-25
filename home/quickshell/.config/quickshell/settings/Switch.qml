import QtQuick
import qs
import "../ui"

// An on / off switch.   Switch { checked: thing.on; onToggled: thing.on = !thing.on }
Rectangle {
    id: root

    property bool checked: false
    signal toggled()

    // Keyboard: Space or Enter flips it. The arrows do not: they move around (Left goes back to the sidebar).
    activeFocusOnTab: true
    Keys.onPressed: event => {
        if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter || event.key === Qt.Key_Space) { root.toggled(); event.accepted = true }
    }

    implicitWidth: 40
    implicitHeight: 22
    radius: height / 2
    color: checked ? Theme.accent : Theme.clear
    border.width: 1
    border.color: checked ? Theme.clear : Theme.border
    Behavior on color { ColorAnimation { duration: Theme.durFast } }
    Behavior on border.color { ColorAnimation { duration: Theme.durFast } }

    Rectangle {
        readonly property real baseSize: parent.height - 8
        width: mouse.pressed ? baseSize + 3 : baseSize
        height: baseSize
        radius: height / 2
        anchors.verticalCenter: parent.verticalCenter
        x: root.checked ? parent.width - width - 4 : 4
        color: root.checked ? Theme.bg : Theme.dim
        HighlightMotion on x {}
        PressMotion on width { epsilon: Theme.epsPx }
        Behavior on color { ColorAnimation { duration: Theme.durFast } }
    }

    MouseArea {
        id: mouse
        anchors { fill: parent; margins: -4 }
        cursorShape: Qt.PointingHandCursor
        onClicked: root.toggled()
    }

    FocusRing { visible: root.activeFocus; radius: root.radius; anchors.margins: -3 }
}
