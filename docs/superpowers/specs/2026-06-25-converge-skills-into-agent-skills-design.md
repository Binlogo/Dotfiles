# Converge skill management into `agent-skills`, orchestrated by chezmoi

**Date:** 2026-06-25
**Status:** Design — approved for planning
**Repos touched:** `Binlogo/agent-skills` (most changes) + `Binlogo/Dotfiles` (chezmoi, one touch)

## Problem

Skill activation is split across two mechanisms with two reproducibility stories:

- **Authored skills** (3: `apple-app-design-guidelines`, `calm-dense-design`,
  `native-feel-desktop`) are live **symlinks** from `~/.local/share/agent-skills`
  into the `~/.agents/skills` hub (and `~/.claude/skills`), created by that repo's
  `install.sh`. chezmoi bootstraps this repo, so authored skills are reproducible.
- **Consumed third-party skills** (~45 in the lock; ~30 materialized) are **copies**
  installed imperatively by the `skills` CLI and tracked only in
  `~/.agents/.skill-lock.json`. They are **not** part of any chezmoi-driven
  bootstrap — a fresh machine gets the 3 authored skills and none of the consumed
  ones.

**Goal:** make `agent-skills` the single declaration + orchestration point for
*both* categories, so chezmoi only ever talks to `agent-skills`, and the full skill
set is reproducible from a clean checkout. The `skills` CLI keeps doing the
fetching/updating.

## Decisions (locked during brainstorming)

1. **Primary outcome:** reproducibility of the consumed set (declare it in
   `agent-skills`; CLI still fetches). Not vendoring, not uniform-activation.
2. **One public manifest** in `Binlogo/agent-skills` covering all consumed skills.
   No `agent-skills-private` split needed yet.
3. **Mechanism:** a human-readable manifest replayed via `skills add -g` (Approach A).
   Rejected: committing the CLI lock + `experimental_install` (experimental,
   project-scoped, no real pin gain); vendoring everything (heaviest, contradicts
   "least machinery").
4. **All consumed skills are GitHub-sourced.** The lark set lives at
   `larksuite/cli/skills/` (27 skills) — the `open.feishu.cn` well-known source is
   dropped. Manifest is uniform `owner/repo` lines.
5. **Lark scope:** bare `larksuite/cli` line = all lark skills (auto-adopts new ones
   like `lark-note` on re-run). Matches the official `npx skills add larksuite/cli -y -g`.

## Architecture

Two layers, each with one responsibility:

```
chezmoi run_onchange (50-link-agent-skills)
   └─ install/common/agent_skills.sh
        for repo in AGENT_SKILL_REPOS:        # ["Binlogo/agent-skills"]
          ensure_clone  ~/.local/share/<repo>
          run_installer ~/.local/share/<repo>/install.sh
                                   │
                                   ▼
        agent-skills/install.sh
          phase 1  symlink skills/*  →  ~/.agents/skills/<name>  (+ ~/.claude/skills)   [UNCHANGED]
          phase 2  read consumed.skills; per line: npx skills add -g <source> [-s ...] -y [NEW]
                                   │
                ┌──────────────────┴───────────────────┐
            authored (mine, symlinks)        consumed (3rd-party, CLI-managed copies)
                └───────────────▶ ~/.agents/skills hub ◀──────────────┘
                                        (+ ~/.claude/skills, fanned out by the CLI)
```

- **chezmoi** never learns about individual skills or sources. Its repo list
  (`AGENT_SKILL_REPOS`) and wrapper script are unchanged in shape; the only edit is
  the PATH fix below.
- **`agent-skills`** owns the entire declaration. Phase 1 is today's symlink logic,
  untouched. Phase 2 is new and additive.

## Component 1 — the manifest: `agent-skills/consumed.skills`

A committed text file at the repo root. Grammar, one entry per line:

```
<owner/repo>[#<ref>]   [<skill> <skill> ...]
```

- Blank lines and `#`-prefixed lines are comments/ignored.
- No skill names after the source ⇒ install **all** skills in that repo.
- Optional `#ref` (tag/branch/SHA) pins a source; omitted ⇒ latest. Pinning is
  opt-in per line — the default is "same set, latest versions," which is the
  reproducibility target chosen.

Initial contents (derived from the current lock, lark re-sourced to GitHub):

```
# Consumed third-party skills. chezmoi → agent-skills/install.sh replays this with
# `npx skills add -g`. Authored skills are NOT listed here — they are symlinked from
# ./skills by phase 1. Format:  <owner/repo>[#ref]  [skill ...]   (no skills = all)

larksuite/cli                                                          # all lark-* skills
kepano/obsidian-skills      defuddle json-canvas obsidian-bases obsidian-cli obsidian-markdown
mattpocock/skills           grill-me grill-with-docs improve-codebase-architecture prototype tdd to-issues to-prd triage write-a-skill
anthropics/skills           skill-creator
anthropics/claude-plugins-official   claude-md-improver
shadcn/improve              improve
pbakaus/impeccable          impeccable
vercel-labs/skills          find-skills
```

> Note: the per-repo skill subsets for the OSS sources are taken from the current
> `~/.agents/.skill-lock.json`. At implementation time, reconcile against what is
> actually materialized in the hub and drop any entries that are no longer wanted.

## Component 2 — `install.sh` phase 2

