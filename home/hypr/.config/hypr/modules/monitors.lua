-- Physical layout (as seen from the chair):
--
--   ┌──────────────┐┌────────────────────────┐
--   │   eDP-1      ││       HDMI-A-1         │
--   │  laptop      ││   Samsung 27" (main)   │
--   │  1920x1200   ││       2560x1440        │
--   └──────────────┘│                        │
--                   └────────────────────────┘
--
-- Positions are in logical pixels (physical size / scale). The laptop is bottom-aligned with the
-- monitor, which matches a laptop sitting lower than the monitor; the cursor crosses between
-- them along that shared edge. Positions are computed from the scales below, so changing a
-- scale keeps the layout correct. Use scales that divide the resolution evenly
-- (laptop: 1.0, 1.2, 1.25, 1.5 all give whole-number logical sizes).

local M = {}

M.main   = "HDMI-A-1"
M.laptop = "eDP-1"

local laptopScale = 1.2       -- the laptop panel is dense (163 DPI), so scale it up
local mainScale   = 1.0

local laptopW, laptopH = 1920 / laptopScale, 1200 / laptopScale
local mainH            = 1440 / mainScale

-- ---- the lid ----
-- With another monitor on, a closed lid turns the laptop screen off, so Hyprland moves workspace 10 (and its windows)
-- to that monitor; opening the lid reloads this config, which turns the screen back on, and workspace 10 goes back
-- (Hyprland returns workspaces to the monitor they came from). With no other monitor nothing changes here: logind
-- suspends as usual. Also covered: starting with the lid shut, and unplugging the monitor while it is shut.
local function lidClosed()
    local f = io.open("/proc/acpi/button/lid/LID/state")
    if not f then return false end
    local s = f:read("*a")
    f:close()
    return s:find("closed") ~= nil
end

local function otherMonitorOn()
    for _, m in ipairs(hl.get_monitors()) do
        if m.name ~= M.laptop then return true end
    end
    return false
end

local function laptopOff() hl.monitor({ output = M.laptop, disabled = true }) end
-- Turning a screen back on only takes effect through a reload. The short wait lets the lid state settle first.
local function reloadSoon() hl.timer(function() hl.exec_cmd("hyprctl reload") end, { timeout = 300, type = "oneshot" }) end

hl.bind("switch:on:Lid Switch",  function() if otherMonitorOn() then laptopOff() end end, { locked = true })
hl.bind("switch:off:Lid Switch", reloadSoon, { locked = true })
hl.on("monitor.added", function(m)
    if m and m.name ~= M.laptop and lidClosed() then laptopOff() end
end)
hl.on("monitor.removed", function()
    if lidClosed() and not otherMonitorOn() then reloadSoon() end   -- the last other monitor went away
end)

if lidClosed() and otherMonitorOn() then
    laptopOff()
else
    hl.monitor({ output = M.laptop, mode = "1920x1200@60", scale = laptopScale,
                 position = string.format("0x%d", math.floor(mainH - laptopH + 0.5)) })
end
hl.monitor({ output = M.main,   mode = "2560x1440@60", scale = mainScale,
             position = string.format("%dx0", math.floor(laptopW + 0.5)) })

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
