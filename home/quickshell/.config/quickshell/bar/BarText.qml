import QtQuick
import qs

// Text for the bar: Maple Mono at the bar's size and weight, in the bar's colours (they follow the wallpaper).
// Only the bar uses it: text elsewhere keeps the normal weight.
StyledText {
    color: Theme.barText
    font.pixelSize: Theme.barFontSize
    font.weight: Theme.barFontWeight
    Behavior on color { ColorAnimation { duration: Theme.durAmbient } }
}
