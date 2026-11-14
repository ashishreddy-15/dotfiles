import QtQuick
import qs

// Text for the bar: Maple Mono at the bar's size, in the bar's colours (they follow the wallpaper).
StyledText {
    color: Theme.barText
    font.pixelSize: Theme.barFontSize
    Behavior on color { ColorAnimation { duration: Theme.durAmbient } }
}
