#!/usr/bin/env bash

# @file install/macos/common/brew.sh
# @brief Install the bootstrap-critical Homebrew packages.
# @description
#   Installs the curated set of always-on CLI tools and first-run GUI apps via
#   `brew bundle`. Language runtimes (node, ruby, python, go, java) are managed
#   by mise — do NOT list them here.
#
#   Philosophy: keep first-run install small. Only bootstrap-critical and
#   always-on tools live here. Infrequent GUI apps, communication apps, duplicate
#   utilities, and project-specific tooling are install-on-demand — see the
#   reference list at the bottom of this file.

set -Eeuo pipefail

if [ "${DOTFILES_DEBUG:-}" ]; then
    set -x
fi

#
# @description Install the curated Homebrew bundle.
# @note `brew bundle`'s exit status is non-zero on partial failures (e.g. an
#   existing differently-versioned cask, or a symlink already placed by
#   mise/corepack). We log and continue so downstream steps (mise, skills) still
#   run.
#
function install_packages() {
    brew bundle --file=/dev/stdin <<'EOF' || echo "WARN: brew bundle reported partial failures — see log above"
# ---------------------------------------------------------------------
# CLI tools (bootstrap-critical)
# ---------------------------------------------------------------------
brew "chezmoi"
brew "direnv"
brew "eza"
brew "fd"
brew "fzf"
brew "gh"
brew "git"
brew "git-delta"
brew "jq"
brew "mise"
brew "neovim"
brew "ripgrep"
brew "sheldon"      # zsh plugin manager (replaces oh-my-zsh)
brew "starship"
brew "zoxide"       # smarter cd (replaces autojump)

# ---------------------------------------------------------------------
# GUI apps (first-run essentials)
# ---------------------------------------------------------------------
cask "cmux"
cask "font-fira-code-nerd-font"
cask "karabiner-elements"
cask "raycast"
cask "visual-studio-code"
EOF
}

# ---------------------------------------------------------------------
# Install-on-demand reference (NOT auto-installed)
# ---------------------------------------------------------------------
# Run these manually when a project actually needs them. They were removed
# from the Brewfile to keep `brew bundle` fast, sudo-free, and ~GB lighter.
#
#   # Low-frequency CLI / duplicates
#   brew install bat btop coreutils dust helix just lazygit rsync tree wget
#
#   # Runtime-adjacent tools
#   # pnpm can come from Node/Corepack; git-lfs is managed by mise in this repo.
#   brew install pnpm git-lfs
#
#   # Low-frequency GUI utilities
#   brew install --cask appcleaner contexts fork istat-menus obsidian stats typora
#
#   # Communication apps
#   brew install --cask slack telegram
#
#   # iOS / mobile dev
#   brew tap facebook/fb && brew tap xcodesorg/made
#   brew install ios-deploy libimobiledevice facebook/fb/idb-companion xcodesorg/made/xcodes
#
#   # C/C++ / cross-compile
#   brew install llvm cmake automake binutils
#   brew tap filosottile/musl-cross && brew install filosottile/musl-cross/musl-cross
#
#   # Swift / protobuf
#   brew install swift-format swift-protobuf swiftformat clang-format protolint
#
#   # Build infra / cache
#   brew install sccache watchman xcodegen wabt
#
#   # Doc / image
#   brew install doxygen ghostscript graphviz
#
#   # Network capture / mobile mirror
#   brew install mitmproxy sniffnet scrcpy
#   brew install --cask charles proxyman
#
#   # SQLite / data inspection
#   brew install sqlcipher tabiew
#   brew install --cask db-browser-for-sqlite
#
#   # Misc niceties
#   brew install asciinema pv tmux tokei fswatch
#
#   # Mac App Store (needs `mas` + GUI sign-in; skip in headless bundle)
#   brew install mas
#   mas install 425424353   # The Unarchiver
#   mas install 402592703   # Time Out
#   mas install 1457158844  # Take a Break
#   mas install 1630034110  # Bob
#   mas install 1575588022  # MenubarX

#
# @description Install the bootstrap-critical Homebrew packages.
#
function main() {
    install_packages
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main
fi
