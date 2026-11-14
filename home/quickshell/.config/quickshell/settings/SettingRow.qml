import QtQuick
import qs

// One setting in the appearance window: the name and a short explanation on the left, the control on the right.
//   SettingRow { title: "Icon theme"; description: "..."; Segmented { ... } }
Item {
    id: root

    property string title
    property string description
    default property alias control: slot.data

    width: parent.width
    height: Math.max(56, textColumn.implicitHeight + 24)

    Column {
        id: textColumn
        anchors { left: parent.left; right: slot.left; rightMargin: 24; verticalCenter: parent.verticalCenter }
        spacing: 2

        StyledText {
            width: parent.width
            text: root.title
            color: Theme.bright
            elide: Text.ElideRight
        }
        StyledText {
            visible: root.description !== ""
            width: parent.width
            text: root.description
            color: Theme.dim
            font.pixelSize: Theme.fontSmall
            wrapMode: Text.Wrap
        }
    }

    // The control, a little in from the right edge, so its keyboard focus ring (drawn just outside it) is not cut off.
    Item {
        id: slot
        anchors { right: parent.right; rightMargin: 10; verticalCenter: parent.verticalCenter }
        width: childrenRect.width
        height: childrenRect.height
    }

    Rectangle {
        anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
        height: 1
        color: Theme.border
    }
}
