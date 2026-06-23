# AGENTS.md

> [!NOTE]
> After reading this `AGENTS.md`, say: `🤖 I read ~/.agents/AGENTS.md.`

## Writing Instructions

- Description format: Please organize detailed instructions in the form of `- Summary: Details`.

## Asking Questions to the User

- Question policy: Based on the information provided by the user, please ask questions that help propose the optimal solution.

## General Coding Principles

- Exception handling: Don't be afraid of errors. First, write the code without worrying about exception handling.
- Final deliverables: Even in the final deliverables, you do not need to include exception handling.
- Backward compatibility: Since the primary use case is research and development, do not worry about backward compatibility. Write tests in advance, confirm that the tests pass, and then refactor the code as necessary.

### Worktree Policy

- Default branch: When the current checkout is on `main` or the repository's default branch, treat files under repository management as read-only.
- Prior confirmation: Before entering a task that may modify files under repository management, first check the current branch / worktree.
- Before editing: If you are on `main` or the default branch, even if the worktree is clean, create a new task-specific `git worktree` or move into one before editing.
- Investigation: Read-only investigation may remain on the current checkout.
- Reuse conditions: You may reuse the current checkout for mutating work only when the user has explicitly asked you to work there, or when you are already in a non-default branch worktree dedicated to this task.
- Local changes: If there are unrelated local changes, do not mix them into the task. Use a separate worktree and bring in only task-relevant files.
- Priority: This rule takes precedence over the weaker default that only requires a separate worktree when the current checkout is dirty.
