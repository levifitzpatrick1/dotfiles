local mainMod = "ALT"

local screenshot_full = [[grim - | satty --filename -]]
local screenshot_region = [[grim -g "$(slurp)" - | satty --filename -]]

hl.bind(mainMod .. " + Return", hl.dsp.exec_cmd("ghostty"))
hl.bind(mainMod .. " + G",
    hl.dsp.exec_cmd("quickshell -c " .. os.getenv("HOME") .. "/.config/quickshell-games"))
hl.bind(mainMod .. " + E", hl.dsp.exec_cmd([[xdg-open "$HOME"]]))
hl.bind(mainMod .. " + B", hl.dsp.exec_cmd("xdg-open https://duckduckgo.com/"))
hl.bind(mainMod .. " + L", hl.dsp.exec_cmd("hyprlock"))
hl.bind(mainMod .. " + W",
    hl.dsp.exec_cmd("quickshell -c " .. os.getenv("HOME") .. "/.config/quickshell-themes"))

hl.bind("Print", hl.dsp.exec_cmd(screenshot_full))
hl.bind(mainMod .. " + Print", hl.dsp.exec_cmd(screenshot_region))
hl.bind("SHIFT + Print", hl.dsp.exec_cmd(screenshot_region))

hl.bind(mainMod .. " + C", hl.dsp.window.close())
hl.bind(mainMod .. " + V", hl.dsp.window.float({ action = "toggle" }))
hl.bind(mainMod .. " + F", hl.dsp.window.fullscreen())
hl.bind(mainMod .. " + P", hl.dsp.window.pseudo())
hl.bind(mainMod .. " + J", hl.dsp.layout("togglesplit"))

hl.bind(mainMod .. " + S", hl.dsp.exec_cmd([[pgrep -x spotify >/dev/null || (spotify &); hyprctl dispatch 'hl.dsp.workspace.toggle_special("spotify")']]))
hl.bind(mainMod .. " + SHIFT + S", hl.dsp.window.move({ workspace = "special:spotify" }))

hl.bind(mainMod .. " + left", hl.dsp.focus({ direction = "left" }))
hl.bind(mainMod .. " + right", hl.dsp.focus({ direction = "right" }))
hl.bind(mainMod .. " + up", hl.dsp.focus({ direction = "up" }))
hl.bind(mainMod .. " + down", hl.dsp.focus({ direction = "down" }))

for i = 1, 10 do
    local key = i % 10
    hl.bind(mainMod .. " + " .. key, hl.dsp.focus({ workspace = i }))
    hl.bind(mainMod .. " + SHIFT + " .. key, hl.dsp.window.move({ workspace = i }))
end

hl.bind(mainMod .. " + SHIFT + right", hl.dsp.exec_cmd("hyprctl dispatch resizeactive 30 0"), { repeating = true })
hl.bind(mainMod .. " + SHIFT + left", hl.dsp.exec_cmd("hyprctl dispatch resizeactive -30 0"), { repeating = true })
hl.bind(mainMod .. " + SHIFT + up", hl.dsp.exec_cmd("hyprctl dispatch resizeactive 0 -30"), { repeating = true })
hl.bind(mainMod .. " + SHIFT + down", hl.dsp.exec_cmd("hyprctl dispatch resizeactive 0 30"), { repeating = true })

hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(), { mouse = true })
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })
hl.bind("F23", hl.dsp.send_key_state({ key = "F23", state = "down", window = "class:^discord$", mods = "" }))
hl.bind("F23", hl.dsp.send_key_state({ key = "F23", state = "up", window = "class:^discord$", mods = "" }),
    { release = true })
hl.bind("F24", hl.dsp.send_key_state({ key = "F24", state = "down", window = "class:^discord$", mods = "" }))
hl.bind("F24", hl.dsp.send_key_state({ key = "F24", state = "up", window = "class:^discord$", mods = "" }),
    { release = true })

hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd(os.getenv("HOME") .. "/.config/quickshell-osd/scripts/volume_adjust up"),
    { locked = true, repeating = true })
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd(os.getenv("HOME") .. "/.config/quickshell-osd/scripts/volume_adjust down"),
    { locked = true, repeating = true })
hl.bind("XF86AudioMute", hl.dsp.exec_cmd(os.getenv("HOME") .. "/.config/quickshell-osd/scripts/volume_adjust mute"),
    { locked = true, repeating = true })
hl.bind("XF86AudioPlay", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioNext", hl.dsp.exec_cmd("playerctl next"), { locked = true })
hl.bind("XF86AudioPrev", hl.dsp.exec_cmd("playerctl previous"), { locked = true })

hl.bind("XF86MonBrightnessUp", hl.dsp.exec_cmd(os.getenv("HOME") .. "/.config/quickshell-osd/scripts/brightness_adjust up"), { locked = true, repeating = true })
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd(os.getenv("HOME") .. "/.config/quickshell-osd/scripts/brightness_adjust down"), { locked = true, repeating = true })

-- Passthrough / Game Mode submap
hl.define_submap("passthru", function()
    -- Keybinds to exit passthru mode
    hl.bind("SUPER + Escape", hl.dsp.submap("reset"))
    hl.bind("SUPER + Escape", hl.dsp.exec_cmd("notify-send -t 1500 'Game Mode' 'Disabled. Global shortcuts restored.'"))
    hl.bind("SUPER + F12", hl.dsp.submap("reset"))
    hl.bind("SUPER + F12", hl.dsp.exec_cmd("notify-send -t 1500 'Game Mode' 'Disabled. Global shortcuts restored.'"))
end)

-- Bind to enter passthru mode
hl.bind("SUPER + F12", hl.dsp.submap("passthru"))
hl.bind("SUPER + F12", hl.dsp.exec_cmd("notify-send -t 2000 -u critical 'Game Mode Enabled' 'All global shortcuts disabled. Press SUPER+Escape or SUPER+F12 to exit.'"))
