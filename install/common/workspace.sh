#!/usr/bin/env bash

# @file install/common/workspace.sh
# @brief Create the unified ~/Workspace project skeleton.
# @description
#   Ensures the project root described in ~/.agents/AGENTS.md exists identically
#   on every device: ~/Workspace/{binlogo,oss,byted}. It only creates the empty
#   category dirs — it never moves, clones, or deletes repos, so migration from
#   the old ~/Developer layout stays a manual, gradual choice. Idempotent.

set -Eeuo pipefail

if [ "${DOTFILES_DEBUG:-}" ]; then
    set -x
fi

readonly WORKSPACE="${HOME}/Workspace"
readonly CATEGORIES=(binlogo oss byted anygen lark)

#
# @description Create each category dir under ~/Workspace if absent.
#
function main() {
    local category
    for category in "${CATEGORIES[@]}"; do
        mkdir -p "${WORKSPACE}/${category}"
    done
    echo "workspace: ensured ${WORKSPACE}/{$(IFS=,; echo "${CATEGORIES[*]}")}"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main
fi
