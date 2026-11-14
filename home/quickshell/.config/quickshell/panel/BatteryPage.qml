import QtQuick
import Quickshell
import Quickshell.Services.UPower
import qs

// Battery: charge, state, time left, power draw and health. Also where the power profile is shown, with a
// warning when the system is holding "performance" back (lap detected, high temperature).
Column {
    id: root

    signal back()
    signal open(string page)

    readonly property var dev: UPower.displayDevice
    readonly property int percent: Math.round((dev?.percentage ?? 0) * 100)
    readonly property bool charging: dev?.state === UPowerDeviceState.Charging
    readonly property bool notCharging: dev?.state === UPowerDeviceState.PendingCharge
    readonly property bool full: dev?.state === UPowerDeviceState.FullyCharged

    function fmtTime(seconds) {
        const h = Math.floor(seconds / 3600), m = Math.floor((seconds % 3600) / 60)
        return h > 0 ? h + "h " + m + "m" : m + "m"
    }
    function stateText() {
        switch (dev?.state) {
        case UPowerDeviceState.Charging:      return "charging"
        case UPowerDeviceState.FullyCharged:  return "full"
        case UPowerDeviceState.PendingCharge: return "plugged in, not charging"
        case UPowerDeviceState.Empty:         return "empty"
        default:                              return "on battery"
        }
    }
    function timeText() {
        if (charging && (dev?.timeToFull ?? 0) > 0)  return fmtTime(dev.timeToFull) + " until full"
        if (!charging && !notCharging && !full && (dev?.timeToEmpty ?? 0) > 0) return fmtTime(dev.timeToEmpty) + " left"
        return "-"
    }
    function levelColor() {
        return charging || full || notCharging ? Theme.ok : percent <= 10 ? Theme.err : percent <= 20 ? Theme.warn : Theme.text
    }

    // Set when the system is holding the performance profile back; "" otherwise.
    readonly property string degraded: PowerProfiles.profile !== PowerProfile.Performance ? ""
        : PowerProfiles.degradationReason === PerformanceDegradationReason.LapDetected ? "limited: lap detected"
        : PowerProfiles.degradationReason === PerformanceDegradationReason.HighTemperature ? "limited: high temperature" : ""
    function profileName() {
        return PowerProfiles.profile === PowerProfile.PowerSaver ? "power saver"
             : PowerProfiles.profile === PowerProfile.Performance ? "performance" : "balanced"
    }

    PageHeader { title: "Battery"; onBack: root.back() }

    InfoRow { label: "charge"; value: root.percent + "%"; valueColor: root.levelColor() }
    InfoRow { label: "state";  value: root.stateText() }
    InfoRow { label: "time";   value: root.timeText() }
    InfoRow {
        visible: Math.abs(root.dev?.changeRate ?? 0) >= 0.1
        height: visible ? 28 : 0
        label: root.charging ? "charging at" : "using"
        value: Math.abs(root.dev.changeRate).toFixed(1) + " W"
    }
    InfoRow {
        visible: root.dev?.energyCapacity > 0
        height: visible ? 28 : 0
        label: "energy"
        value: (root.dev?.energy ?? 0).toFixed(1) + " / " + (root.dev?.energyCapacity ?? 0).toFixed(1) + " Wh"
    }
    InfoRow {
        visible: root.dev?.healthSupported ?? false
        height: visible ? 28 : 0
        label: "health"
        value: Math.round(root.dev?.healthPercentage ?? 0) + "%"
    }

    Line {
        label: "profile"
        value: root.profileName() + (root.degraded !== "" ? "  (" + root.degraded + ")" : "")
        valueColor: root.degraded !== "" ? Theme.warn : Theme.text
        onClicked: root.open("profile")
    }
}
