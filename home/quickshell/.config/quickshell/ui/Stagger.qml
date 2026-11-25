import QtQuick
import qs

// The entrance of one row of a panel or list when it opens: the row fades in (durBase) and rises Theme.staggerRise
// px into place, a little after the row before it (min(order, staggerMax) * staggerStep ms). Put one inside the row
// and bind the row to it:
//   Stagger { id: enter; order: index; play: card.open; fresh: card.shown < 1 }
//   opacity: enter.progress
//   transform: Translate { y: enter.rise }
// It runs when `play` turns true. A row made while `play` is already true (a list being filtered, a recycled row)
// just shows, unless `fresh` says the surface is still opening (rows that arrive in the first frames of an open).
// Reduce motion: no stagger at all; the card's own fade is enough.
Item {
    id: root

    property int order: 0
    property bool play: false
    property bool fresh: false
    property bool fromHidden: true           // pass `card.shown === 0`: reopening a card that is still closing does not replay
    property real progress: 1                // 0 = not in yet, 1 = in place
    readonly property real rise: Theme.reduceMotion ? 0 : (1 - progress) * Theme.staggerRise

    visible: false                           // nothing to draw; also keeps positioners from laying it out

    function run() {
        anim.stop()
        if (Theme.reduceMotion) { progress = 1; return }
        progress = 0
        anim.start()
    }
    onPlayChanged: if (play && fromHidden) run()
    Component.onCompleted: if (play && fresh) run()

    SequentialAnimation {
        id: anim
        PauseAnimation { duration: Math.min(root.order, Theme.staggerMax) * Theme.staggerStep }
        NumberAnimation { target: root; property: "progress"; to: 1; duration: Theme.durBase; easing.type: Theme.easeOut }
    }
}
