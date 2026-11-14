import QtQuick
import Quickshell
import Quickshell.Services.UPower
import qs

// Power: the power profile, and the battery (charge, state, time left, draw, energy, health).
// A warning shows when the system is holding "performance" back (lap detected, high temperature).
Page {
    id: root

    readonly property var dev: UPower.displayDevice
    readonly property bool hasBattery: dev?.isLaptopBattery ?? false
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
        case UPowerDeviceState.Charging:      return "Charging"
        case UPowerDeviceState.FullyCharged:  return "Full"
        case UPowerDeviceState.PendingCharge: return "Plugged in, not charging"
        case UPowerDeviceState.Empty:         return "Empty"
        default:                              return "On battery"
        }
    }
    function timeText() {
        if (charging && (dev?.timeToFull ?? 0) > 0) return fmtTime(dev.timeToFull) + " until full"
        if (!charging && !notCharging && !full && (dev?.timeToEmpty ?? 0) > 0) return fmtTime(dev.timeToEmpty) + " left"
        return "-"
    }
    function levelColor() {
        return charging || full || notCharging ? Theme.ok : percent <= 10 ? Theme.err : percent <= 20 ? Theme.warn : Theme.text
    }

    // Set when the system is holding the performance profile back; "" otherwise.
    readonly property string degraded: PowerProfiles.profile !== PowerProfile.Performance ? ""
        : PowerProfiles.degradationReason === PerformanceDegradationReason.LapDetected ? "Performance is limited: the laptop is on your lap."
        : PowerProfiles.degradationReason === PerformanceDegradationReason.HighTemperature ? "Performance is limited: the system is too hot." : ""

    readonly property var profiles: [
        { label: "power saver", value: PowerProfile.PowerSaver },
        { label: "balanced",    value: PowerProfile.Balanced },
        { label: "performance", value: PowerProfile.Performance }
    ].filter(p => p.value !== PowerProfile.Performance || PowerProfiles.hasPerformanceProfile)

    SettingRow {
        title: "Power profile"
        description: root.degraded !== "" ? root.degraded : "Power saver lasts longest; performance is fastest and uses more power."
        Segmented {
            options: root.profiles
            value: PowerProfiles.profile
            onPicked: v => PowerProfiles.profile = v
        }
    }

    GroupLabel { visible: root.hasBattery; text: "Battery" }

    component Fact: SettingRow {
        id: fact
        property string text
        property color color: Theme.text
        visible: root.hasBattery
        height: visible ? 48 : 0
        StyledText { text: fact.text; color: fact.color }
    }
    Fact { title: "Charge"; text: root.percent + "%"; color: root.levelColor() }
    Fact { title: "State"; text: root.stateText() }
    Fact { title: "Time"; text: root.timeText() }
    Fact {
        visible: root.hasBattery && Math.abs(root.dev?.changeRate ?? 0) >= 0.1
        title: root.charging ? "Charging at" : "Using"
        text: Math.abs(root.dev?.changeRate ?? 0).toFixed(1) + " W"
    }
    Fact {
        visible: root.hasBattery && (root.dev?.energyCapacity ?? 0) > 0
        title: "Energy"
        text: (root.dev?.energy ?? 0).toFixed(1) + " / " + (root.dev?.energyCapacity ?? 0).toFixed(1) + " Wh"
    }
    Fact {
        visible: root.hasBattery && (root.dev?.healthSupported ?? false)
        title: "Health"
        text: Math.round(root.dev?.healthPercentage ?? 0) + "%"
    }
}
