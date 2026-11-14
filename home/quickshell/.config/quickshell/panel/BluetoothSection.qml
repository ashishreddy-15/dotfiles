import QtQuick
import Quickshell
import Quickshell.Bluetooth
import qs

// Bluetooth: on/off switch, your devices, and a scan for new ones.
Column {
    id: root

    property bool expanded: false
    signal toggleExpanded()

    readonly property var adapter: Bluetooth.defaultAdapter
    readonly property bool on: adapter?.enabled ?? false
    readonly property var connected: Bluetooth.devices.values.filter(d => d.connected)

    // Connected first, then saved (paired) ones, then newly found ones. Nearby gadgets that don't announce
    // a name (they show up as a bare address) are left out unless you have paired them.
    readonly property var addressLike: /^([0-9a-f]{2}[:-]){5}[0-9a-f]{2}$/i
    readonly property var devices: Bluetooth.devices.values
        .filter(d => d.paired || d.connected || (d.name !== "" && !addressLike.test(d.name)))
        .sort((a, b) => (b.connected - a.connected) || ((b.paired ? 1 : 0) - (a.paired ? 1 : 0)) || a.name.localeCompare(b.name))

    // Look for devices only while the list is open.
    Binding {
        target: root.adapter
        property: "discovering"
        value: root.expanded && root.on && ShellState.panelOpen
        when: root.adapter !== null
    }

    function summary() {
        if (!adapter) return "no adapter"
        if (!on) return "off"
        if (connected.length === 0) return "not connected"
        return connected.length === 1 ? connected[0].name : connected.length + " devices"
    }

    Line {
        label: "bt"
        value: root.summary()
        valueColor: root.connected.length > 0 ? Theme.text : Theme.dim
        toggleText: root.adapter ? (root.on ? "on" : "off") : ""
        toggleColor: root.on ? Theme.ok : Theme.dim
        expandable: root.on
        expanded: root.expanded
        onClicked: if (root.on) root.toggleExpanded()
        onToggled: if (root.adapter) root.adapter.enabled = !root.adapter.enabled
    }

    Repeater {
        model: root.expanded && root.on ? root.devices : []

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

    // Shown while the list is open and nothing has been found yet
    StyledText {
        visible: root.expanded && root.on && root.devices.length === 0
        leftPadding: 78
        height: 28
        text: "searching…"
        color: Theme.dim
    }
}
