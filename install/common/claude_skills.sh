#!/usr/bin/env bash

# @file install/common/claude_skills.sh
# @brief Restore Claude Code skills from the skill lockfile.
# @description
#   Reinstalls the Claude Code skills tracked in ~/.agents/.skill-lock.json,
#   grouping them by upstream source and installing only those missing locally.
#   Requires node (via mise) and jq (via the Homebrew bundle). The chezmoi
#   wrapper embeds a hash of the lockfile, so `chezmoi apply` re-runs this
#   whenever the tracked skills change.

set -Eeuo pipefail

if [ "${DOTFILES_DEBUG:-}" ]; then
    set -x
fi

# mise shims (node/npx) first, then Homebrew (jq) and the standalone bin dir.
export PATH="${HOME}/.local/share/mise/shims:/opt/homebrew/bin:${HOME}/.local/bin:${PATH}"

readonly LOCK="${HOME}/.agents/.skill-lock.json"

#
# @description Skip the restore unless the skill lockfile exists.
#
function require_lock() {
    if [[ ! -f "${LOCK}" ]]; then
        echo "skill lock not found at ${LOCK} — skipping" >&2
        exit 0
    fi
}

#
# @description Skip the restore unless jq and npx are both available.
#
function require_tools() {
    for cmd in jq npx; do
        if ! command -v "${cmd}" > /dev/null 2>&1; then
            echo "${cmd} not found in PATH — skip skills restore" >&2
            exit 0
        fi
    done
}

#
# @description Install, per upstream source, only the skills missing locally.
#
function restore_skills() {
    # Group skills by upstream source and install only the ones missing locally.
    jq -r '
      .skills
      | to_entries
      | group_by(.value.source)
      | map({source: .[0].value.source, names: (map(.key))})
      | .[]
      | "\(.source)\t\(.names | join(","))"
    ' "${LOCK}" | while IFS=$'\t' read -r source names; do
        missing=""
        IFS=',' read -r -a arr <<< "${names}"
        for name in "${arr[@]}"; do
            if [[ ! -e "${HOME}/.agents/skills/${name}" ]]; then
                missing="${missing:+${missing},}${name}"
            fi
        done
        if [[ -z "${missing}" ]]; then
            echo "==> ${source}: already installed"
            continue
        fi
        echo "==> installing from ${source}: ${missing}"
        npx -y skills add "${source}" -g -a claude-code -s "${missing}" -y \
            || echo "WARN: failed to install from ${source} (${missing})" >&2
    done
}

#
# @description Restore the Claude Code skills declared in the lockfile.
#
function main() {
    require_lock
    require_tools
    restore_skills
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main
fi
