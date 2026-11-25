import QtQuick
import qs

// Follows a selection: list and grid highlights, segmented pills, switch thumbs, the workspace brackets.
// Use as a Behavior:  HighlightMotion on x {}   (set epsilon: Theme.epsNorm for 0..1 values, Theme.epsPx for pixels).
// Turn it off with `active: false` rather than `enabled`: the preset also turns itself off for Theme.reduceMotion.
Behavior {
    property bool active: true
    property alias epsilon: spring.epsilon
    enabled: active && !Theme.reduceMotion
    SpringAnimation { id: spring; spring: Theme.springHighlight; damping: Theme.dampingHighlight; epsilon: Theme.epsPx }
}
