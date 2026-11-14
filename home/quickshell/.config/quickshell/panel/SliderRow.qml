import QtQuick
import qs

// label | slider | value. Optionally the label is a button (volume: click to mute).
Item {
    id: root

    property string label
    property real value: 0                       // 0..1
    property bool muted: false
    property string valueText: Math.round(value * 100) + "%"
    property bool labelClickable: false
    property color labelColor: Theme.dim

    signal moved(real value)
    signal labelClicked()

    width: parent.width
    height: 32

    MouseArea {
        width: Theme.valueX
        height: parent.height
        enabled: root.labelClickable
        hoverEnabled: true
        cursorShape: root.labelClickable ? Qt.PointingHandCursor : Qt.ArrowCursor
        onClicked: root.labelClicked()

        StyledText {
            x: 10
            anchors.verticalCenter: parent.verticalCenter
            text: root.label
            color: root.labelColor
        }
    }
    Slider {
        x: Theme.valueX
        width: parent.width - Theme.valueX - 54
        height: parent.height
        value: root.value
        muted: root.muted
        onMoved: v => root.moved(v)
    }
    StyledText {
        anchors { right: parent.right; rightMargin: 10; verticalCenter: parent.verticalCenter }
        text: root.valueText
        color: root.muted ? Theme.dim : Theme.text
    }
}
