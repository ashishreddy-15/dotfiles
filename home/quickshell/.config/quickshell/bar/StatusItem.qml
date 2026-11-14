import QtQuick
import qs

// One text status entry: dim label + value, e.g. "vol 62%".
// Each item sets `attention`; the bar only shows items that have it.
Row {
    property string label
    property string value
    property color valueColor: Theme.text
    property bool attention: true

    spacing: 5

    StyledText { text: parent.label; color: Theme.dim; font.pixelSize: Theme.barFontSize }
    StyledText { text: parent.value; color: parent.valueColor; font.pixelSize: Theme.barFontSize }
}
