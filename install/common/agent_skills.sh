#!/usr/bin/env bash

# @file install/common/agent_skills.sh
# @brief Bootstrap the authored agent-skills repos and link their skills.
# @description
#   chezmoi ORCHESTRATES these repos but never owns their files. For each repo
#   it clones the working checkout into ~/.local/share/<name> if missing, then
#   runs that repo's own install.sh, which symlinks each skill into the shared
#   ~/.agents/skills hub (and into ~/.claude/skills). The repos stay
#   independently versioned — see the public repo's AGENTS.md "Install model".
#   Adding the private repo later is a one-line change to AGENT_SKILL_REPOS;
#   because the wrapper inlines this script, that edit re-triggers the run.

set -Eeuo pipefail

if [ "${DOTFILES_DEBUG:-}" ]; then
    set -x
fi

# git from Homebrew, plus the standalone bin dir, in case PATH is not inherited.
export PATH="/opt/homebrew/bin:${HOME}/.local/bin:${PATH}"

# Repos to bootstrap, as "owner/repo". Add the private one when it exists:
#   "Binlogo/agent-skills-private"
readonly AGENT_SKILL_REPOS=(
    "Binlogo/agent-skills"
)

readonly BASE="${HOME}/.local/share"

#
# @description Clone a repo's working checkout if it is not already present.
#
function ensure_clone() {
    local slug="$1" dest="$2"
    if [ -d "${dest}/.git" ]; then
        return 0
    fi
    echo "==> cloning ${slug} -> ${dest}"
    git clone "https://github.com/${slug}.git" "${dest}"
}

#
# @description Run a repo's own installer if it ships an executable one.
#
function run_installer() {
    local dest="$1"
    if [ -x "${dest}/install.sh" ]; then
        "${dest}/install.sh"
    else
        echo "no executable install.sh in ${dest} — skip linking" >&2
    fi
}

#
# @description Clone (if needed) and link every declared agent-skills repo.
#
function main() {
    local slug name dest
    for slug in "${AGENT_SKILL_REPOS[@]}"; do
        name="${slug##*/}"
        dest="${BASE}/${name}"
        ensure_clone "${slug}" "${dest}"
        run_installer "${dest}"
    done
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main
fi
