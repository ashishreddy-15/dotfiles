import QtQuick
import qs

// Cards and stacks: a card's height, re-stacking.
// Use as a Behavior:  SmoothMotion on x {}   (set epsilon: Theme.epsNorm for 0..1 values, Theme.epsPx for pixels).
// Turn it off with `active: false` rather than `enabled`: the preset also turns itself off for Theme.reduceMotion.
Behavior {
    property bool active: true
    property alias epsilon: spring.epsilon
    enabled: active && !Theme.reduceMotion
    SpringAnimation { id: spring; spring: Theme.springSmooth; damping: Theme.dampingSmooth; epsilon: Theme.epsPx }
}
