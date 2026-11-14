import QtQuick
import Quickshell
import Quickshell.Bluetooth
import qs

// Bluetooth page: your devices and the ones found nearby. Scans only while this page is open.
Column {
    id: root

    signal back()

    readonly property var adapter: Bluetooth.defaultAdapter
    readonly property bool on: adapter?.enabled ?? false

    // Connected first, then saved (paired) ones, then newly found ones. Nearby gadgets that don't announce
    // a name (they show up as a bare address) are left out unless you have paired them.
    readonly property var addressLike: /^([0-9a-f]{2}[:-]){5}[0-9a-f]{2}$/i
    readonly property var devices: Bluetooth.devices.values
        .filter(d => d.paired || d.connected || (d.name !== "" && !addressLike.test(d.name)))
        .sort((a, b) => (b.connected - a.connected) || ((b.paired ? 1 : 0) - (a.paired ? 1 : 0)) || a.name.localeCompare(b.name))

    Binding {
        target: root.adapter
        property: "discovering"
        value: root.on && ShellState.panelOpen
        when: root.adapter !== null
    }

    PageHeader {
        title: "Bluetooth"
        switchText: root.adapter ? (root.on ? "on" : "off") : ""
        switchColor: root.on ? Theme.ok : Theme.dim
        onBack: root.back()
        onSwitched: if (root.adapter) root.adapter.enabled = !root.on
    }

    StyledText {
        visible: !root.on
        leftPadding: 10
        topPadding: 8
        bottomPadding: 8
        text: root.adapter ? "Bluetooth is off" : "no adapter"
        color: Theme.dim
    }

    Repeater {
        model: root.on ? root.devices : []

        ListItem {
            id: item
            required property var modelData

            text: modelData.name || modelData.address
            marked: modelData.connected
            detail: modelData.pairing ? "pairing…"
                  : modelData.connected ? (modelData.batteryAvailable ? Math.round(modelData.battery * 100) + "%" : "connected")
                  : modelData.paired ? "paired" : "pair"
            rightColor: modelData.connected ? Theme.ok : Theme.dim

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
        leftPadding: 10
        topPadding: 8
        bottomPadding: 8
        text: "searching…"
        color: Theme.dim
    }
}
