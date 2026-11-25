import QtQuick
import qs

// Cards and stacks: a card's height, re-stacking.
// Use as a Behavior:  SmoothMotion on x {}   (set epsilon: Theme.epsNorm for 0..1 values, Theme.epsPx for pixels).
// Turn it off with `active: false` rather than `enabled`, so the shell-wide switches can still apply.
Behavior {
    property bool active: true
    property alias epsilon: spring.epsilon
    enabled: active
    SpringAnimation { id: spring; spring: Theme.springSmooth; damping: Theme.dampingSmooth; epsilon: Theme.epsPx }
}
