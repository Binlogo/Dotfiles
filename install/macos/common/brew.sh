#!/usr/bin/env bash

# @file install/macos/common/brew.sh
# @brief Install the bootstrap-critical Homebrew bundle.
# @description
#   Runs `brew bundle` against the curated Brewfile at
#   ~/.config/homebrew/Brewfile (managed by chezmoi). The chezmoi wrapper embeds
#   a hash of that Brewfile, so `chezmoi apply` re-runs this whenever the package
#   set changes. Language runtimes (node, ruby, python, go, java) are managed by
#   mise — keep them out of the Brewfile.

set -Eeuo pipefail

if [ "${DOTFILES_DEBUG:-}" ]; then
    set -x
fi

# Homebrew bin, in case PATH is not inherited.
export PATH="/opt/homebrew/bin:${PATH}"

readonly BREWFILE="${HOME}/.config/homebrew/Brewfile"

#
# @description Abort early with a hint when Homebrew or the Brewfile is missing.
#
function require_brew() {
    if ! command -v brew > /dev/null 2>&1; then
        echo "brew not found — install Homebrew before running chezmoi apply." >&2
        exit 1
    fi
    if [[ ! -f "${BREWFILE}" ]]; then
        echo "Brewfile not found at ${BREWFILE} — was it applied by chezmoi?" >&2
        exit 1
    fi
}

#
# @description Install everything declared in the Brewfile.
# @note `--no-upgrade` keeps this install-only: it adds missing packages but
#   never upgrades already-installed ones, so `chezmoi apply` stays fast and
#   predictable. Run `brew upgrade` (or `brew bundle --global`) by hand to bump
#   versions.
# @note `brew bundle`'s exit status is non-zero on partial failures (e.g. an
#   existing differently-versioned cask, or a symlink already placed by
#   mise/corepack). We log and continue so downstream steps (mise, plugins)
#   still run.
#
function install_packages() {
    brew bundle --file="${BREWFILE}" --no-upgrade \
        || echo "WARN: brew bundle reported partial failures — see log above"
}

#
# @description Install the bootstrap-critical Homebrew bundle.
#
function main() {
    require_brew
    install_packages
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main
fi
