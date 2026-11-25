import QtQuick
import qs
import "../ui"

// A thick pill-shaped slider with its icon inside (brightness, volume, mic), like a phone's.
// The fill always covers at least the circle around the icon. The name sits at the right end and turns into the value
// while you hover, drag or focus it. Click or drag to set, scroll to nudge, Left / Right from the keyboard.
// With `iconClickable`, the icon is a button of its own (volume, mic: mute); Enter or Space presses it.
// `active: false` shows it greyed out with `label` as the explanation (a monitor that cannot be controlled).
Item {
    id: root

    property real value: 0                 // 0..1
    property bool muted: false
    property bool active: true
    property string glyph
    property string mutedGlyph: glyph
    property string label
    property string valueText: Math.round(clamp(value) * 100) + "%"
    property bool iconClickable: false

    signal moved(real value)
    signal iconClicked()

    width: parent.width
    height: 40

    function clamp(v) { return Math.max(0, Math.min(1, v)) }
    function valueAt(x) { return clamp((x - height / 2) / (width - height)) }
    readonly property bool showValue: active && (area.containsMouse || area.pressed || root.activeFocus)

    activeFocusOnTab: active
    Keys.onPressed: event => {
        if (event.key === Qt.Key_Left) root.moved(clamp(root.value - Theme.brightnessStep))
        else if (event.key === Qt.Key_Right) root.moved(clamp(root.value + Theme.brightnessStep))
        else if (root.iconClickable && (event.key === Qt.Key_Return || event.key === Qt.Key_Enter || event.key === Qt.Key_Space)) root.iconClicked()
        else return
        event.accepted = true
    }

    Rectangle {
        anchors.fill: parent
        radius: height / 2
        color: Theme.hover
    }
    Rectangle {
        height: parent.height
        radius: height / 2
        width: parent.height + root.clamp(root.active ? root.value : 0) * (parent.width - parent.height)
        color: root.muted || !root.active ? Theme.border : Theme.sliderFill
        ValueMotion on width { active: !area.pressed }
        Behavior on color { ColorAnimation { duration: Theme.durFast } }
    }

    StyledText {
        x: (parent.height - implicitWidth) / 2
        anchors.verticalCenter: parent.verticalCenter
        text: root.muted ? root.mutedGlyph : root.glyph
        color: root.active ? Theme.bright : Theme.dim
    }
    StyledText {
        anchors { right: parent.right; rightMargin: 16; verticalCenter: parent.verticalCenter }
        width: Math.min(implicitWidth, parent.width - parent.height - 24)
        horizontalAlignment: Text.AlignRight
        elide: Text.ElideRight
        text: root.showValue ? (root.muted ? "muted" : root.valueText) : root.label
        color: root.showValue ? Theme.bright : Theme.text
        font.pixelSize: Theme.fontSmall
    }

    // The icon's own button (mute), over the left circle.
    MouseArea {
        visible: root.iconClickable && root.active
        z: 1
        width: parent.height
        height: parent.height
        cursorShape: Qt.PointingHandCursor
        onClicked: root.iconClicked()
    }
    MouseArea {
        id: area
        anchors.fill: parent
        enabled: root.active
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onPressed: m => root.moved(root.valueAt(m.x))
        onPositionChanged: m => { if (pressed) root.moved(root.valueAt(m.x)) }
    }
    WheelHandler {
        enabled: root.active
        onWheel: e => root.moved(root.clamp(root.value + (e.angleDelta.y > 0 ? Theme.brightnessStep : -Theme.brightnessStep)))
    }

    FocusRing { shown: root.activeFocus; radius: root.height / 2 + 3; anchors.margins: -3 }
}
