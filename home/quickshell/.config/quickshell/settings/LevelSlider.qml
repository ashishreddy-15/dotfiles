import QtQuick
import qs
import "../ui"
import "../panel"

// A level (volume, brightness, warmth): a slider and its value.   LevelSlider { value: 0.4; onMoved: v => ... }
// Left / Right nudge it by 5% from the keyboard.
Item {
    id: root

    property real value: 0                       // 0..1
    property bool muted: false
    property string valueText: Math.round(value * 100) + "%"
    property int trackWidth: 200
    property int textWidth: 56

    signal moved(real value)

    implicitWidth: trackWidth + 14 + textWidth
    implicitHeight: 32

    activeFocusOnTab: true
    Keys.onPressed: event => {
        if (event.key === Qt.Key_Left) root.moved(Math.max(0, root.value - 0.05))
        else if (event.key === Qt.Key_Right) root.moved(Math.min(1, root.value + 0.05))
        else return
        event.accepted = true
    }

    Slider {
        width: root.trackWidth
        height: parent.height
        value: root.value
        muted: root.muted
        onMoved: v => root.moved(v)
    }
    StyledText {
        x: root.trackWidth + 14
        width: root.textWidth
        height: parent.height
        horizontalAlignment: Text.AlignRight
        text: root.valueText
    }

    FocusRing { visible: root.activeFocus; anchors.margins: -3 }
}
