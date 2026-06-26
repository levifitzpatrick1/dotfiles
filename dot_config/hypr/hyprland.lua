require("hyprland.env")
require("hyprland.startup")
require("hyprland.input")
require("hyprland.vibes")
require("hyprland.layout")
require("hyprland.windows")
require("hyprland.binds")
require("machine_specific")

-- Brain Shell Keybinds
pcall(dofile, os.getenv("HOME") .. "/.config/Brain_Shell/Brain_ShellKeybinds.lua")
