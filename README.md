# Levi's Dotfiles

Chezmoi-managed Hyprland setup. Lua is the trunk/source of truth for Hyprland:

- `dot_config/hypr/hyprland.lua`
- `dot_config/hypr/hyprland/*.lua`

## Install

On Arch:

```sh
git clone git@github.com:levifitzpatrick1/dotfiles.git ~/repos/dotfiles
cd ~/repos/dotfiles
./scripts/install-arch-hyprland.sh
chezmoi init --source ~/repos/dotfiles
chezmoi apply
```

The install script installs `paru` first when it is missing, then installs the packages this config expects.

### Neovim only (other machines, incl. Windows)

If you just want the Neovim config on a machine that isn't running this full
Hyprland setup:

```sh
# Linux / macOS
./scripts/install-neovim.sh
```

```powershell
# Windows (PowerShell)
.\scripts\install-neovim.ps1
```

Then `chezmoi init`/`chezmoi apply` as above (or copy `dot_config/nvim` to
your Neovim config directory directly). See `dot_config/nvim/KEYBINDINGS.md`
for a quick intro and the full keymap list.

## Hyprland Apps TLDR

Short caveman list. What thing do.

- **Hyprland** - window manager. It make windows move.
- **hyprctl** - talk to Hyprland from terminal.
- **Ghostty** - terminal. `Alt+Return`.
- **Rofi** - app launcher. `Alt+Space`.
- **Game launcher** - Steam library plus Steam non-Steam shortcuts. `Alt+G`.
- **Waybar** - top/status bar.
- **SwayNC** - notifications. `Alt+Escape`.
- **Wlogout** - power/logout menu. `Alt+X`.
- **Hyprlock** - lock screen. `Alt+L`.
- **Hypridle** - idle helper. Lock/sleep stuff.
- **Hyprpaper** - wallpaper. Used because `swww` not installed here.
- **Grim + Slurp + Satty** - screenshots. `Print` or region screenshot.
- **wpctl** - volume keys.
- **playerctl** - media keys.
- **brightnessctl** - brightness keys.
- **Tailscale + WayVNC** - remote desktop over tailnet.
- **Sunshine** - game/desktop streaming.

More detail is in `docs/apps.md`.
