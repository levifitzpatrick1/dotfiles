#!/usr/bin/env bash
set -euo pipefail

if ! command -v pacman >/dev/null 2>&1; then
  echo "This installer is for Arch Linux systems with pacman." >&2
  exit 1
fi

official_packages=(
  base-devel
  brightnessctl
  chezmoi
  fzf
  ghostty
  git
  grim
  hypridle
  hyprland
  hyprlock
  hyprpaper
  libnotify
  noto-fonts-cjk
  pipewire
  pipewire-alsa
  pipewire-jack
  pipewire-pulse
  playerctl
  rofi
  rofi-calc
  satty
  slurp
  starship
  stow
  swaync
  tailscale
  ttf-hack-nerd
  ttf-space-mono-nerd
  waybar
  wayvnc
  wget
  wireplumber
  wl-clipboard
  xdg-desktop-portal-hyprland
  xdg-utils
  yazi
  zoxide
)

aur_packages=(
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

echo "Installed Hyprland dotfiles packages."
echo "Next: chezmoi init --source ~/repos/dotfiles && chezmoi apply"

