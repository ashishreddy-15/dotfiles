import QtQuick
import Quickshell
import qs

StyledText {
    font.pixelSize: Theme.barFontSize
    text: Qt.formatDateTime(clock.date, "ddd d MMM   HH:mm")

    SystemClock {
        id: clock
        precision: SystemClock.Minutes   // wake up once a minute, not every second
    }
}
