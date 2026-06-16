hl.on("hyprland.start", function()
    hl.exec_cmd("dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP")
    hl.exec_cmd("systemctl --user import-environment WAYLAND_DISPLAY XDG_CURRENT_DESKTOP XDG_SESSION_TYPE XDG_SESSION_DESKTOP HYPRLAND_INSTANCE_SIGNATURE XDG_RUNTIME_DIR")
    hl.exec_cmd("/usr/lib/xdg-desktop-portal-hyprland")

    hl.exec_cmd([[sh -c 'until tailscale ip -4 >/dev/null 2>&1; do sleep 1; done; wayvnc "$(tailscale ip -4)" 5900']])

    hl.exec_cmd("hyprlock")
    hl.exec_cmd("sh -c 'sleep 4; systemctl --user restart app-dev.lizardbyte.app.Sunshine.service'")
    hl.exec_cmd("sh -c 'sleep 1; swaync'")
    hl.exec_cmd("sh -c 'sleep 2; ~/.config/waybar/launch'")
    hl.exec_cmd("sh -c 'pkill hyprpaper; sleep 1; hyprpaper'")
    hl.exec_cmd("sh -c 'sleep 1; hypridle'")
end)
