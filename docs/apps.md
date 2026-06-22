# Apps On This Hyprland Setup

## Config Apps

These are the important apps this dotfiles repo configures or calls.

| App | What it does | Package |
| --- | --- | --- |
| Hyprland | Wayland window manager | `hyprland` |
| hyprctl | Control Hyprland from shell/scripts | `hyprland` |
| Ghostty | Terminal, bound to `Alt+Return` | `ghostty` |
| Rofi | App launcher, bound to `Alt+Space` | `rofi`, `rofi-calc` |
| Waybar | Top/status bar | `waybar` |
| SwayNC | Notification daemon/control center | `swaync` |
| Wlogout | Logout/power menu | `wlogout` |
| Hyprlock | Lock screen | `hyprlock` |
| Hypridle | Idle helper | `hypridle` |
| Hyprpaper | Wallpaper fallback | `hyprpaper` |
| Grim | Screenshot capture | `grim` |
| Slurp | Region picker for screenshots | `slurp` |
| Satty | Screenshot editor | `satty` |
| WirePlumber/wpctl | Audio session and volume control | `wireplumber` |
| playerctl | Media key control | `playerctl` |
| brightnessctl | Brightness key control | `brightnessctl` |
| Tailscale | Tailnet address for remote access | `tailscale` |
| WayVNC | Remote desktop server | `wayvnc` |
| Sunshine | Game/desktop streaming service | `sunshine-bin` |
| Starship | Shell prompt | `starship` |
| Zoxide | Smarter `cd` helper | `zoxide` |
| Yazi | Terminal file manager | `yazi` |
| Chezmoi | Dotfile manager | `chezmoi` |

## Explicit Packages Installed Here

Snapshot from `pacman -Qqe` on 2026-06-22.

```text
amd-ucode
antigravity-cli
archon-appimage
ark
base
base-devel
bluez
bluez-utils
brave-origin-nightly-bin
brightnessctl
bun
cameractrls
chezmoi
claude-code-stable-bin
curseforge
discord
docker
docker-desktop
dolphin
dosfstools
dunst
earlyoom
efibootmgr
elephant-all-bin
ethtool
exfatprogs
fastfetch
faugus-launcher
fzf
gemini-cli
ghostty
git
github-cli
go
gst-plugin-pipewire
htop
hypridle
hyprland
hyprlock
hyprpaper
hyprpicker
hyprshot
icedtea-web
inkscape
intel-media-driver
iotas
iwd
jdk
jre-openjdk
jre8-openjdk
kate
konsole
lazygit
libpulse
libratbag
libva-intel-driver
lightdm
lightdm-gtk-greeter
lightdm-gtk-greeter-settings
linux
linux-firmware
linux-headers
nano
neofetch
network-manager-applet
networkmanager
noto-fonts-cjk
ntfs-3g
nvidia-open
nvtop
obs-studio
obsbot-camera-control
openrgb
orca-slicer-bin
pacman-contrib
paru
paru-debug
pavucontrol
piper
pipewire
pipewire-alsa
pipewire-jack
pipewire-pulse
plasma-meta
plasma-workspace
plasma-x11-session
playerctl
protonup-qt-bin
python-pip
quickshell
r8125-dkms
raiderio-client
rawtherapee
remmina
rofi
rofi-calc
rusty-path-of-building
satty
sddm
slack-desktop
smartmontools
spotify
sqlc
starship
steam
stow
sudo
sunshine-bin
swaync
t3code-bin
tailscale
teams-for-linux-bin
ttf-comfortaa
ttf-hack-nerd
ttf-space-mono-nerd
udiskie
unzip
v4l2loopback-dkms
vesktop-bin
vim
vulkan-intel
vulkan-nouveau
vulkan-radeon
wago-app-bin
walker-bin
waybar
wayvnc
wget
winboat-bin
wireless_tools
wireplumber
wlogout
wpa_supplicant
xdg-desktop-portal-hyprland
xdg-utils
xf86-video-amdgpu
xf86-video-ati
xf86-video-nouveau
xorg-server
xorg-xinit
xorg-xinput
yaak
yazi
ydotool
zed
zen-browser-bin
zoom
zoxide
zram-generator
```

