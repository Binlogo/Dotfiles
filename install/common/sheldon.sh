#!/usr/bin/env bash

# @file install/common/sheldon.sh
# @brief Clone/update the zsh plugins managed by Sheldon.
# @description
#   Runs `sheldon lock --update` against ~/.config/sheldon/plugins.toml, cloning
#   or updating every declared plugin. The `sheldon` binary itself is provided
#   by the Homebrew bundle step. The chezmoi wrapper embeds a hash of the
#   manifest, so `chezmoi apply` re-runs this whenever the plugin set changes.

set -Eeuo pipefail

if [ "${DOTFILES_DEBUG:-}" ]; then
    set -x
fi

# Homebrew and the standalone bin dir, in case PATH is not inherited.
export PATH="/opt/homebrew/bin:${HOME}/.local/bin:${PATH}"

#
# @description Abort early with a hint when `sheldon` is missing.
#
function require_sheldon() {
    if ! command -v sheldon > /dev/null 2>&1; then
        echo "sheldon not found — did the Homebrew bundle step finish?" >&2
        exit 1
    fi
}

#
# @description Refresh the Sheldon lockfile, cloning/updating every plugin.
#
function update_plugins() {
    sheldon lock --update
}

#
# @description Install/update the Sheldon-managed zsh plugins.
#
function main() {
    require_sheldon
    update_plugins
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main
fi
