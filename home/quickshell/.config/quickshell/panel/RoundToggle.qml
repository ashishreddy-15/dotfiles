import QtQuick
import qs
import "../ui"

// A round on/off button with its name and state under it (the control center's top row).
// On: filled with the accent. Off: a hairline circle. Click, Enter or Space toggles; Left / Right move to the neighbours.
Item {
    id: root

    property string glyph
    property string label
    property string status                 // the line under the name: a network, a device, "on", "off"
    property bool on: false

    signal toggled()

    implicitHeight: column.implicitHeight

    activeFocusOnTab: true
    Keys.onPressed: event => {
        if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter || event.key === Qt.Key_Space) root.toggled()
        else if (event.key === Qt.Key_Left || event.key === Qt.Key_Right) {
            const next = root.nextItemInFocusChain(event.key === Qt.Key_Right)
            if (next) next.forceActiveFocus()
        }
        else return
        event.accepted = true
    }

    Column {
        id: column
        width: parent.width
        spacing: 6

        Rectangle {
            id: circle
            anchors.horizontalCenter: parent.horizontalCenter
            width: 46
            height: 46
            radius: height / 2
            color: root.on ? Theme.accent : (area.containsMouse ? Theme.hover : Theme.clear)
            border.width: root.on ? 0 : 1
            border.color: Theme.border
            Behavior on color { ColorAnimation { duration: Theme.durFast } }

            StyledText {
                anchors.centerIn: parent
                text: root.glyph
                color: root.on ? Theme.bg : Theme.text
                font.pixelSize: Theme.fontLarge
                Behavior on color { ColorAnimation { duration: Theme.durFast } }
            }

            FocusRing { visible: root.activeFocus; radius: circle.radius + 3; anchors.margins: -3 }
        }

        StyledText {
            width: parent.width
            horizontalAlignment: Text.AlignHCenter
            text: root.label
            color: root.on ? Theme.bright : Theme.text
            font.pixelSize: Theme.fontSmall
            elide: Text.ElideRight
        }
        StyledText {
            width: parent.width
            horizontalAlignment: Text.AlignHCenter
            text: root.status
            color: Theme.dim
            font.pixelSize: Theme.fontSmall
            elide: Text.ElideRight
        }
    }

    MouseArea {
        id: area
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.toggled()
    }
}
