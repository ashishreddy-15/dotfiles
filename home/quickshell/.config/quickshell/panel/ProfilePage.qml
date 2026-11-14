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

    StyledText {
        visible: PowerProfiles.profile === PowerProfile.Performance && PowerProfiles.degradationReason !== PerformanceDegradationReason.None
        width: parent.width
        leftPadding: 10
        rightPadding: 10
        topPadding: 6
        bottomPadding: 6
        text: PowerProfiles.degradationReason === PerformanceDegradationReason.LapDetected
              ? "Performance is limited: the laptop is on your lap."
              : "Performance is limited: the system is too hot."
        color: Theme.warn
        font.pixelSize: Theme.fontSmall
        wrapMode: Text.Wrap
    }
}
