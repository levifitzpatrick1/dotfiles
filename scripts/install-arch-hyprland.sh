#!/usr/bin/env bash
set -euo pipefail

if ! command -v pacman >/dev/null 2>&1; then
  echo "This installer is for Arch Linux systems with pacman." >&2
  exit 1
fi

official_packages=(
  base-devel
  brightnessctl
  cava
  chezmoi
  cliphist
  fzf
  ghostty
  git
  grim
  hypridle
  hyprland
  hyprlock
  hyprpaper
  hyprsunset
  libnotify
  lm_sensors
  matugen
  noto-fonts-cjk
  pipewire
  pipewire-alsa
  pipewire-jack
  pipewire-pulse
  playerctl
  quickshell
  rofi
  rofi-calc
  satty
  slurp
  starship
  stow
  swaync
  tailscale
  ttf-hack-nerd
  ttf-jetbrains-mono-nerd
  ttf-space-mono-nerd
  upower
  waybar
  wayvnc
  wf-recorder
  wget
  wireplumber
  wl-clipboard
  wtype
  xdg-desktop-portal-hyprland
  xdg-utils
  yazi
  zoxide
)

aur_packages=(
  auto-cpufreq
  envycontrol
  sunshine-bin
  ttf-comfortaa
  wlogout
)

install_paru() {
  if command -v paru >/dev/null 2>&1; then
    return
  fi

  sudo pacman -S --needed git base-devel

  tmpdir="$(mktemp -d)"
  trap 'rm -rf "$tmpdir"' EXIT

  git clone https://aur.archlinux.org/paru.git "$tmpdir/paru"
  (cd "$tmpdir/paru" && makepkg -si --needed)
}

sudo pacman -Syu --needed "${official_packages[@]}"
install_paru
paru -S --needed "${aur_packages[@]}"

# Start services
sudo systemctl enable --now auto-cpufreq

# Set up Brain Shell
echo "Setting up Brain Shell..."
if [ ! -d "$HOME/.local/src/Brain_Shell" ]; then
  git clone https://github.com/Brainitech/Brain_Shell.git "$HOME/.local/src/Brain_Shell"
fi
bash "$HOME/.local/src/Brain_Shell/install.sh"

echo "Installed Hyprland dotfiles packages and Brain Shell."
echo "Next: chezmoi init --source ~/repos/dotfiles && chezmoi apply"

