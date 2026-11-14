import QtQuick
import Quickshell
import Quickshell.Services.UPower
import qs

// Power profile: power saver, balanced or performance (through tuned-ppd).
Column {
    id: root

    signal back()

    readonly property var profiles: [
        { name: "power saver", value: PowerProfile.PowerSaver,  note: "longest battery" },
        { name: "balanced",    value: PowerProfile.Balanced,    note: "the default" },
        { name: "performance", value: PowerProfile.Performance, note: "fastest, uses more power" }
    ]

    PageHeader { title: "Power profile"; onBack: root.back() }

    Repeater {
        model: root.profiles.filter(p => p.value !== PowerProfile.Performance || PowerProfiles.hasPerformanceProfile)

        ListItem {
            required property var modelData
            text: modelData.name
            detail: modelData.note
            marked: PowerProfiles.profile === modelData.value
            onClicked: PowerProfiles.profile = modelData.value
        }
    }
}
