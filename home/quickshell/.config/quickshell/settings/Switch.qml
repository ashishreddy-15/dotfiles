import QtQuick
import qs
import "../ui"

// An on / off switch.   Switch { checked: thing.on; onToggled: thing.on = !thing.on }
Rectangle {
    id: root

    property bool checked: false
    signal toggled()

    // Keyboard: Enter or Space flips it; Left switches it off, Right switches it on.
    activeFocusOnTab: true
    Keys.onPressed: event => {
        if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter || event.key === Qt.Key_Space) root.toggled()
        else if (event.key === Qt.Key_Left) { if (root.checked) root.toggled() }
        else if (event.key === Qt.Key_Right) { if (!root.checked) root.toggled() }
        else return
        event.accepted = true
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
        width: parent.height - 8
        height: width
        radius: width / 2
        anchors.verticalCenter: parent.verticalCenter
        x: root.checked ? parent.width - width - 4 : 4
        color: root.checked ? Theme.bg : Theme.dim
        Behavior on x { NumberAnimation { duration: Theme.durFast; easing.type: Theme.easeOut } }
        Behavior on color { ColorAnimation { duration: Theme.durFast } }
    }

    MouseArea {
        anchors { fill: parent; margins: -4 }
        cursorShape: Qt.PointingHandCursor
        onClicked: root.toggled()
    }

    FocusRing { visible: root.activeFocus; radius: root.radius; anchors.margins: -3 }
}
