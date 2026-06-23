#!/usr/bin/env bash

# @file install/common/claude_plugins.sh
# @brief Restore Claude Code plugins declared in settings.json.
# @description
#   `enabledPlugins` only TOGGLES a plugin on/off — it does not download it. A
#   fresh machine therefore needs each third-party marketplace registered and
#   each enabled plugin explicitly installed. Both `claude plugin marketplace
#   add` and `claude plugin install` are idempotent, so this is safe to replay.
#   Requires the `claude` CLI (in PATH) and jq (via the Homebrew bundle). The
#   chezmoi wrapper embeds a hash of settings.json, so `chezmoi apply` re-runs
#   this whenever the declared plugins change.

set -Eeuo pipefail

if [ "${DOTFILES_DEBUG:-}" ]; then
    set -x
fi

# mise shims (claude) first, then Homebrew (jq) and the standalone bin dir.
export PATH="${HOME}/.local/share/mise/shims:/opt/homebrew/bin:${HOME}/.local/bin:${PATH}"

readonly SETTINGS="${HOME}/.claude/settings.json"

#
# @description Skip the restore unless claude and jq are both available.
#
function require_tools() {
    for cmd in claude jq; do
        if ! command -v "${cmd}" > /dev/null 2>&1; then
            echo "${cmd} not found in PATH — skip plugin restore" >&2
            exit 0
        fi
    done
}

#
# @description Skip the restore unless settings.json exists.
#
function require_settings() {
    if [[ ! -f "${SETTINGS}" ]]; then
        echo "no settings.json at ${SETTINGS} — skip" >&2
        exit 0
    fi
}

#
# @description Register any extra marketplaces declared in settings (idempotent).
#
function register_marketplaces() {
    jq -r '(.extraKnownMarketplaces // {}) | to_entries[] | .value.source.repo // empty' "${SETTINGS}" \
        | while read -r repo; do
            [[ -z "${repo}" ]] && continue
            echo "==> marketplace add ${repo}"
            claude plugin marketplace add "${repo}" 2>&1 || echo "WARN: marketplace add ${repo} failed" >&2
        done
}

#
# @description Install each enabled plugin that is not already present.
#
function install_plugins() {
    local installed
    installed="$(claude plugin list 2>/dev/null || true)"
    jq -r '(.enabledPlugins // {}) | to_entries[] | select(.value == true) | .key' "${SETTINGS}" \
        | while read -r plugin; do
            if printf '%s\n' "${installed}" | grep -qF "${plugin}"; then
                echo "==> ${plugin}: already installed"
            else
                echo "==> installing ${plugin}"
                claude plugin install "${plugin}" --scope user 2>&1 \
                    || echo "WARN: failed to install ${plugin}" >&2
            fi
        done
}

#
# @description Restore the Claude Code marketplaces and plugins from settings.
#
function main() {
    require_tools
    require_settings
    register_marketplaces
    install_plugins
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main
fi
