import QtQuick
import Quickshell
import Quickshell.Networking
import qs

// Wi-Fi: on/off switch, the networks around you, and a password prompt for new secured ones.
Column {
    id: root

    property bool expanded: false
    signal toggleExpanded()

    readonly property var wifi: Networking.devices.values.find(d => d.type === DeviceType.Wifi) ?? null
    readonly property var connectedNetwork: wifi?.networks.values.find(n => n.connected) ?? null

    // Connected first, then saved ones, then by signal strength.
    readonly property var networks: {
        if (!wifi) return []
        return wifi.networks.values.slice().sort((a, b) =>
            (b.connected - a.connected) || ((b.known ? 1 : 0) - (a.known ? 1 : 0)) || (b.signalStrength - a.signalStrength))
            .slice(0, 8)                                    // the best few; the list would get very long
    }

    property string askingFor: ""       // name of the secured network we are asking a password for

    // Look for networks only while the list is open.
    Binding {
        target: root.wifi
        property: "scannerEnabled"
        value: root.expanded && ShellState.panelOpen
        when: root.wifi !== null
    }
    onExpandedChanged: if (!expanded) askingFor = ""

    function activate(n) {
        if (n.connected) { n.disconnect(); return }
        if (n.known || n.security === WifiSecurityType.Open) { n.connect(); return }
        askingFor = (askingFor === n.name) ? "" : n.name      // new and secured: ask for the password
    }

    Line {
        label: "wifi"
        value: !Networking.wifiEnabled ? "off"
             : root.connectedNetwork ? root.connectedNetwork.name
             : root.wifi ? "not connected" : "no adapter"
        valueColor: root.connectedNetwork ? Theme.text : Theme.dim
        toggleText: Networking.wifiEnabled ? "on" : "off"
        toggleColor: Networking.wifiEnabled ? Theme.ok : Theme.dim
        expandable: Networking.wifiEnabled
        expanded: root.expanded
        onClicked: if (Networking.wifiEnabled) root.toggleExpanded()
        onToggled: Networking.wifiEnabled = !Networking.wifiEnabled
    }

    Repeater {
        model: root.expanded && Networking.wifiEnabled ? root.networks : []

        Column {
            id: entry
            required property var modelData
            width: root.width

            readonly property bool secured: modelData.security !== WifiSecurityType.Open
            readonly property bool connecting: modelData.state === ConnectionState.Connecting

            ListItem {
                text: entry.modelData.name
                marked: entry.modelData.connected
                // "connecting…", or the signal strength, with a padlock in front of networks that need a password
                detail: entry.connecting ? "connecting…"
                      : (entry.secured && !entry.modelData.known ? "\uf023  " : "") + Math.round(entry.modelData.signalStrength * 100) + "%"
                rightColor: entry.modelData.connected ? Theme.ok : Theme.dim
                onClicked: root.activate(entry.modelData)
            }

            // Password prompt under the network that needs one
            Item {
                visible: root.askingFor === entry.modelData.name
                width: parent.width
                height: visible ? 34 : 0

                Rectangle {
                    x: 78; y: 2
                    width: parent.width - 78 - 10
                    height: 30
                    radius: Theme.radius
                    color: Theme.bg
                    border.width: 1
                    border.color: pass.activeFocus ? Theme.accent : Theme.border

                    TextInput {
                        id: pass
                        anchors { fill: parent; leftMargin: 10; rightMargin: 10 }
                        verticalAlignment: TextInput.AlignVCenter
                        echoMode: TextInput.Password
                        color: Theme.bright
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSize
                        clip: true
                        onVisibleChanged: if (visible) { text = ""; forceActiveFocus() }
                        onAccepted: { entry.modelData.connectWithPsk(text); root.askingFor = ""; text = "" }
                        Keys.onEscapePressed: root.askingFor = ""

                        StyledText {
                            visible: pass.text === ""
                            text: "password, then Enter"
                            color: Theme.dim
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }
                }
            }
        }
    }
}
