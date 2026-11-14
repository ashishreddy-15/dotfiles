import QtQuick
import qs

// A toggle tile (Wi-Fi, Bluetooth, ...): a label, a line of state, and a fill when it is on.
//   click the tile      toggles it                (or opens its page, if `toggle` is false)
//   click the arrow     opens its detail page     (only when `hasDetail`)
Item {
    id: root

    property string label
    property string value
    property bool active: false          // on: the tile is filled with the accent
    property bool toggle: true           // false: the whole tile opens the detail page instead
    property bool hasDetail: false

    signal toggled()
    signal detail()

    height: 52

    // Keyboard: Enter or Space toggles (or opens the page, for tiles that only open one); Right opens the details.
    activeFocusOnTab: true
    Keys.onPressed: event => {
        if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter || event.key === Qt.Key_Space) { root.toggle ? root.toggled() : root.detail(); event.accepted = true }
        else if (event.key === Qt.Key_Right && root.hasDetail) { root.detail(); event.accepted = true }
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
            radius: 1
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
        onClicked: root.toggle ? root.toggled() : root.detail()
    }

    Column {
        anchors { left: parent.left; right: arrow.left; verticalCenter: parent.verticalCenter; leftMargin: 12; rightMargin: 4 }
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

    // The arrow has its own click, so it can sit on top of the tile's.
    Item {
        id: arrow
        visible: root.hasDetail
        anchors { right: parent.right; top: parent.top; bottom: parent.bottom }
        width: root.hasDetail ? 30 : 0

        StyledText {
            anchors.centerIn: parent
            text: "›"
            color: root.active ? Theme.text : Theme.dim
        }
        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: root.detail()
        }
    }

    FocusRing { visible: root.activeFocus }
}
