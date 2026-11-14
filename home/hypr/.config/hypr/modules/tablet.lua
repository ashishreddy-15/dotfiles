-- Pen tablets. The shell sets each tablet up live from Settings > Tablet (quickshell/Tablet.qml): which screen, the
-- active area (kept to the screen's proportions), orientation, pen or mouse mode. This is only the default for when the
-- shell is not running: the tablet covers the screen you are working on.
hl.config({
    input = {
        tablet = { output = "current" },
    },
})
