import QtQuick
import qs

// The keyboard focus mark: an accent outline around the control that has focus.
// Put it inside a control and set `visible: root.activeFocus`.
Rectangle {
    anchors.fill: parent
    radius: Theme.radiusRow
    color: "transparent"
    border.width: 1
    border.color: Theme.accent
    z: 10
}
