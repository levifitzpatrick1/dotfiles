hl.on("hyprland.start", function()
    hl.exec_cmd("dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP")
    hl.exec_cmd("systemctl --user import-environment WAYLAND_DISPLAY XDG_CURRENT_DESKTOP XDG_SESSION_TYPE XDG_SESSION_DESKTOP HYPRLAND_INSTANCE_SIGNATURE XDG_RUNTIME_DIR")
    hl.exec_cmd("systemctl --user start hyprland-session.target xdg-desktop-portal")

    hl.exec_cmd([[sh -c 'until tailscale ip -4 >/dev/null 2>&1;]])

    hl.exec_cmd("sh -c 'sleep 4; systemctl --user restart app-dev.lizardbyte.app.Sunshine.service'")

    -- Brain Shell & services (keeping the custom wallpaper engine instead of awww)
    hl.exec_cmd("quickshell -c " .. os.getenv("HOME") .. "/.local/src/Brain_Shell")
    hl.exec_cmd("quickshell -c " .. os.getenv("HOME") .. "/.config/quickshell-osd")
    hl.exec_cmd("systemctl --user start hyprpolkitagent")
    hl.exec_cmd("wl-paste --type text --watch cliphist store")
    hl.exec_cmd("wl-paste --type image --watch cliphist store")

    hl.exec_cmd("sh -c 'sleep 1; ~/.config/themes/restore_wallpaper'")
    hl.exec_cmd("sh -c 'sleep 1; hypridle'")
    hl.exec_cmd("sh -c 'sleep 2; openrgb -d \"ASUS ROG STRIX B650E-I GAMING WIFI\" -c 000000'")
    hl.exec_cmd("sh -c 'sleep 3; steam -silent'")
end)
