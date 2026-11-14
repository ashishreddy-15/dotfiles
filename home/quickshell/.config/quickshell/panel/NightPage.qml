import QtQuick
import Quickshell
import qs

// Night light: how warm the screen colour gets (hyprsunset), and the switch.
Column {
    id: root

    signal back()

    PageHeader {
        title: "Night light"
        switchText: Modes.nightLight ? "on" : "off"
        switchColor: Modes.nightLight ? Theme.ok : Theme.dim
        onBack: root.back()
        onSwitched: Modes.toggleNight()
    }

    // Right = warmer (lower kelvin).
    SliderRow {
        label: "warmth"
        value: (Modes.kelvinMax - Modes.kelvin) / (Modes.kelvinMax - Modes.kelvinMin)
        valueText: Modes.kelvin + " K"
        onMoved: v => Modes.setWarmth(Modes.kelvinMax - v * (Modes.kelvinMax - Modes.kelvinMin))
    }

    StyledText {
        width: parent.width
        leftPadding: 10
        rightPadding: 10
        topPadding: 6
        bottomPadding: 6
        text: "Makes the screen warmer so it is easier on the eyes at night."
        color: Theme.dim
        font.pixelSize: Theme.fontSmall
        wrapMode: Text.Wrap
    }
}
