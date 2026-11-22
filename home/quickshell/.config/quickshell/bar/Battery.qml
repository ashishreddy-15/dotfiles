import QtQuick
import Quickshell
import Quickshell.Services.UPower
import qs

// A battery icon, always there on a laptop (dim while all is well), with the percentage beside it. The percentage
// can be switched off in Settings > Power, and then only shows when it matters: at 30% or less, and while charging. Amber at 20%, red at 10%, green while charging.
Row {
    readonly property var dev: UPower.displayDevice
    readonly property bool present: dev?.isLaptopBattery ?? false
    readonly property int percent: Math.round((dev?.percentage ?? 0) * 100)
    readonly property bool charging: dev?.state === UPowerDeviceState.Charging
    readonly property bool full: dev?.state === UPowerDeviceState.FullyCharged
    readonly property bool showPercent: Modes.batteryPercent || percent <= 30 || charging

    visible: present
    spacing: 5

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
    BarText {
        anchors.verticalCenter: parent.verticalCenter
        visible: parent.showPercent
        text: percent + "%" + (charging ? "+" : "")
        color: parent.charging || parent.full ? Theme.barOk
             : parent.percent <= 10 ? Theme.barErr
             : parent.percent <= 20 ? Theme.barWarn
             : Theme.barText
    }
}
