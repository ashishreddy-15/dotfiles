import QtQuick
import qs

// The keyboard focus mark: an accent outline around the control that has focus.
// Put it inside a control and set `shown: root.activeFocus`: it fades in and out (durFast) instead of popping.
// (The older `visible: root.activeFocus` still works, without the fade: `shown` stays true and `visible` wins.)
Rectangle {
    property bool shown: true

    anchors.fill: parent
    radius: Theme.radiusRow
    color: "transparent"
    border.width: 1
    border.color: Theme.accent
    z: 10

    opacity: shown ? 1 : 0
    visible: opacity > 0                     // nothing to draw once faded out
    Behavior on opacity { NumberAnimation { duration: Theme.durFast; easing.type: Theme.easeOut } }
}
