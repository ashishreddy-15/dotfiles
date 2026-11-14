-- Long-running helpers are systemd user services, not started here:
--   hypridle, hyprpolkitagent   (enabled by system/user-services.sh)
-- They start with the Hyprland session and restart if they crash.
-- Only small one-off things that don't have a unit belong here.

hl.on("hyprland.start", function()
    -- Clipboard history for SUPER+SHIFT+V
    hl.exec_cmd("uwsm app -- wl-paste --type text  --watch cliphist store")
    hl.exec_cmd("uwsm app -- wl-paste --type image --watch cliphist store")
end)
