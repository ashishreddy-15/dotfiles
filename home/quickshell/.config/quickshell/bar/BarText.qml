import QtQuick
import qs

// Text for the bar: Maple Mono at the bar's size and weight, in the bar's colours (they follow the wallpaper).
// Only the bar uses it: text elsewhere keeps the normal weight.
StyledText {
    color: Theme.barText
    font.pixelSize: Theme.barFontSize
    font.weight: Theme.barFontWeight
    // A wallpaper change flips every bar colour at once: ease that slowly. Hover and state changes answer in durFast,
    // like every other hover in the shell.
    Behavior on color { ColorAnimation { duration: ShellState.barFlipping ? Theme.durAmbient : Theme.durFast } }
}
