-- Hyprland config (Lua, Hyprland >= 0.57). Wiki: https://wiki.hypr.land/configuring/
-- Each file in modules/ handles one topic. Check for errors without restarting:
--   Hyprland --verify-config        (./install.sh runs this automatically)

require("modules.monitors")   -- outputs, positions, workspace -> monitor
require("modules.input")      -- keyboard, touchpad
require("modules.look")       -- gaps, borders, blur, animations
require("modules.rules")      -- window rules
require("modules.binds")      -- keybindings
require("modules.autostart")  -- things started with the session
