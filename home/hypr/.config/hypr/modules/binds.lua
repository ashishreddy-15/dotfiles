-- Keybindings. See https://wiki.hypr.land/configuring/core/binds/
-- Apps are started through `uwsm app` so each one runs in its own systemd scope
-- (clean shutdown, per-app logs in `journalctl --user`).

local function app(cmd) return hl.dsp.exec_cmd("uwsm app -- " .. cmd) end

local mod = "SUPER"
local function k(keys) return mod .. " + " .. keys end

local terminal    = "kitty"
local fileManager = "nautilus --new-window"
-- Temporary launcher until the Quickshell one exists.
local launcher    = "rofi -show drun -run-command 'uwsm app -- {cmd}'"

-- Apps
hl.bind(k("Return"),  app(terminal))
hl.bind(k("E"),       app(fileManager))
hl.bind(k("Space"),   hl.dsp.exec_cmd(launcher))
hl.bind(k("SHIFT + V"), hl.dsp.exec_cmd("cliphist list | rofi -dmenu -p clipboard | cliphist decode | wl-copy"))

-- Session
hl.bind(k("Escape"),    hl.dsp.exec_cmd("loginctl lock-session"))   -- lock (via hypridle -> hyprlock)
hl.bind(k("SHIFT + E"), hl.dsp.exec_cmd("uwsm stop"))               -- log out

-- Windows
hl.bind(k("Q"),         hl.dsp.window.close())
hl.bind(k("F"),         hl.dsp.window.fullscreen({ mode = "fullscreen" }))
hl.bind(k("M"),         hl.dsp.window.fullscreen({ mode = "maximized" }))
hl.bind(k("V"),         hl.dsp.window.float({ action = "toggle" }))
hl.bind(k("P"),         hl.dsp.window.pseudo())
hl.bind(k("T"),         hl.dsp.layout("togglesplit"))

-- Focus / move with arrows or h j k l. Moving past the screen edge goes to the other monitor.
local dirs = { left = "left", right = "right", up = "up", down = "down",
               H = "left", L = "right", K = "up", J = "down" }
for key, dir in pairs(dirs) do
    hl.bind(k(key),             hl.dsp.focus({ direction = dir }))
    hl.bind(k("SHIFT + " .. key), hl.dsp.window.move({ direction = dir }))
end

-- Monitors: SUPER + , / .  focus laptop / main;  add SHIFT to send the window there.
hl.bind(k("comma"),          hl.dsp.focus({ monitor = "left" }))
hl.bind(k("period"),         hl.dsp.focus({ monitor = "right" }))
hl.bind(k("SHIFT + comma"),  hl.dsp.window.move({ monitor = "left" }))
hl.bind(k("SHIFT + period"), hl.dsp.window.move({ monitor = "right" }))

-- Workspaces: SUPER + 1..0 go to 1..10, SHIFT moves the window there.
for i = 1, 10 do
    local key = tostring(i % 10)
    hl.bind(k(key),             hl.dsp.focus({ workspace = i }))
    hl.bind(k("SHIFT + " .. key), hl.dsp.window.move({ workspace = i }))
end
hl.bind(k("Tab"),        hl.dsp.focus({ workspace = "previous" }))
hl.bind(k("mouse_down"), hl.dsp.focus({ workspace = "e+1" }))
hl.bind(k("mouse_up"),   hl.dsp.focus({ workspace = "e-1" }))

-- Scratchpad
hl.bind(k("S"),         hl.dsp.workspace.toggle_special("scratch"))
hl.bind(k("SHIFT + S"), hl.dsp.window.move({ workspace = "special:scratch" }))

-- Mouse: SUPER + left drag moves, SUPER + right drag resizes.
hl.bind(k("mouse:272"), hl.dsp.window.drag(),   { mouse = true })
hl.bind(k("mouse:273"), hl.dsp.window.resize(), { mouse = true })

-- Screenshots (to clipboard)
hl.bind("Print",         hl.dsp.exec_cmd([[grim -g "$(slurp)" - | wl-copy]]))
hl.bind("SHIFT + Print", hl.dsp.exec_cmd([[grim -o "$(hyprctl activeworkspace -j | python3 -c 'import json,sys;print(json.load(sys.stdin)["monitor"])')" - | wl-copy]]))

-- Media / brightness keys (work on the lock screen too)
local hw = { locked = true, repeating = true }
hl.bind("XF86AudioRaiseVolume",  hl.dsp.exec_cmd("wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+"), hw)
hl.bind("XF86AudioLowerVolume",  hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"),      hw)
hl.bind("XF86AudioMute",         hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"),     { locked = true })
hl.bind("XF86AudioMicMute",      hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"),   { locked = true })
hl.bind("XF86MonBrightnessUp",   hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%+"),                  hw)
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%-"),                  hw)
hl.bind("XF86AudioPlay",         hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPause",        hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioNext",         hl.dsp.exec_cmd("playerctl next"),       { locked = true })
hl.bind("XF86AudioPrev",         hl.dsp.exec_cmd("playerctl previous"),   { locked = true })
