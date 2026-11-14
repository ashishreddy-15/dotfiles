-- Window rules. See https://wiki.hypr.land/configuring/core/rules/

-- Ignore apps asking to maximize themselves; tiling decides the size.
hl.window_rule({
    name  = "suppress-maximize-events",
    match = { class = ".*" },
    suppress_event = "maximize",
})

-- Fix drag-and-drop issues with XWayland apps.
hl.window_rule({
    name  = "fix-xwayland-drags",
    match = { class = "^$", title = "^$", xwayland = true, float = true, fullscreen = false, pin = false },
    no_focus = true,
})

-- Small utility windows float instead of tiling.
hl.window_rule({
    name  = "float-utilities",
    match = { class = "^(org.pulseaudio.pavucontrol|blueman-manager|nm-connection-editor)$" },
    float = true,
})

-- The pickers (launcher, clipboard, wallpapers) animate themselves (fade, zoom, height) inside their window.
-- Hyprland's own layer fade smears when Quickshell unmaps the window, so switch it off for them.
hl.layer_rule({
    name  = "no-anim-pickers",
    match = { namespace = "^quickshell-(launcher|clipboard|wallpapers)$" },
    no_anim = true,
})

-- When the wallpaper is light, the bar gets a translucent background (Bar.qml); blur what is behind it.
-- ignore_alpha: fully transparent pixels (the normal, dark-wallpaper case) are left alone.
hl.layer_rule({
    name  = "blur-bar",
    match = { namespace = "^quickshell-bar$" },
    blur  = true,
    ignore_alpha = 0.1,
})
