import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Networking
import Quickshell.Bluetooth
import Quickshell.Services.Pipewire
import Quickshell.Services.UPower
import qs
import "../ui"

// The control center: only the quick things, in three bands, top to bottom:
//   toggles  one row of round buttons: Wi-Fi, Bluetooth, Do Not Disturb, Night light, Keep awake
//   levels   thick pill sliders with their icon inside: a brightness per screen, volume, mic (click the icon to mute)
//   media    what is playing (only while a player runs)
// and a footer: the battery (opens Settings > Power), Settings, and the power menu (Super + X).
// Everything with a list or options (networks, devices, wallpaper, ...) is in Settings (Super + I).
Column {
    id: root

    signal done()                // close the panel
    property bool fromHidden: true   // see ui/Stagger.qml
    property bool play: false    // true while the panel is open: the bands come in one after another (see ui/Stagger.qml)

    readonly property int pad: 8
    readonly property real inner: width - 2 * pad
    topPadding: 12
    bottomPadding: 2
    leftPadding: pad
    rightPadding: pad
    spacing: 14

    // ---- state shown on this page ----
    readonly property var wifi: Networking.devices.values.find(d => d.type === DeviceType.Wifi) ?? null
    readonly property var wifiNetwork: wifi?.networks.values.find(n => n.connected) ?? null
    readonly property var btAdapter: Bluetooth.defaultAdapter
    readonly property bool btOn: (btAdapter?.enabled ?? false) && !Rfkill.bluetoothBlocked   // a blocked radio counts as off
    readonly property var btConnected: Bluetooth.devices.values.filter(d => d.connected)

    readonly property var sink: Pipewire.defaultAudioSink
    readonly property bool muted: sink?.audio?.muted ?? false
    readonly property real volume: sink?.audio?.volume ?? 0
    readonly property var mic: Pipewire.defaultAudioSource
    readonly property bool micMuted: mic?.audio?.muted ?? false
    readonly property real micVolume: mic?.audio?.volume ?? 0
    PwObjectTracker { objects: [root.sink, root.mic] }

    readonly property var battery: UPower.displayDevice
    readonly property bool hasBattery: battery?.isLaptopBattery ?? false

    function fmtTime(seconds) {
        const h = Math.floor(seconds / 3600), m = Math.floor((seconds % 3600) / 60)
        return h > 0 ? h + "h " + m + "m" : m + "m"
    }
    // Close the control center and open Settings (on a section, or on the last one used).
    function openSettings(section) { root.done(); ShellState.openSettings(section) }
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


    // The entrance, one per band, top to bottom. Only on open: a band that appears later (media) or a change in
    // height does not replay it.
    Stagger { id: enterToggles; order: 0; play: root.play; fromHidden: root.fromHidden }
    Stagger { id: enterLevels; order: 1; play: root.play; fromHidden: root.fromHidden }
    Stagger { id: enterMedia; order: 2; play: root.play; fromHidden: root.fromHidden }
    Stagger { id: enterFooter; order: 3; play: root.play; fromHidden: root.fromHidden }

    // ---- toggles ----
    Row {
        width: root.inner
        opacity: enterToggles.progress
        transform: Translate { y: enterToggles.rise }
        readonly property real cell: width / 5

        RoundToggle {
            width: parent.cell
            glyph: Theme.glyphWifi
            label: "Wi-Fi"
            status: !root.wifi ? "no adapter" : !Networking.wifiEnabled ? "off"
                  : root.wifiNetwork ? root.wifiNetwork.name : "on"
            on: Networking.wifiEnabled
            onToggled: Networking.wifiEnabled = !Networking.wifiEnabled
        }
        RoundToggle {
            width: parent.cell
            glyph: Theme.glyphBluetooth
            label: "Bluetooth"
            status: Rfkill.bluetoothHardBlocked ? "switch" : Rfkill.bluetoothBlocked ? "blocked"
                  : !root.btAdapter ? "none" : !root.btOn ? "off"
                  : root.btConnected.length === 0 ? "on"
                  : root.btConnected.length === 1 ? root.btConnected[0].name
                  : root.btConnected.length + " devices"
            on: root.btOn
            onToggled: Rfkill.bluetoothBlocked ? Rfkill.unblockBluetooth() : (root.btAdapter ? root.btAdapter.enabled = !root.btOn : undefined)
        }
        RoundToggle {
            width: parent.cell
            glyph: Theme.glyphSilent
            label: "Silence"
            // the number is how many notifications are waiting in the history
            status: (Modes.dnd ? "on" : "off") + (Notifs.count > 0 ? " · " + Notifs.count : "")
            on: Modes.dnd
            onToggled: Modes.toggleDnd()
        }
        RoundToggle {
            width: parent.cell
            glyph: Theme.glyphNight
            label: "Night"
            status: Modes.nightLight ? Modes.kelvin + " K" : "off"
            on: Modes.nightLight
            onToggled: Modes.toggleNight()
        }
        RoundToggle {
            width: parent.cell
            glyph: Theme.glyphAwake
            label: "Awake"
            status: Modes.keepAwake ? "on" : "off"
            on: Modes.keepAwake
            onToggled: Modes.toggleAwake()
        }
    }

    // ---- levels ----
    Column {
        width: root.inner
        spacing: 8
        opacity: enterLevels.progress
        transform: Translate { y: enterLevels.rise }

        Repeater {
            model: Brightness.displays
            PillSlider {
                required property var modelData
                glyph: Theme.glyphBright
                label: modelData.label
                value: modelData.level
                onMoved: v => modelData.set(v)
            }
        }
        Repeater {
            model: root.uncontrollable
            PillSlider {
                active: false
                glyph: Theme.glyphBright
                label: "monitor: " + root.brightnessReason()
            }
        }
        PillSlider {
            glyph: Theme.glyphVolume
            mutedGlyph: Theme.glyphMuted
            label: root.sink ? (root.sink.nickname || root.sink.description || root.sink.name) : "no output"
            value: root.volume
            muted: root.muted
            iconClickable: true
            onIconClicked: if (root.sink?.audio) root.sink.audio.muted = !root.sink.audio.muted
            onMoved: v => { if (root.sink?.audio) { root.sink.audio.volume = v; if (root.muted && v > 0) root.sink.audio.muted = false } }
        }
        PillSlider {
            glyph: Theme.glyphMic
            mutedGlyph: Theme.glyphMicOff
            label: "mic"
            value: root.micVolume
            muted: root.micMuted
            iconClickable: true
            onIconClicked: if (root.mic?.audio) root.mic.audio.muted = !root.mic.audio.muted
            onMoved: v => { if (root.mic?.audio) root.mic.audio.volume = v }
        }
    }

    // ---- media (only while a player is running) ----
    MediaBlock {
        width: root.inner
        opacity: enterMedia.progress
        transform: Translate { y: enterMedia.rise }
    }

    // ---- footer: battery, Settings, power ----
    component IconButton: Item {
        id: btn
        property string glyph
        signal clicked()
        width: 34
        height: 34

        activeFocusOnTab: true
        Keys.onPressed: event => {
            if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter || event.key === Qt.Key_Space) { btn.clicked(); event.accepted = true }
        }
        Pressable {
            anchors.fill: parent
            radius: height / 2
            onClicked: btn.clicked()
            StyledText { anchors.centerIn: parent; text: btn.glyph; color: Theme.text }
        }
        FocusRing { shown: btn.activeFocus; radius: height / 2 }
    }

    Item {
        width: root.inner
        height: 36
        opacity: enterFooter.progress
        transform: Translate { y: enterFooter.rise }

        // The battery opens Settings on Power.
        Pressable {
            id: batteryArea
            visible: root.hasBattery
            anchors { left: parent.left; verticalCenter: parent.verticalCenter }
            width: batteryText.implicitWidth + 20
            height: 30
            onClicked: root.openSettings("power")

            activeFocusOnTab: true
            Keys.onPressed: event => {
                if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter || event.key === Qt.Key_Space) { root.openSettings("power"); event.accepted = true }
            }
            FocusRing { shown: batteryArea.activeFocus }

            StyledText {
                id: batteryText
                x: 10
                anchors.verticalCenter: parent.verticalCenter
                text: root.batteryText()
                color: root.batteryColor()
                font.pixelSize: Theme.fontSmall
            }
        }

        Row {
            anchors { right: parent.right; verticalCenter: parent.verticalCenter }
            spacing: 4
            IconButton { glyph: Theme.glyphGear; onClicked: root.openSettings("") }
            IconButton { glyph: Theme.glyphPower; onClicked: { root.done(); ShellState.openPowerMenu() } }
        }
    }
}
