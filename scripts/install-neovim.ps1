# Standalone Neovim installer for a new Windows machine.
# Installs Neovim itself plus everything this config's plugins need
# (git, ripgrep, fd, a C compiler, tree-sitter-cli, chezmoi).
#
# Run from PowerShell:
#   irm <raw-url-to-this-file> | iex
# or, after cloning the dotfiles repo:
#   powershell -ExecutionPolicy Bypass -File .\scripts\install-neovim.ps1

$ErrorActionPreference = "Stop"

if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
    Write-Error "winget is not available. Install 'App Installer' from the Microsoft Store, then re-run this script."
    exit 1
}

function Install-WingetPackage {
    param([string]$Id)
    Write-Host "Installing $Id..."
    winget install --id $Id -e --silent --accept-package-agreements --accept-source-agreements
    if ($LASTEXITCODE -ne 0) {
        Write-Warning "winget install for $Id did not succeed (exit code $LASTEXITCODE). You may need to install it manually."
    }
}

# LLVM provides clang, used to compile treesitter parsers on Windows.
$packages = @(
    "Neovim.Neovim",
    "Git.Git",
    "BurntSushi.ripgrep.MSVC",
    "sharkdp.fd",
    "twpayne.chezmoi",
    "LLVM.LLVM"
)
foreach ($id in $packages) {
    Install-WingetPackage -Id $id
}

# tree-sitter-cli isn't on winget; fetch the prebuilt binary from GitHub releases.
if (-not (Get-Command tree-sitter -ErrorAction SilentlyContinue)) {
    Write-Host "Downloading tree-sitter-cli..."

    $arch = if ([System.Environment]::Is64BitOperatingSystem) {
        if ($env:PROCESSOR_ARCHITECTURE -eq "ARM64") { "arm64" } else { "x64" }
    } else { "x86" }

    $installDir = "$env:LOCALAPPDATA\Programs\tree-sitter"
    New-Item -ItemType Directory -Force -Path $installDir | Out-Null

    $gzPath = "$installDir\tree-sitter.gz"
    Invoke-WebRequest -Uri "https://github.com/tree-sitter/tree-sitter/releases/latest/download/tree-sitter-windows-$arch.gz" -OutFile $gzPath

    $exePath = "$installDir\tree-sitter.exe"
    $inStream = [System.IO.File]::OpenRead($gzPath)
    $gzStream = New-Object System.IO.Compression.GzipStream($inStream, [System.IO.Compression.CompressionMode]::Decompress)
    $outStream = [System.IO.File]::Create($exePath)
    $gzStream.CopyTo($outStream)
    $outStream.Close(); $gzStream.Close(); $inStream.Close()
    Remove-Item $gzPath

    $userPath = [Environment]::GetEnvironmentVariable("Path", "User")
    if ($userPath -notlike "*$installDir*") {
        [Environment]::SetEnvironmentVariable("Path", "$userPath;$installDir", "User")
        Write-Host "Added $installDir to your User PATH. Open a new terminal for it to take effect."
    }
}

Write-Host ""
Write-Host "Neovim installed. Next steps (in a new terminal so PATH updates apply):"
Write-Host "  1. chezmoi init --source <path to your cloned dotfiles repo>"
Write-Host "  2. chezmoi apply"
Write-Host "  3. Launch nvim - it bootstraps lazy.nvim and installs plugins on first run."
