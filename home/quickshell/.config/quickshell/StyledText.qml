import QtQuick

// Text with the theme applied. mono: true -> Maple Mono, false -> Asap.
Text {
    property bool mono: true

    color: Theme.text
    font.family: mono ? Theme.monoFont : Theme.uiFont
    font.pixelSize: Theme.fontSize
    font.variableAxes: mono ? ({}) : ({ "wdth": Theme.uiWidth })
    verticalAlignment: Text.AlignVCenter
}
