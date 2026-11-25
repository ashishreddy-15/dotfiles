import QtQuick
import Quickshell
import Quickshell.Wayland
import qs

// Notification pop-ups: a stack of cards under the bar, top-centre of the main screen, newest on top.
// The data (and the D-Bus server) live in Notifs.qml. This file is only the window and the stack.
//
// Like the other floating pieces, the window has a fixed size with room for the cards' shadows; the cards
// move inside it. New cards fade and zoom in, leaving ones fade out, and the rest slide to re-stack.
Scope {
    id: root

    readonly property int cardWidth: 400
    readonly property int gap: 8
    readonly property int cardMaxHeight: 150
    // Room for the most cards we ever show, each as tall as allowed.
    readonly property int stackMax: Notifs.maxPopups * cardMaxHeight + (Notifs.maxPopups - 1) * gap

    // Stay mapped a moment after the last card is gone, so its exit animation can finish.
    Timer { id: linger; interval: 350 }
    Connections {
        target: Notifs.popups
        function onCountChanged() { linger.restart() }
    }

    LazyLoader {
        id: loader
        active: Notifs.popups.count > 0 || linger.running

        PanelWindow {
            id: win

            screen: ShellState.mainScreen
            visible: Notifs.popups.count > 0 || linger.running

            readonly property int wantedTop: Theme.barHeight + 4
            anchors.top: true                                    // top only = horizontally centred
            margins.top: Math.max(0, wantedTop - Theme.shadowMargin)
            exclusionMode: ExclusionMode.Ignore
            implicitWidth: root.cardWidth + 2 * Theme.shadowMargin
            implicitHeight: wantedTop + root.stackMax + Theme.shadowMargin
            color: "transparent"
            mask: Region { item: hitArea }                       // only the cards take clicks
            WlrLayershell.namespace: "quickshell-notifications"
            WlrLayershell.layer: WlrLayer.Overlay

            // The clickable part: the cards' current extent (the list itself is always full height, see below).
            Item {
                id: hitArea
                x: list.x
                y: list.y
                width: list.width
                height: Math.min(list.contentHeight, root.stackMax)
            }

            ListView {
                id: list
                x: Theme.shadowMargin
                y: win.wantedTop - win.margins.top
                width: root.cardWidth
                // Full height, never min(contentHeight, ...): a list that shrank the moment a card was removed dropped
                // that card at once (no exit) and blanked the stack for a frame when the rest started to move.
                height: root.stackMax
                interactive: false
                spacing: root.gap
                model: Notifs.popups
                delegate: NotificationCard {}

                add: Transition {
                    ParallelAnimation {
                        NumberAnimation { property: "opacity"; from: 0; to: 1; duration: Theme.durBase; easing.type: Theme.easeOut }
                        SpringAnimation { property: "scale"; from: Theme.reduceMotion ? 1 : 0.95; to: 1; spring: Theme.springSmooth; damping: Theme.dampingSmooth; epsilon: Theme.epsNorm }
                    }
                }
                // A dismissed card fades, shrinks a little and drifts aside; only then does the stack close the gap
                // (removeDisplaced waits durFast), so the cards below never slide through one that is still fading.
                remove: Transition {
                    ParallelAnimation {
                        NumberAnimation { property: "opacity"; to: 0; duration: Theme.durFast; easing.type: Theme.easeOut }
                        NumberAnimation { property: "scale"; to: Theme.reduceMotion ? 1 : 0.97; duration: Theme.durFast; easing.type: Theme.easeOut }
                        NumberAnimation { property: "x"; to: Theme.reduceMotion ? 0 : Theme.exitDrift; duration: Theme.durFast; easing.type: Theme.easeOut }
                    }
                }
                // Reduce motion: no transition at all, so the rest of the stack moves at once. (Transition.enabled is
                // not honoured by a ListView's view transitions; only taking the transition away works.)
                removeDisplaced: Theme.reduceMotion ? null : closeUp
                displaced: Theme.reduceMotion ? null : restack
                Transition {
                    id: closeUp
                    SequentialAnimation {
                        PauseAnimation { duration: Theme.durFast }
                        SpringAnimation { properties: "y"; spring: Theme.springSmooth; damping: Theme.dampingSmooth; epsilon: Theme.epsPx }
                    }
                }
                Transition {
                    id: restack
                    SpringAnimation { properties: "y"; spring: Theme.springSmooth; damping: Theme.dampingSmooth; epsilon: Theme.epsPx }
                }
            }
        }
    }
}
