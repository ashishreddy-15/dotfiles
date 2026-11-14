-- Physical layout (as seen from the chair):
--
--   ┌──────────────┐┌────────────────────────┐
--   │   eDP-1      ││       HDMI-A-1         │
--   │  laptop      ││   Samsung 27" (main)   │
--   │  1920x1200   ││       2560x1440        │
--   └──────────────┘│                        │
--                   └────────────────────────┘
--
-- Positions are in logical pixels. The laptop is bottom-aligned with the
-- monitor (y = 1440 - 1200 = 240), which matches a laptop sitting lower
-- than the monitor; the cursor crosses between them along that shared edge.
-- If you change the laptop scale, its width changes: x of HDMI-A-1 = 1920 / scale.

local M = {}

M.main   = "HDMI-A-1"
M.laptop = "eDP-1"

hl.monitor({ output = M.laptop, mode = "1920x1200@60", position = "0x240",  scale = 1 })
hl.monitor({ output = M.main,   mode = "2560x1440@60", position = "1920x0", scale = 1 })

-- Anything else (projector, another monitor): preferred mode, placed to the right.
hl.monitor({ output = "", mode = "preferred", position = "auto", scale = "auto" })

-- Workspaces 1-9 live on the main monitor, 10 on the laptop.
-- If the main monitor is unplugged, Hyprland moves them all to the laptop.
for i = 1, 9 do
    hl.workspace_rule({ workspace = tostring(i), monitor = M.main, default = (i == 1) })
end
hl.workspace_rule({ workspace = "10", monitor = M.laptop, default = true })

-- Start the cursor on the main monitor.
hl.config({ cursor = { default_monitor = M.main } })

return M
