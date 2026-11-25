import QtQuick
import qs

// Follows a selection: list and grid highlights, segmented pills, switch thumbs, the workspace brackets.
// Use as a Behavior:  HighlightMotion on x {}   (set epsilon: Theme.epsNorm for 0..1 values, Theme.epsPx for pixels).
// Turn it off with `active: false` rather than `enabled`, so the shell-wide switches can still apply.
Behavior {
    property bool active: true
    property alias epsilon: spring.epsilon
    enabled: active
    SpringAnimation { id: spring; spring: Theme.springHighlight; damping: Theme.dampingHighlight; epsilon: Theme.epsPx }
}
