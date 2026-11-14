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

    Rectangle {
        anchors.fill: parent
        radius: Theme.radiusRow
        color: root.active ? Qt.alpha(Theme.accent, area.containsMouse ? 0.40 : 0.30)
                           : (area.containsMouse ? Theme.selected : Theme.hover)
        Behavior on color { ColorAnimation { duration: Theme.durFast } }
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
            color: root.active ? Theme.text : Theme.dim
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
}
