import QtQuick
import qs

// A fill or knob that shows a value (sliders, the OSD bar, meters): never overshoots past the value.
// Use as a Behavior:  ValueMotion on x {}   (set epsilon: Theme.epsNorm for 0..1 values, Theme.epsPx for pixels).
// Turn it off with `active: false` rather than `enabled`, so the shell-wide switches can still apply.
Behavior {
    property bool active: true
    property alias epsilon: spring.epsilon
    enabled: active
    SpringAnimation { id: spring; spring: Theme.springValue; damping: Theme.dampingValue; epsilon: Theme.epsPx }
}
