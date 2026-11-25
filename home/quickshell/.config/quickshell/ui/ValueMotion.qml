import QtQuick
import qs

// A fill or knob that shows a value (sliders, the OSD bar, meters): never overshoots past the value.
// Use as a Behavior:  ValueMotion on x {}   (set epsilon: Theme.epsNorm for 0..1 values, Theme.epsPx for pixels).
// Turn it off with `active: false` rather than `enabled`: the preset also turns itself off for Theme.reduceMotion.
Behavior {
    property bool active: true
    property alias epsilon: spring.epsilon
    enabled: active && !Theme.reduceMotion
    SpringAnimation { id: spring; spring: Theme.springValue; damping: Theme.dampingValue; epsilon: Theme.epsPx }
}
