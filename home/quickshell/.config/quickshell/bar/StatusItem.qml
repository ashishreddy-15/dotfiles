import QtQuick
import qs

// One text-only status entry:  dim label + value, e.g. "vol 62%".
Row {
    property string label
    property string value
    property color valueColor: Theme.text

    spacing: 6

    StyledText { text: parent.label; color: Theme.dim }
    StyledText { text: parent.value; color: parent.valueColor }
}
