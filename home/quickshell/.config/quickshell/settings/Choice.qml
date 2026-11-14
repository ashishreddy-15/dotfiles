import QtQuick
import qs
import "../ui"

// One choice out of a list, stepped through:   ‹  Undo  ›     (for lists too long for a Segmented)
//   Choice { options: [{ label, value }, ...]; value: current; onPicked: v => ... }
// Click the arrows, or Left / Right from the keyboard. It wraps around at the ends.
Item {
    id: root

    property var options: []
    property var value
    signal picked(var value)

    readonly property int currentIndex: Math.max(0, options.findIndex(o => o.value === value))
    function step(by) {
        if (options.length > 0) picked(options[(currentIndex + by + options.length) % options.length].value)
    }

    implicitWidth: row.implicitWidth
    implicitHeight: row.implicitHeight

    activeFocusOnTab: true
    Keys.onPressed: event => {
        if (event.key === Qt.Key_Left) root.step(-1)
        else if (event.key === Qt.Key_Right) root.step(1)
        else return
        event.accepted = true
    }

    component Arrow: Rectangle {
        id: arrow
        property string glyph
        signal clicked()
        width: 30
        height: 32
        radius: Theme.radiusRow
        color: area.containsMouse ? Theme.hover : Theme.clear
        Behavior on color { ColorAnimation { duration: Theme.durFast } }
        StyledText { anchors.centerIn: parent; text: arrow.glyph; color: Theme.text }
        MouseArea { id: area; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: arrow.clicked() }
    }

    Row {
        id: row
        Arrow { glyph: Theme.glyphBack; onClicked: root.step(-1) }
        StyledText {
            width: 150
            height: 32
            horizontalAlignment: Text.AlignHCenter
            text: root.options.length > 0 ? root.options[root.currentIndex].label : ""
            color: Theme.bright
            elide: Text.ElideRight
        }
        Arrow { glyph: Theme.glyphNext; onClicked: root.step(1) }
    }

    FocusRing { visible: root.activeFocus; anchors.margins: -3 }
}
