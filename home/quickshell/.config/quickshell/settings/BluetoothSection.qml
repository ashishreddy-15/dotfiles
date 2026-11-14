import QtQuick
import Quickshell
import Quickshell.Bluetooth
import qs

// Bluetooth: the switch, your devices and the ones found nearby. Scans only while Settings is open on this section.
Page {
    id: root

    readonly property var adapter: Bluetooth.defaultAdapter
    readonly property bool on: adapter?.enabled ?? false

    // Connected first, then saved (paired) ones, then newly found ones. Nearby gadgets that don't announce
    // a name (they show up as a bare address) are left out unless you have paired them.
    readonly property var addressLike: /^([0-9a-f]{2}[:-]){5}[0-9a-f]{2}$/i
    readonly property var devices: Bluetooth.devices.values
        .filter(d => d.paired || d.connected || (d.name !== "" && !addressLike.test(d.name)))
        .sort((a, b) => (b.connected - a.connected) || ((b.paired ? 1 : 0) - (a.paired ? 1 : 0)) || a.name.localeCompare(b.name))
    readonly property var connectedDevices: Bluetooth.devices.values.filter(d => d.connected)

    Binding {
        target: root.adapter
        property: "discovering"
        value: root.on && ShellState.settingsOpen && root.visible
        when: root.adapter !== null
    }

    SettingRow {
        title: "Bluetooth"
        description: !root.adapter ? "No Bluetooth adapter"
                   : !root.on ? "Off"
                   : root.connectedDevices.length === 0 ? "On"
                   : root.connectedDevices.length === 1 ? "Connected to " + root.connectedDevices[0].name
                   : "Connected to " + root.connectedDevices.length + " devices"
        Switch { visible: root.adapter !== null; checked: root.on; onToggled: root.adapter.enabled = !root.on }
    }

    GroupLabel { visible: root.on; text: "Devices" }

    Repeater {
        model: root.on ? root.devices : []

        ListRow {
            id: item
            required property var modelData

            title: modelData.name || modelData.address
            marked: modelData.connected
            detail: modelData.pairing ? "pairing…"
                  : modelData.connected ? (modelData.batteryAvailable ? Math.round(modelData.battery * 100) + "%" : "connected")
                  : modelData.paired ? "paired" : "pair"
            detailColor: modelData.connected ? Theme.ok : Theme.dim

            // Pairing is only half the job: connect as soon as it has worked.
            property bool connectAfterPairing: false
            Connections {
                target: item.modelData
                function onPairedChanged() {
                    if (item.connectAfterPairing && item.modelData.paired) { item.connectAfterPairing = false; item.modelData.connect() }
                }
            }

            onClicked: {
                if (modelData.connected) modelData.disconnect()
                else if (modelData.paired) modelData.connect()
                else { connectAfterPairing = true; modelData.pair() }
            }
        }
    }

    StyledText {
        visible: root.on && root.devices.length === 0
        topPadding: 12
        leftPadding: 12
        text: "Searching…"
        color: Theme.dim
    }
}
