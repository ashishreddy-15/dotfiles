hl.config({
    input = {
        kb_layout  = "us",
        kb_options = "",            -- the shell adds caps:none while handwriting input is enabled in Settings and a pen tablet is connected (Handwriting.qml)

        follow_mouse = 1,           -- focus follows the mouse
        sensitivity  = 0,           -- -1.0 .. 1.0

        touchpad = {
            natural_scroll       = false,
            disable_while_typing = true,
        },
    },
})

-- 3-finger horizontal swipe switches workspace.
hl.gesture({ fingers = 3, direction = "horizontal", action = "workspace" })
