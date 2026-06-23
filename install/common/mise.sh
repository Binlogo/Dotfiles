#!/usr/bin/env bash

# @file install/common/mise.sh
# @brief Install the language runtimes pinned by mise.
# @description
#   Runs `mise install` for the tools declared in ~/.config/mise/config.toml.
#   The `mise` binary itself is provided by the Homebrew bundle step, so this
#   only populates the runtimes. The chezmoi wrapper embeds a hash of the
#   manifest, so `chezmoi apply` re-runs this whenever the tool set changes.

set -Eeuo pipefail

if [ "${DOTFILES_DEBUG:-}" ]; then
    set -x
fi

# Homebrew and the standalone bin dir, in case PATH is not inherited.
export PATH="/opt/homebrew/bin:${HOME}/.local/bin:${PATH}"

#
# @description Abort early with a hint when `mise` is missing.
#
function require_mise() {
    if ! command -v mise > /dev/null 2>&1; then
        echo "mise not found — did the Homebrew bundle step finish?" >&2
        exit 1
    fi
}

#
# @description Install every runtime pinned in the mise manifest.
#
function install_runtimes() {
    mise install --yes
}

#
# @description Install the mise-managed language runtimes.
#
function main() {
    require_mise
    install_runtimes
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main
fi
