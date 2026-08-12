#!/usr/bin/env bash
set -euo pipefail

# This script installs and configures VirtualBox with USB passthrough support on Arch Linux.

if ! command -v pacman >/dev/null 2>&1; then
  echo "This script is designed for Arch Linux systems using pacman." >&2
  exit 1
fi

echo "==> Installing VirtualBox, Host Modules, and Extension Pack..."
# virtualbox: Core virtualization software
# virtualbox-host-dkms: DKMS host module sources (since virtualbox-host-modules-arch is no longer available)
# virtualbox-ext-oracle: Extension Pack from AUR (required for USB 2.0/3.0 passthrough)
if command -v paru >/dev/null 2>&1; then
  paru -S --needed --noconfirm virtualbox virtualbox-host-dkms virtualbox-ext-oracle
elif command -v yay >/dev/null 2>&1; then
  yay -S --needed --noconfirm virtualbox virtualbox-host-dkms virtualbox-ext-oracle
else
  echo "No AUR helper (paru or yay) found. Installing official packages, but you must manually install virtualbox-ext-oracle from the AUR."
  sudo pacman -S --needed --noconfirm virtualbox virtualbox-host-dkms
fi

echo "==> Configuring vboxusers group..."
# The vboxusers group is required for the user to have permission to access host USB devices in VirtualBox.
CURRENT_USER="${USER:-$(whoami)}"
if [ "$CURRENT_USER" = "root" ] && [ -n "${SUDO_USER:-}" ]; then
  CURRENT_USER="$SUDO_USER"
fi

sudo usermod -aG vboxusers "$CURRENT_USER"
echo "Added user '$CURRENT_USER' to group 'vboxusers'."

echo "==> Loading VirtualBox kernel modules..."
sudo modprobe vboxdrv

echo "==> VirtualBox setup completed successfully!"
echo "IMPORTANT: You MUST log out and log back in (or reboot) for the 'vboxusers' group membership to take effect."
echo "If you want to start VirtualBox in your current terminal session with the new group immediately, run:"
echo "  newgrp vboxusers"
echo "  virtualbox"
