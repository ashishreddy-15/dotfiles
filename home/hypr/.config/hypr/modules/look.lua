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
        rounding = 8,
        shadow   = { enabled = true, range = 8, render_power = 3, color = 0xaa08090b },
        blur     = { enabled = true, size = 4, passes = 2 },
    },

    animations = { enabled = true },  -- Hyprland's built-in default animations

    dwindle = { preserve_split = true },

    misc = {
        force_default_wallpaper = 0,      -- no anime mascot; Quickshell will draw the wallpaper
        disable_hyprland_logo   = true,
        focus_on_activate       = true,   -- apps asking for focus (e.g. a link opening Brave) get it
    },
})
