import QtQuick
import Quickshell
import Quickshell.Services.UPower
import qs
import "../ui"

// A battery icon, always there on a laptop (dim while all is well), with the percentage beside it. The percentage
// can be switched off in Settings > Power, and then only shows when it matters: at 30% or less, and while charging. Amber at 20%, red at 10%, green while charging.
// The bar shows it only on a laptop (`present`), through a Reveal (Bar.qml); the percentage reveals itself too.
Row {
    id: root

    readonly property var dev: UPower.displayDevice
    readonly property bool present: dev?.isLaptopBattery ?? false
    readonly property int percent: Math.round((dev?.percentage ?? 0) * 100)
    readonly property bool charging: dev?.state === UPowerDeviceState.Charging
    readonly property bool full: dev?.state === UPowerDeviceState.FullyCharged
    readonly property bool showPercent: Modes.batteryPercent || percent <= 30 || charging

    readonly property color tone: charging || full ? Theme.barOk
                                : percent <= 10 ? Theme.barErr
                                : percent <= 20 ? Theme.barWarn
                                : Theme.barDim

    // Font Awesome battery-empty ... battery-full, by quarters
    readonly property var levels: ["", "", "", "", ""]

    BarText {
        anchors.verticalCenter: parent.verticalCenter
        text: levels[Math.min(4, Math.round(percent / 25))]
        color: parent.tone
    }
    // The 5 px gap to the icon is inside the reveal, so plugging in glides the percentage in.
    Reveal {
        anchors.verticalCenter: parent.verticalCenter
        shown: root.showPercent
        gapBefore: Theme.barGapTight
        BarText {
            text: root.percent + "%" + (root.charging ? "+" : "")
            color: root.charging || root.full ? Theme.barOk
                 : root.percent <= 10 ? Theme.barErr
                 : root.percent <= 20 ? Theme.barWarn
                 : Theme.barText
        }
    }
}
