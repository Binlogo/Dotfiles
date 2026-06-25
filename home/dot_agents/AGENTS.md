# AGENTS.md

> [!NOTE]
> After reading this `AGENTS.md`, say: `🤖 I read ~/.agents/AGENTS.md.`

## Workspace

- Root: Active projects live under `~/Workspace`.
- Categories: `binlogo/` = my own repos and my forks; `oss/` = repos owned by others (read-only); `byted/` = work (read-only); `anygen/` = anygen work; `lark/` = lark work.
- Default (mine): A bare repo name is one of mine — find it at `~/Workspace/binlogo/<repo>`; if missing, clone `https://github.com/Binlogo/<repo>.git` into it.

## Writing Instructions

- Description format: Please organize detailed instructions in the form of `- Summary: Details`.
- Scope: Keep this file to hard rules; detailed, repeatable workflows belong in skills, not here.

## Asking Questions to the User

- Question policy: Based on the information provided by the user, please ask questions that help propose the optimal solution.

## Safety

- Confidentiality: Never expose, infer, or publish non-public organizational information — internal project/codenames, systems, infrastructure, processes, credentials, URLs, datasets, or personnel. Treat it as confidential unless I confirm it is public. In public repos (chezmoi, skills) and shared output, replace sensitive internal names with neutral codenames (e.g. `anygen`) and keep sensitive detail in the private repo.
- Secrets: Never run `env`, `set`, `export -p`, or broad secret/regex dumps. Query exact variable names only and redact values. Pull credentials from the password manager, not by enumerating the environment.

## General Coding Principles

- Exception handling: Don't be afraid of errors — skip exception handling in drafts and final deliverables alike (R&D).
- Backward compatibility: Since the primary use case is research and development, do not worry about backward compatibility. Write tests in advance, confirm that the tests pass, and then refactor the code as necessary.
- Toolchain: Use the repo's existing package manager and language runtime; don't swap them without approval.
- Bugs: Add a regression test when it fits.
- Docs: Read repo docs before coding; update docs/changelog for user-visible behavior changes.
- New deps: Do a quick health check (recent releases, commits, adoption) before adding one.
- zsh: Don't use `status` as a variable name; iterate multi-item lists as arrays — zsh scalars don't word-split like bash.

## Git

- Commits: Conventional Commits (`feat|fix|refactor|build|ci|chore|docs|style|perf|test`), scoped — e.g. `feat(zsh): …`.
- Concurrent agents: Unrecognized or pre-existing working-tree changes are likely another agent or unrelated work — never fold them into your task, focus only your own changes, and stop to ask if they conflict or break things.

### Worktree Policy

- Default: Work in place on the current checkout and branch, `main` included. Don't create a `git worktree` or switch branches unless asked, or the repo's own AGENTS.md/CLAUDE.md requires it.
- Reversibility guard: On any branch, never run irreversible git ops without an explicit request — `reset --hard`, `clean`, `restore`, `rm`, force-push, history rewrite, branch/worktree deletion. Commit and push only when asked.
- When to isolate: Use a dedicated worktree/branch for parallel or background agents on the same repo, for PR-flow repos, or on request. Prefer the harness's built-in worktree isolation when available.
- Location: Place hand-made worktrees at `~/Workspace/<category>/<repo>-worktrees/<branch>` — a single sibling dir per repo, mirroring the branch name (slashes allowed, e.g. `feat/foo`). Never scatter them as flat `<repo>-<ticket>` siblings or a shared top-level `worktrees/`.
- Tool-managed worktrees: Worktrees created by external tools keep their own roots (e.g. `~/conductor/workspaces/<repo>/…`, `~/.codex/worktrees/…`) — leave them there; don't force them into the Workspace convention or relocate them.
- Ask when awkward: If you're on an unexpected branch or the repo's convention is unclear, surface it and ask — don't switch branches unilaterally.
