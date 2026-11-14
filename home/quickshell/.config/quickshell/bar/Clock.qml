import QtQuick
import Quickshell
import qs

// The clock: a short, dim date and the time in the bright colour, a little heavier. The gap between them is smaller
// than the gaps between bar items, so the two read as one thing.
Row {
    spacing: 6

    SystemClock {
        id: clock
        precision: SystemClock.Minutes   // wake up once a minute, not every second
    }

    BarText {
        anchors.verticalCenter: parent.verticalCenter
        text: Qt.formatDateTime(clock.date, "ddd d")
        color: Theme.barDim
    }
    BarText {
        anchors.verticalCenter: parent.verticalCenter
        text: Qt.formatDateTime(clock.date, "HH:mm")
        color: Theme.barBright
        font.weight: Theme.barFontWeightStrong
    }
}
