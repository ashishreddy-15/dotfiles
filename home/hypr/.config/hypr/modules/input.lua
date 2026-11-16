hl.config({
    input = {
        kb_layout  = "us",
        kb_options = "caps:none",   -- Caps Lock does nothing by itself: it is the handwriting key (binds.lua)

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
