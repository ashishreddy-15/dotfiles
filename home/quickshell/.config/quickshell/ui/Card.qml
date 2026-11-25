import QtQuick
import QtQuick.Effects
import qs

// The one card every floating piece (panel, pickers, indicator) is built from, so they look and move alike:
//   - a frosted, slightly see-through surface with a hairline border and rounded corners
//   - a soft shadow underneath
//   - the shared enter/exit animation (fade, slight zoom, short slide) and a smooth height change
//
// Use it inside a fixed-size window that leaves Theme.shadowMargin free on every side, put the card at
// (shadowMargin, shadowMargin), set `width`, bind `contentHeight` to the content's natural height, and put
// the content inside. The window must stay mapped until `shown` is back to 0.
Item {
    id: root

    property bool open: false
    property real contentHeight: 0           // natural height of the content; the card animates to it
    property real maxHeight: 100000
    property int origin: Item.Top            // which edge the zoom grows from
    property alias radius: surface.radius
    default property alias content: surface.data

    // 0 = hidden, 1 = fully shown
    property real shown: open ? 1 : 0
    Behavior on shown { NumberAnimation { duration: root.open ? Theme.durBase : Theme.durFast; easing.type: Theme.easeOut } }

    // 0 = shrunk and raised, 1 = in place: drives the zoom and the short slide.
    // Entering uses a spring, so an open that interrupts a close carries on smoothly. Leaving uses the fade's own
    // duration and curve, so the card visibly shrinks while it fades. (An over-damped spring took ~580 ms and had
    // barely moved by the time the 90 ms fade had hidden the card: the exit read as a plain fade.)
    property real spatial: 0
    Component.onCompleted: spatial = open ? 1 : 0
    onOpenChanged: {
        if (open) { spatialOut.stop(); spatialIn.restart() }
        else { spatialIn.stop(); spatialOut.restart() }
    }
    SpringAnimation { id: spatialIn; target: root; property: "spatial"; to: 1; spring: Theme.springSmooth; damping: Theme.dampingSmooth; epsilon: Theme.epsNorm }
    NumberAnimation { id: spatialOut; target: root; property: "spatial"; to: 0; duration: Theme.durFast; easing.type: Theme.easeOut }

    height: Math.min(contentHeight, maxHeight)
    Behavior on height { SpringAnimation { spring: Theme.springSmooth; damping: Theme.dampingSmooth; epsilon: Theme.epsPx } }

    opacity: shown
    scale: 0.95 + 0.05 * spatial
    transformOrigin: root.origin
    transform: Translate { y: (1 - root.spatial) * (root.origin === Item.Bottom ? 8 : -8) }

    RectangularShadow {
        anchors.fill: parent
        radius: surface.radius
        blur: Theme.shadowBlur
        offset: Qt.vector2d(0, Theme.shadowOffset)
        color: Theme.shadow
    }

    Rectangle {
        id: surface
        anchors.fill: parent
        radius: Theme.radiusCard
        color: Theme.card
        border.width: 1
        border.color: Theme.border
        clip: true                           // rows are revealed as the card grows
    }
}
