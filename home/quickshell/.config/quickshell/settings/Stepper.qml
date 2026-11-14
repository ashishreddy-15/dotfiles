import QtQuick
import qs
import "../ui"

// A number with minus and plus buttons:   -   10 pt   +      (Left / Right change it from the keyboard)
Item {
    id: root

    property int value: 0
    property int from: 0
    property int to: 100
    property int step: 1
    property string suffix: ""
    signal changed(int value)

    implicitWidth: row.implicitWidth
    implicitHeight: row.implicitHeight

    function less() { if (value > from) changed(Math.max(from, value - step)) }
    function more() { if (value < to) changed(Math.min(to, value + step)) }

    activeFocusOnTab: true
    Keys.onPressed: event => {
        if (event.key === Qt.Key_Left) root.less()
        else if (event.key === Qt.Key_Right) root.more()
        else return
        event.accepted = true
    }

    component Button: Rectangle {
        id: btn
        property string glyph
        property bool active: true
        signal clicked()

        width: 32
        height: 32
        radius: Theme.radiusRow
        color: area.containsMouse && active ? Theme.hover : Theme.clear
        border.width: 1
        border.color: Theme.border
        Behavior on color { ColorAnimation { duration: Theme.durFast } }

        StyledText {
            anchors.centerIn: parent
            text: btn.glyph
            color: btn.active ? Theme.text : Theme.dim
        }
        MouseArea {
            id: area
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: btn.active ? Qt.PointingHandCursor : Qt.ArrowCursor
            onClicked: if (btn.active) btn.clicked()
        }
    }

    Row {
        id: row
        spacing: 4

        Button { glyph: Theme.glyphMinus; active: root.value > root.from; onClicked: root.less() }
        StyledText {
            width: 64
            height: 32
            horizontalAlignment: Text.AlignHCenter
            text: root.value + root.suffix
            color: Theme.bright
        }
        Button { glyph: Theme.glyphPlus; active: root.value < root.to; onClicked: root.more() }
    }

    FocusRing { visible: root.activeFocus; anchors.margins: -3 }
}
