import QtQuick
import Quickshell
import Quickshell.Bluetooth
import qs

// "bt off", "bt on", "bt <device>" or "bt 2" (several connected).
StatusItem {
    readonly property var adapter: Bluetooth.defaultAdapter
    readonly property var connected: Bluetooth.devices.values.filter(d => d.connected)

    label: "bt"
    value: !adapter?.enabled ? "off"
         : connected.length === 0 ? "on"
         : connected.length === 1 ? (connected[0].name.length > 16 ? connected[0].name.slice(0, 15) + "…" : connected[0].name)
         : connected.length
    valueColor: connected.length > 0 ? Theme.text : Theme.dim
}
