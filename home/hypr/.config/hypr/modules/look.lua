-- Colours: "Carbon & Pewter" (same palette as quickshell/Theme.qml).
hl.config({
    general = {
        gaps_in     = 4,
        gaps_out    = 8,
        border_size = 2,
        col = {
            active_border   = "rgba(6c7f91ee)",
            inactive_border = "rgba(262626ee)",
        },
        resize_on_border = true,   -- drag window edges to resize
        layout           = "dwindle",
    },

    decoration = {
        rounding = 10,                -- = Theme.radiusCard
        shadow   = { enabled = true, range = 8, render_power = 3, color = 0xaa08090b },
        blur     = { enabled = true, size = 4, passes = 2 },
    },

    animations = { enabled = true },

    dwindle = { preserve_split = true },

    misc = {
        force_default_wallpaper = 0,      -- no anime mascot; Quickshell will draw the wallpaper
        disable_hyprland_logo   = true,
        disable_splash_rendering = true,  -- no joke text at the bottom of empty screens
        focus_on_activate       = true,   -- apps asking for focus (e.g. a link opening Brave) get it
    },
})

-- Motion: the same numbers as quickshell/Theme.qml. Hyprland speeds are in units of 100 ms, so
-- durBase 140 ms = 1.4, durFast 90 ms = 0.9, durSlow 240 ms = 2.4. Enter slower than exit, ease out, no springs.
hl.curve("easeOut", { type = "bezier", points = { {0.215, 0.61}, {0.355, 1} } })   -- = Easing.OutCubic

hl.animation({ leaf = "global",        enabled = true, speed = 1.4, bezier = "easeOut" })
hl.animation({ leaf = "windowsIn",     enabled = true, speed = 1.4, bezier = "easeOut", style = "popin 94%" })
hl.animation({ leaf = "windowsOut",    enabled = true, speed = 0.9, bezier = "easeOut", style = "popin 94%" })
hl.animation({ leaf = "windowsMove",   enabled = true, speed = 1.4, bezier = "easeOut" })
hl.animation({ leaf = "fadeIn",        enabled = true, speed = 1.4, bezier = "easeOut" })
hl.animation({ leaf = "fadeOut",       enabled = true, speed = 0.9, bezier = "easeOut" })
hl.animation({ leaf = "fadeSwitch",    enabled = true, speed = 0.9, bezier = "easeOut" })
hl.animation({ leaf = "fadeShadow",    enabled = true, speed = 1.4, bezier = "easeOut" })
hl.animation({ leaf = "border",        enabled = true, speed = 0.9, bezier = "easeOut" })
hl.animation({ leaf = "borderangle",   enabled = false })
hl.animation({ leaf = "layersIn",      enabled = true, speed = 1.4, bezier = "easeOut", style = "fade" })
hl.animation({ leaf = "layersOut",     enabled = true, speed = 0.9, bezier = "easeOut", style = "fade" })
hl.animation({ leaf = "workspaces",    enabled = true, speed = 2.4, bezier = "easeOut", style = "slide" })
hl.animation({ leaf = "workspacesIn",  enabled = true, speed = 2.4, bezier = "easeOut", style = "slide" })
hl.animation({ leaf = "workspacesOut", enabled = true, speed = 2.4, bezier = "easeOut", style = "slide" })
