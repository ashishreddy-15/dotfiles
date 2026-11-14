import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Networking
import Quickshell.Bluetooth
import Quickshell.Services.Pipewire
import Quickshell.Services.UPower
import qs

// The first page of the control center. Every control is one of four kinds, always in the same place:
//   tile    on/off things (Wi-Fi, Bluetooth), in the grid at the top; the arrow opens the details
//   slider  levels (brightness, volume), grouped under "display" and "sound"
//   row     things that open something (wallpaper picker, sound output page)
//   action  the power buttons in the footer
// Order, top to bottom: status header, tiles, display, sound, footer.
Column {
    id: root

    signal open(string page)     // go to a detail page
    signal done()                // close the panel

    spacing: 2

    // ---- state shown on this page ----
    readonly property var wifi: Networking.devices.values.find(d => d.type === DeviceType.Wifi) ?? null
    readonly property var wifiNetwork: wifi?.networks.values.find(n => n.connected) ?? null
    readonly property var btAdapter: Bluetooth.defaultAdapter
    readonly property bool btOn: btAdapter?.enabled ?? false
    readonly property var btConnected: Bluetooth.devices.values.filter(d => d.connected)

    readonly property var sink: Pipewire.defaultAudioSink
    readonly property bool muted: sink?.audio?.muted ?? false
    readonly property real volume: sink?.audio?.volume ?? 0
    PwObjectTracker { objects: [root.sink] }

    readonly property var battery: UPower.displayDevice
    readonly property bool hasBattery: battery?.isLaptopBattery ?? false

    function fmtTime(seconds) {
        const h = Math.floor(seconds / 3600), m = Math.floor((seconds % 3600) / 60)
        return h > 0 ? h + "h " + m + "m" : m + "m"
    }
    function batteryText() {
        const d = battery
        const pct = Math.round((d?.percentage ?? 0) * 100)
        switch (d?.state) {
        case UPowerDeviceState.Charging:      return pct + "%  charging"
        case UPowerDeviceState.FullyCharged:  return pct + "%  full"
        case UPowerDeviceState.PendingCharge: return pct + "%  plugged in"
        default: return pct + "%" + (d?.timeToEmpty > 0 ? "  " + fmtTime(d.timeToEmpty) : "")
        }
    }
    function batteryColor() {
        const d = battery
        const pct = Math.round((d?.percentage ?? 0) * 100)
        if (d?.state === UPowerDeviceState.Charging || d?.state === UPowerDeviceState.FullyCharged || d?.state === UPowerDeviceState.PendingCharge) return Theme.ok
        return pct <= 10 ? Theme.err : pct <= 20 ? Theme.warn : Theme.text
    }
    function profileName() {
        switch (PowerProfiles.profile) {
        case PowerProfile.PowerSaver:  return "power saver"
        case PowerProfile.Performance: return "performance"
        default:                       return "balanced"
        }
    }

    // External screens that are connected but have no brightness control, and why.
    readonly property var uncontrollable: Hyprland.monitors.values
        .map(m => m.name)
        .filter(n => !Brightness.isInternal(n) && !Brightness.displays.some(d => d.name === n))
    function brightnessReason() {
        switch (Brightness.ddcStatus) {
        case "unknown":     return "looking…"
        case "no-access":   return "no DDC access (see README)"
        case "unsupported": return "DDC/CI off or unsupported"
        case "missing":     return "ddcutil not installed"
        default:            return "not controllable"
        }
    }

    // ---- header: battery on the left, power profile on the right ----
    Item {
        width: parent.width
        height: 32

        StyledText {
            x: 10
            anchors.verticalCenter: parent.verticalCenter
            visible: root.hasBattery
            text: root.batteryText()
            color: root.batteryColor()
        }

        MouseArea {
            id: profileArea
            anchors { right: parent.right; verticalCenter: parent.verticalCenter }
            width: profileText.implicitWidth + 24
            height: 28
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: root.open("profile")

            Rectangle {
                anchors.fill: parent
                radius: Theme.radiusRow
                color: profileArea.containsMouse ? Theme.hover : Theme.clear
                Behavior on color { ColorAnimation { duration: Theme.durFast } }
            }
            StyledText {
                id: profileText
                anchors.centerIn: parent
                text: root.profileName() + "  ›"
                color: Theme.dim
            }
        }
    }

    // ---- tiles ----
    Grid {
        width: parent.width
        columns: 2
        spacing: 6
        readonly property real tileWidth: (width - spacing) / 2

        Tile {
            width: parent.tileWidth
            label: "Wi-Fi"
            value: !Networking.wifiEnabled ? "off"
                 : root.wifiNetwork ? root.wifiNetwork.name
                 : root.wifi ? "not connected" : "no adapter"
            active: Networking.wifiEnabled
            hasDetail: Networking.wifiEnabled
            onToggled: Networking.wifiEnabled = !Networking.wifiEnabled
            onDetail: root.open("wifi")
        }
        Tile {
            width: parent.tileWidth
            label: "Bluetooth"
            value: !root.btAdapter ? "no adapter"
                 : !root.btOn ? "off"
                 : root.btConnected.length === 0 ? "on"
                 : root.btConnected.length === 1 ? root.btConnected[0].name
                 : root.btConnected.length + " devices"
            active: root.btOn
            hasDetail: root.btOn
            onToggled: if (root.btAdapter) root.btAdapter.enabled = !root.btOn
            onDetail: root.open("bt")
        }
    }

    // ---- display ----
    Heading { text: "display" }

    Repeater {
        model: Brightness.displays
        SliderRow {
            required property var modelData
            label: modelData.label
            value: modelData.level
            onMoved: v => modelData.set(v)
        }
    }
    Repeater {
        model: root.uncontrollable
        Item {
            width: root.width
            height: 32
            StyledText { x: 10; width: Theme.labelWidth; anchors.verticalCenter: parent.verticalCenter; text: "monitor"; color: Theme.dim }
            StyledText {
                x: Theme.valueX
                width: parent.width - Theme.valueX - 10
                anchors.verticalCenter: parent.verticalCenter
                text: root.brightnessReason()
                color: Theme.dim
                elide: Text.ElideRight
            }
        }
    }
    Line {
        label: "wallpaper"
        value: ShellState.wallpaperName
        onClicked: { root.done(); ShellState.pickWallpaper() }
    }

    // ---- sound ----
    Heading { text: "sound" }

    SliderRow {
        label: root.muted ? "muted" : "volume"
        labelColor: root.muted ? Theme.warn : Theme.dim
        labelClickable: true
        value: root.volume
        muted: root.muted
        onLabelClicked: if (root.sink?.audio) root.sink.audio.muted = !root.sink.audio.muted
        onMoved: v => { if (root.sink?.audio) root.sink.audio.volume = v }
    }
    Line {
        label: "output"
        value: root.sink ? (root.sink.nickname || root.sink.description || root.sink.name) : "none"
        onClicked: root.open("output")
    }

    // ---- footer ----
    Item {
        width: parent.width
        height: 11
        Rectangle {
            anchors { left: parent.left; right: parent.right; verticalCenter: parent.verticalCenter; leftMargin: 10; rightMargin: 10 }
            height: 1
            color: Theme.border
        }
    }

    PowerSection {
        width: parent.width
        onDone: root.done()
    }
}
