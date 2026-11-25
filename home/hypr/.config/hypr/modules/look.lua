-- Colours: "Carbon & Pewter" (same palette as quickshell/Theme.qml), dark or light.
-- The scheme is the one `appearance set color-scheme` wrote to ~/.local/state/dotfiles/scheme (missing = dark).
local scheme = "dark"
local f = io.open((os.getenv("HOME") or "") .. "/.local/state/dotfiles/scheme", "r")
if f then
	local v = (f:read("*a") or ""):gsub("%s+", "")
	f:close()
	if v == "light" then scheme = "light" end
end
local palette = {
	dark = { active = "rgba(6c7f91ee)", inactive = "rgba(262626ee)", shadow = 0xaa08090b },
	-- Light: the borders sit between a light window and (usually) a dark wallpaper, so they cannot be the light
	-- palette's accent / border (a dark border vanished into the wallpaper, a light one looked lit up). The focused
	-- window gets a mid-tone, more saturated pewter-blue that shows against both (about 3:1); the others a faint edge.
	light = { active = "rgba(5f86b0ff)", inactive = "rgba(00000026)", shadow = 0x55000000 },
}
local colours = palette[scheme]

-- Reduce motion: `appearance set reduce-motion on` writes "reduced" to ~/.local/state/dotfiles/motion (missing = full)
-- and reloads Hyprland. Reduced turns off the spatial leaves below (spring geometry, popin, workspace slides): windows
-- then appear and disappear with only their fade, moves and resizes jump, and workspaces switch instantly. Fades,
-- borders and layers stay on, since a short opacity / colour change is not motion.
local motion_reduced = false
f = io.open((os.getenv("HOME") or "") .. "/.local/state/dotfiles/motion", "r")
if f then
	local v = (f:read("*a") or ""):gsub("%s+", "")
	f:close()
	motion_reduced = v == "reduced"
end
local spatial = not motion_reduced

hl.config({
	general = {
		gaps_in = 4,
		gaps_out = 8,
		border_size = 2,
		col = {
			active_border = colours.active,
			inactive_border = colours.inactive,
		},
		resize_on_border = true, -- drag window edges to resize
		layout = "dwindle",
	},

	decoration = {
		rounding = 10, -- = Theme.radiusCard
		shadow = { enabled = true, range = 8, render_power = 3, color = colours.shadow },
		blur = { enabled = true, size = 4, passes = 2 },
	},

	animations = { enabled = true },

	dwindle = { preserve_split = true, force_split = 2 },

	misc = {
		force_default_wallpaper = 0, -- no anime mascot; Quickshell will draw the wallpaper
		disable_hyprland_logo = true,
		disable_splash_rendering = true, -- no joke text at the bottom of empty screens
		focus_on_activate = true, -- apps asking for focus (e.g. a link opening Brave) get it
	},
})

-- Motion: matched to quickshell/Theme.qml.
-- Bezier leaves: speed is in units of 100 ms, so durBase 140 ms = 1.4, durFast 90 ms = 0.9.
-- Spring leaves: the curve's physics (stiffness / damping / mass) sets the timing and `speed` is ignored
-- (hyprutils only feeds it to the bezier path). hl.animation still requires the field, so spring leaves keep
-- the duration they stand in for (1.4 windows, 2.4 = durSlow workspaces) purely as documentation.
-- springSmooth matches the shell's springSmooth / dampingSmooth (Qt's SpringAnimation); scripts/ui-check compares them.
-- Spatial geometry uses native physical springs (never for fades, borders, or exits);
-- opacity, colour, and dismissals stay monotonic on easeOut (= Easing.OutCubic).
-- `enabled = spatial` marks the leaves that reduce motion turns off (see `spatial` at the top).
hl.curve("easeOut",      { type = "bezier", points = { { 0.215, 0.61 }, { 0.355, 1 } } }) -- = Easing.OutCubic
hl.curve("springSmooth", { type = "spring", mass = 1, stiffness = 260, damping = 27.7 }) -- ~0.86 damping ratio: weighted, supple windows
hl.curve("springFluid",  { type = "spring", mass = 1, stiffness = 210, damping = 26.7 }) -- ~0.92 damping ratio: smooth workspace glide

hl.animation({ leaf = "global",        enabled = true, speed = 1.4, bezier = "easeOut" })
hl.animation({ leaf = "windows",       enabled = spatial, speed = 1.4, spring = "springSmooth" })
hl.animation({ leaf = "windowsIn",     enabled = spatial, speed = 1.4, spring = "springSmooth", style = "popin 92%" })
hl.animation({ leaf = "windowsOut",    enabled = spatial, speed = 0.9, bezier = "easeOut",      style = "popin 94%" })
hl.animation({ leaf = "windowsMove",   enabled = spatial, speed = 1.4, spring = "springSmooth" })
hl.animation({ leaf = "fadeIn",        enabled = true, speed = 1.4, bezier = "easeOut" })
hl.animation({ leaf = "fadeOut",       enabled = true, speed = 0.9, bezier = "easeOut" })
hl.animation({ leaf = "fadeSwitch",    enabled = true, speed = 0.9, bezier = "easeOut" })
hl.animation({ leaf = "fadeShadow",    enabled = true, speed = 1.4, bezier = "easeOut" })
hl.animation({ leaf = "fadeDim",       enabled = true, speed = 1.4, bezier = "easeOut" })
hl.animation({ leaf = "border",        enabled = true, speed = 0.9, bezier = "easeOut" })
hl.animation({ leaf = "borderangle",   enabled = false })
hl.animation({ leaf = "layersIn",      enabled = true, speed = 1.4, bezier = "easeOut",      style = "fade" })
hl.animation({ leaf = "layersOut",     enabled = true, speed = 0.9, bezier = "easeOut",      style = "fade" })
hl.animation({ leaf = "workspaces",    enabled = spatial, speed = 2.4, spring = "springFluid",  style = "slide" })
hl.animation({ leaf = "workspacesIn",  enabled = spatial, speed = 2.4, spring = "springFluid",  style = "slide" })
hl.animation({ leaf = "workspacesOut", enabled = spatial, speed = 2.4, spring = "springFluid",  style = "slide" })
-- The scratchpad (SUPER+S) drops in like a drawer over the current workspace, on the same glide.
hl.animation({ leaf = "specialWorkspace",    enabled = spatial, speed = 2.4, spring = "springFluid", style = "slidevert" })
hl.animation({ leaf = "specialWorkspaceIn",  enabled = spatial, speed = 2.4, spring = "springFluid", style = "slidevert" })
hl.animation({ leaf = "specialWorkspaceOut", enabled = spatial, speed = 2.4, spring = "springFluid", style = "slidevert" })
