# AGENTS.md

> [!NOTE]
> After reading this `AGENTS.md`, say: `🤖 I read ~/.agents/AGENTS.md.`

## Workspace

- Root: Active projects live under `~/Workspace`.
- Categories: `binlogo/` = my own repos and my forks; `oss/` = repos owned by others (read-only); `byted/` = work (read-only); `anygen/` = anygen work; `lark/` = lark work.
- Default (mine): A bare repo name is one of mine — find it at `~/Workspace/binlogo/<repo>`; if missing, clone `https://github.com/Binlogo/<repo>.git` into it.

## Writing Instructions

- Description format: Please organize detailed instructions in the form of `- Summary: Details`.

## Asking Questions to the User

- Question policy: Based on the information provided by the user, please ask questions that help propose the optimal solution.

## General Coding Principles

- Exception handling: Don't be afraid of errors. First, write the code without worrying about exception handling.
- Final deliverables: Even in the final deliverables, you do not need to include exception handling.
- Backward compatibility: Since the primary use case is research and development, do not worry about backward compatibility. Write tests in advance, confirm that the tests pass, and then refactor the code as necessary.

### Worktree Policy

- Default: Work in place on the current checkout and branch, `main` included. Don't create a `git worktree` or switch branches unless asked, or the repo's own AGENTS.md/CLAUDE.md requires it.
- Reversibility guard: On any branch, never run irreversible git ops without an explicit request — `reset --hard`, `clean`, `restore`, `rm`, force-push, history rewrite, branch/worktree deletion. Commit and push only when asked.
- When to isolate: Use a dedicated worktree/branch for parallel or background agents on the same repo, for PR-flow repos, or on request. Prefer the harness's built-in worktree isolation when available.
- Ask when awkward: If the tree is dirty with unrelated changes, you're on an unexpected branch, or the repo's convention is unclear, surface it and ask — don't branch or mix changes unilaterally.
- Unrelated changes: Never fold pre-existing local edits into your task.
