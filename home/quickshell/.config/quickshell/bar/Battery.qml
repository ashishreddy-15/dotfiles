import QtQuick
import Quickshell
import Quickshell.Services.UPower
import qs

// "bat 84%", with "+" while charging. Amber at 20%, red at 10%.
// Quiet: shown at 30% or less, and while charging.
StatusItem {
    readonly property var dev: UPower.displayDevice
    readonly property int percent: Math.round((dev?.percentage ?? 0) * 100)
    readonly property bool charging: dev?.state === UPowerDeviceState.Charging
    readonly property bool full: dev?.state === UPowerDeviceState.FullyCharged

    attention: (dev?.isLaptopBattery ?? false) && (percent <= 30 || charging)
    label: "bat"
    value: percent + "%" + (charging ? "+" : "")
    valueColor: charging || full ? Theme.barOk
              : percent <= 10 ? Theme.barErr
              : percent <= 20 ? Theme.barWarn
              : Theme.barText
}
