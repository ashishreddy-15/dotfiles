import QtQuick
import qs

// A toggle tile (Wi-Fi, Bluetooth, ...): a label, a line of state, and a fill when it is on. Click it to toggle.
Item {
    id: root

    property string label
    property string value
    property bool active: false          // on: the tile is filled with the accent

    signal toggled()

    height: 52

    // Keyboard: Enter or Space toggles.
    activeFocusOnTab: true
    Keys.onPressed: event => {
        if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter || event.key === Qt.Key_Space) { root.toggled(); event.accepted = true }
    }

    // Quiet by design: "on" is a light wash with the accent mark (the same sign a selected row has in a
    // picker); "off" is only a hairline outline. Nothing here should shout louder than the sliders and text.
    Rectangle {
        anchors.fill: parent
        radius: Theme.radiusRow
        color: root.active ? (area.containsMouse ? Theme.selectedHover : Theme.selected)
                           : (area.containsMouse ? Theme.hover : Theme.clear)
        border.width: 1
        border.color: root.active ? Theme.clear : Theme.border
        Behavior on color { ColorAnimation { duration: Theme.durFast } }
        Behavior on border.color { ColorAnimation { duration: Theme.durFast } }

        Rectangle {
            x: 5
            anchors.verticalCenter: parent.verticalCenter
            width: 2
            height: 18
            radius: Theme.radiusMark
            color: Theme.accent
            opacity: root.active ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: Theme.durFast; easing.type: Theme.easeOut } }
        }
    }

    MouseArea {
        id: area
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.toggled()
    }

    Column {
        anchors { left: parent.left; right: parent.right; verticalCenter: parent.verticalCenter; leftMargin: 12; rightMargin: 12 }
        spacing: 2

        StyledText {
            width: parent.width
            text: root.label
            color: root.active ? Theme.bright : Theme.text
            elide: Text.ElideRight
        }
        StyledText {
            width: parent.width
            text: root.value
            color: Theme.dim
            font.pixelSize: Theme.fontSmall
            elide: Text.ElideRight
        }
    }

    FocusRing { visible: root.activeFocus }
}
