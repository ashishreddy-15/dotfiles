import QtQuick
import qs

// A read-only row:  label | value. Same grid as Line (label column, then the value), but no hover and no arrow.
Item {
    id: root

    property string label
    property string value
    property color valueColor: Theme.text

    width: parent.width
    height: 28

    StyledText {
        x: 10
        width: Theme.labelWidth
        anchors.verticalCenter: parent.verticalCenter
        text: root.label
        color: Theme.dim
    }
    StyledText {
        x: Theme.valueX
        width: parent.width - Theme.valueX - 12
        anchors.verticalCenter: parent.verticalCenter
        text: root.value
        color: root.valueColor
        elide: Text.ElideRight
    }
}
