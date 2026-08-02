#!/usr/bin/env bash

# @file install/common/mise.sh
# @brief Install mise (native build) and the language runtimes it pins.
# @description
#   Ensures the `mise` binary is present, then runs `mise install` for the tools
#   declared in ~/.config/mise/config.toml.
#
#   mise is installed from its official standalone installer (https://mise.run)
#   rather than Homebrew. jdx (mise's author) bakes extra build-time
#   optimizations into the released binaries (e.g. BOLT) that Homebrew's build
#   can't reproduce, so the Homebrew package ships a slower binary — jdx now
#   recommends against installing mise via Homebrew. Native builds also support
#   `mise self-update`, which package-managed builds disable.
#
#   The chezmoi wrapper embeds a hash of the manifest, so `chezmoi apply`
#   re-runs this whenever the tool set changes.

set -Eeuo pipefail

if [ "${DOTFILES_DEBUG:-}" ]; then
    set -x
fi

# Standalone bin dir first (where mise.run installs, so the native build shadows
# any leftover Homebrew mise), then Homebrew, in case PATH is not inherited.
export PATH="${HOME}/.local/bin:/opt/homebrew/bin:${PATH}"

#
# @description Install the native mise build if it is not already on PATH.
# @note mise.run installs to ~/.local/bin/mise by default; `hash -r` clears any
#   cached negative lookup so the freshly installed binary resolves in this run.
#
function ensure_mise() {
    if command -v mise > /dev/null 2>&1; then
        return
    fi
    echo "mise not found — installing the native (optimized) build from https://mise.run" >&2
    curl -fsSL https://mise.run | sh
    hash -r
}

#
# @description Install every runtime pinned in the mise manifest.
#
function install_runtimes() {
    mise install --yes
}

#
# @description Install mise and its managed language runtimes.
#
function main() {
    ensure_mise
    install_runtimes
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main
fi
