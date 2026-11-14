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

-- The launcher animates itself (fade, zoom, height) inside its window. Hyprland's own layer fade
-- smears when Quickshell unmaps the window, so switch it off for this one.
hl.layer_rule({
    name  = "no-anim-launcher",
    match = { namespace = "^quickshell-launcher$" },
    no_anim = true,
})
