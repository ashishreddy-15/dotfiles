import QtQuick
import qs

// The press-in scale of a button or tile (Theme.pressScale). The one spring allowed a small bounce.
// Use as a Behavior:  PressMotion on scale {}   (set epsilon: Theme.epsNorm for 0..1 values, Theme.epsPx for pixels).
// Turn it off with `active: false` rather than `enabled`: the preset also turns itself off for Theme.reduceMotion.
Behavior {
    property bool active: true
    property alias epsilon: spring.epsilon
    enabled: active && !Theme.reduceMotion
    SpringAnimation { id: spring; spring: Theme.springPress; damping: Theme.dampingPress; epsilon: Theme.epsNorm }
}
