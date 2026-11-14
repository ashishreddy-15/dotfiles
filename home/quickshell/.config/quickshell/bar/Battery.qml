import QtQuick
import Quickshell
import Quickshell.Services.UPower
import qs

// "bat 84%", with "+" while charging. Turns amber at 20%, red at 10%. Hidden on machines without a battery.
StatusItem {
    readonly property var dev: UPower.displayDevice
    readonly property int percent: Math.round((dev?.percentage ?? 0) * 100)
    readonly property bool charging: dev?.state === UPowerDeviceState.Charging
    readonly property bool full: dev?.state === UPowerDeviceState.FullyCharged

    visible: dev?.isLaptopBattery ?? false
    label: "bat"
    value: percent + "%" + (charging ? "+" : "")
    valueColor: charging || full ? Theme.ok
              : percent <= 10 ? Theme.err
              : percent <= 20 ? Theme.warn
              : Theme.text
}
