local ok, colors = pcall(dofile, os.getenv("HOME") .. "/.config/themes/current/colors.lua")
if not ok or not colors then
    colors = {
        primary = "rgba(89b4faee)",
        secondary = "rgba(94e2d5ee)",
        glow = "rgba(89b4fa38)",
        border_inactive = "rgba(313244aa)",
    }
end

hl.config({
    general = {
        gaps_in = 6,
        gaps_out = 12,
        border_size = 2,
        col = {
            active_border = colors.primary,
            inactive_border = colors.border_inactive,
        },
        layout = "dwindle",
        resize_on_border = true,
    },

    decoration = {
        rounding = 10,
        blur = {
            enabled = true,
            size = 8,
            passes = 3,
            new_optimizations = true,
            ignore_opacity = true,
            brightness = 1.0,
            contrast = 1.0,
            noise = 0.02,
        },
        shadow = {
            enabled = false,
        },
    },

    animations = {
        enabled = true,
    },

    misc = {
        force_default_wallpaper = 0,
        disable_hyprland_logo = true,
    },
})

hl.curve("snappy", { type = "bezier", points = { { 0.2, 1.0 }, { 0.2, 1.0 } } })
hl.curve("easeInOut", { type = "bezier", points = { { 0.4, 0.0 }, { 0.2, 1.0 } } })

hl.animation({ leaf = "windows", enabled = true, speed = 3, bezier = "snappy", style = "slide" })
hl.animation({ leaf = "windowsOut", enabled = true, speed = 3, bezier = "snappy", style = "slide" })
hl.animation({ leaf = "windowsMove", enabled = true, speed = 3, bezier = "easeInOut" })
hl.animation({ leaf = "border", enabled = true, speed = 5, bezier = "default" })
hl.animation({ leaf = "fade", enabled = true, speed = 3, bezier = "snappy" })
hl.animation({ leaf = "workspaces", enabled = true, speed = 4, bezier = "snappy", style = "slide" })
