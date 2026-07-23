#!/usr/bin/env bash
# Standalone Neovim installer for a new Linux or macOS machine.
# Installs Neovim itself plus everything this config's plugins need
# (git, ripgrep, fd, a C compiler, tree-sitter-cli) without pulling in
# the rest of the Hyprland desktop setup. See install-arch-hyprland.sh
# for the full Arch/Hyprland install.
set -euo pipefail

echo "Installing Neovim and its build dependencies..."

if command -v pacman >/dev/null 2>&1; then
  sudo pacman -Syu --needed neovim git ripgrep fd base-devel tree-sitter-cli
elif command -v apt-get >/dev/null 2>&1; then
  sudo apt-get update
  sudo apt-get install -y neovim git ripgrep fd-find build-essential
elif command -v dnf >/dev/null 2>&1; then
  sudo dnf install -y neovim git ripgrep fd-find gcc
elif command -v brew >/dev/null 2>&1; then
  brew install neovim git ripgrep fd
else
  echo "No supported package manager found (pacman/apt/dnf/brew)." >&2
  echo "Install neovim, git, ripgrep, fd, and a C compiler manually, then re-run this script." >&2
  exit 1
fi

# tree-sitter-cli isn't packaged everywhere (e.g. apt/dnf); fall back to the
# prebuilt binary from GitHub releases if it's still missing after the above.
if ! command -v tree-sitter >/dev/null 2>&1; then
  echo "tree-sitter-cli not found via package manager, downloading a prebuilt binary..."

  os="$(uname -s)"
  arch="$(uname -m)"
  case "$os" in
    Linux) platform="linux" ;;
    Darwin) platform="macos" ;;
    *) echo "Unsupported OS for tree-sitter-cli fallback: $os" >&2; exit 1 ;;
  esac
  case "$arch" in
    x86_64) ts_arch="x64" ;;
    arm64|aarch64) ts_arch="arm64" ;;
    *) echo "Unsupported architecture for tree-sitter-cli fallback: $arch" >&2; exit 1 ;;
  esac

  mkdir -p "$HOME/.local/bin"
  curl -sL "https://github.com/tree-sitter/tree-sitter/releases/latest/download/tree-sitter-${platform}-${ts_arch}.gz" \
    | gunzip -c > "$HOME/.local/bin/tree-sitter"
  chmod +x "$HOME/.local/bin/tree-sitter"
  echo "Installed tree-sitter to ~/.local/bin/tree-sitter (make sure ~/.local/bin is on your PATH)."
fi

echo
echo "Neovim installed. Next steps:"
echo "  1. Install chezmoi if you haven't (see https://chezmoi.io)"
echo "  2. chezmoi init --source ~/repos/dotfiles"
echo "  3. chezmoi apply"
echo "  4. Launch nvim - it bootstraps lazy.nvim and installs plugins on first run."