Appended to the existing `agent-skills/install.sh` (POSIX `sh`, same style):

```sh
# --- phase 2: consumed third-party skills (declarative, CLI-fetched) ---------
manifest="${repo_dir}/consumed.skills"
if [ -f "$manifest" ]; then
    # Read non-blank, non-comment lines: first field = source, rest = skill names.
    while IFS= read -r line || [ -n "$line" ]; do
        case "$line" in ''|'#'*) continue ;; esac
        # strip inline comments and surrounding whitespace
        line=${line%%#*}
        set -- $line
        [ "$#" -ge 1 ] || continue
        source=$1; shift
        if [ "$#" -ge 1 ]; then
            skills=$(printf '%s,' "$@"); skills=${skills%,}
            npx skills add -g "$source" -s "$skills" -y || \
                printf 'warn  consumed: %s failed (continuing)\n' "$source" >&2
        else
            npx skills add -g "$source" -y || \
                printf 'warn  consumed: %s failed (continuing)\n' "$source" >&2
        fi
    done < "$manifest"
fi
```

Properties:

- **Idempotent / additive** — re-running re-adds the same set; the CLI no-ops or
  updates in place, mirroring phase 1's contract.
- **Best-effort** — a single unreachable source logs a warning and continues; it
  must not abort the chezmoi run.
- **Agent fan-out is delegated to the CLI** — `add -g` (no `-a`) auto-detects all
  installed agents (universal hub + `~/.claude/skills`), exactly like the official
  lark command.

## Component 3 — chezmoi PATH fix (the one chezmoi-side change)

`install/common/agent_skills.sh` currently exports only
`PATH=/opt/homebrew/bin:~/.local/bin:$PATH`. During bootstrap, node/npx live under
mise (`~/.local/share/mise/installs/node/lts/bin`) and are **not** on that PATH, so
phase 2's `npx` would not resolve. Ordering already guarantees node *exists* by then
(runtimes script `20` < this script `50`); we only need it on PATH.

Fix (pick the most robust at implementation; preference order):

1. Activate mise for the script: `eval "$(mise activate bash --shims)"` or prepend
   `~/.local/share/mise/shims` to PATH, if that shims dir is populated for node.
2. Otherwise invoke the CLI through mise inside `install.sh`: `mise exec node@lts -- npx skills ...`.

Guard: if neither node nor `mise` is found, phase 2 logs a warning and skips
(consumed skills install on next `chezmoi apply` once runtimes are present) — phase 1
(authored symlinks) must always still succeed.

## Migration / one-time reconciliation

The existing hub holds `lark-*` as copies sourced from `open.feishu.cn`
(`sourceType: well-known`). We are re-sourcing them from `larksuite/cli` (GitHub).

1. Snapshot current hub state (`ls -la ~/.agents/skills`, copy `~/.agents/.skill-lock.json`).
2. Remove the stale well-known-sourced lark entries so the CLI re-materializes them
   from GitHub: `npx skills remove -g -s '<lark list>' -y` (or remove the lark hub
   dirs by hand), leaving authored symlinks and other consumed skills intact.
3. Run `agent-skills/install.sh` and confirm:
   - all lark-* reappear, now sourced from `larksuite/cli` in `.skill-lock.json`;
   - authored symlinks (phase 1) are unchanged;
   - the OSS consumed set is present.
4. Commit the manifest + `install.sh` changes in `agent-skills`; commit the PATH fix
   in chezmoi.

## Error handling

- **Offline / unreachable source at bootstrap:** per-line best-effort; warn + continue;
  whole-run never fails on phase 2. Re-running `chezmoi apply` (or `install.sh`)
  later reconciles.
- **No node/npx:** phase 2 skips with a warning; phase 1 unaffected.
- **Non-symlink already in hub:** phase 1 already refuses to clobber CLI-managed
  copies; phase 2 leaves CLI-managed entries to the CLI. The two phases never fight
  over the same path because authored and consumed skill name-sets are disjoint.

## Verification

- **Fresh-machine simulation:** in a scratch `HOME`, clone `agent-skills`, ensure
  node on PATH, run `install.sh`; assert the hub contains authored symlinks + every
  manifest skill, and `~/.claude/skills` is populated.
- **Idempotency:** run `install.sh` twice; second run produces no errors and no
  unexpected changes.
- **chezmoi dry path:** `chezmoi apply` (or re-trigger the run_onchange) on this
  machine completes without aborting, with node resolved via the PATH fix.
- **Manifest round-trip:** add a throwaway line, re-run, confirm the skill appears;
  remove it, confirm clean state.

## Docs & memory updates

- `agent-skills/README.md` + `AGENTS.md`: document the two-phase / two-audience model
  and the `consumed.skills` manifest as the source of truth for consumed skills.
- Update the `agent-skills-management` memory: consumed set is now declared in
  `consumed.skills` and reproduced by `install.sh` phase 2; lark re-sourced to
  `larksuite/cli`.

## Out of scope

- Claude Code **plugins** (e.g. superpowers) — a separate mechanism, not the skills hub.
- `agent-skills-private` — deferred; not needed under the "all public" decision.
- Bit-exact version pinning across machines — opt-in per line via `#ref`, not a goal.
- Changing the authored-skill symlink model (phase 1) — untouched.
