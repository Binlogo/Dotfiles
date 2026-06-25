# Converge Skill Management into agent-skills — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make `Binlogo/agent-skills` the single declaration + activation point for all skills (authored + consumed third-party), so chezmoi only orchestrates `agent-skills` and the full skill set is reproducible from a clean checkout.

**Architecture:** `agent-skills/install.sh` runs two phases — phase 1 symlinks authored `skills/*` (unchanged), phase 2 replays a committed `consumed.skills` manifest via `npx skills add -g`. chezmoi clones `agent-skills` and runs `install.sh` (already wired); the only chezmoi edit is putting mise's node/npx on PATH so phase 2 can run during bootstrap.

**Tech Stack:** POSIX `sh` (install.sh), bash (chezmoi run scripts), the `skills` CLI (`npx skills`, v1.5.x), chezmoi, mise (node).

## Global Constraints

- Two repos: `~/.local/share/agent-skills` (manifest, install.sh, docs) and `~/.local/share/chezmoi` (PATH fix, this plan/spec). Both on `main`; commit + push both (user authorized).
- `agent-skills/AGENTS.md`: keep the repo root lean — only `consumed.skills` is added at root; no other scaffolding.
- `install.sh` is POSIX `sh` (`#!/usr/bin/env sh`, `set -eu`). Phase 1 logic is untouched.
- Manifest grammar: `<owner/repo>[#ref]  [skill ...]`; `#`-lines and blanks ignored; no skills ⇒ all skills in repo.
- Phase 2 is additive + best-effort: a failing source warns and continues; missing `npx` warns and skips; phase 1 must always still succeed.
- Lark = bare `larksuite/cli` line (all lark skills).
- Authored and consumed skill name-sets are disjoint; the two phases never touch the same hub path.
- Conventional Commits, scoped (`feat(skills):`, `fix(zsh):`/`build:` etc.).

---

### Task 1: Add the `consumed.skills` manifest

**Files:**
- Create: `~/.local/share/agent-skills/consumed.skills`

**Interfaces:**
- Produces: a manifest read by `install.sh` phase 2 (Task 2). First whitespace field = source (`owner/repo[#ref]`); remaining fields = skill names; `#` starts a comment.

- [ ] **Step 1: Write the manifest file**

```
# consumed.skills — third-party skills, replayed by install.sh phase 2 via
# `npx skills add -g`. Authored skills are NOT listed here; they are symlinked
# from ./skills by phase 1. Format:  <owner/repo>[#ref]  [skill ...]  (no skills = all)

larksuite/cli                                                          # all lark-* skills
kepano/obsidian-skills      defuddle json-canvas obsidian-bases obsidian-cli obsidian-markdown
mattpocock/skills           grill-me grill-with-docs improve-codebase-architecture prototype tdd to-issues to-prd triage write-a-skill
anthropics/skills           skill-creator
anthropics/claude-plugins-official   claude-md-improver
shadcn/improve              improve
pbakaus/impeccable          impeccable
vercel-labs/skills          find-skills
```

- [ ] **Step 2: Verify it parses with the same shell logic phase 2 will use**

Run:
```bash
cd ~/.local/share/agent-skills
while IFS= read -r line || [ -n "$line" ]; do
  case "$line" in ''|'#'*) continue ;; esac
  line=${line%%#*}; set -- $line; [ "$#" -ge 1 ] || continue
  src=$1; shift; echo "source=$src skills=[$*]"
done < consumed.skills
```
Expected: 8 lines; `source=larksuite/cli skills=[]`; others list their skills; no comment/blank lines.

---

### Task 2: Add phase 2 to `agent-skills/install.sh`

**Files:**
- Modify: `~/.local/share/agent-skills/install.sh` (append after the phase-1 loop + summary `printf`)

**Interfaces:**
- Consumes: `consumed.skills` (Task 1), `repo_dir` (already defined at top of install.sh), `npx skills` CLI.
- Produces: consumed skills materialized into `~/.agents/skills` and detected agent dirs by the CLI.

- [ ] **Step 1: Append the phase-2 block**

Add to the end of `install.sh` (after the existing `printf 'agent-skills: linked ...'` line). Note phase-1 comment rename to `phase 1` is optional polish; the new block:

```sh

# --- phase 2: consumed third-party skills (declarative, CLI-fetched) ---------
# Reproducibility lives in ./consumed.skills, not in an imperative install. The
# skills CLI still fetches/updates; this just replays the committed manifest.
manifest="${repo_dir}/consumed.skills"
if [ -f "$manifest" ]; then
    if ! command -v npx >/dev/null 2>&1; then
        printf 'agent-skills: npx not found — skipping consumed skills (re-run after node is on PATH)\n' >&2
    else
        consumed=0
        while IFS= read -r line || [ -n "$line" ]; do
            case "$line" in ''|'#'*) continue ;; esac
            line=${line%%#*}                 # strip inline comments
            # shellcheck disable=SC2086      # intentional word-split into fields
            set -- $line
            [ "$#" -ge 1 ] || continue
            source=$1; shift
            if [ "$#" -ge 1 ]; then
                skills=$(printf '%s,' "$@"); skills=${skills%,}
                if npx skills add -g "$source" -s "$skills" -y; then
                    consumed=$((consumed + 1))
                else
                    printf 'warn  consumed: %s failed (continuing)\n' "$source" >&2
                fi
            else
                if npx skills add -g "$source" -y; then
                    consumed=$((consumed + 1))
                else
                    printf 'warn  consumed: %s failed (continuing)\n' "$source" >&2
                fi
            fi
        done < "$manifest"
        printf 'agent-skills: processed %d consumed source(s) from consumed.skills\n' "$consumed"
    fi
fi
```

- [ ] **Step 2: Lint the script**

Run: `shellcheck ~/.local/share/agent-skills/install.sh || true` (advisory; the SC2086 split is intentional and disabled inline).
Expected: no errors beyond the disabled SC2086.

- [ ] **Step 3: Verify phase 2 end-to-end in a scratch HOME (non-destructive)**

Run:
```bash
SB=$(mktemp -d)
HOME="$SB" PATH="$HOME/.local/share/mise/shims:$PATH" \
  HOME="$SB" ~/.local/share/agent-skills/install.sh
ls -la "$SB/.agents/skills" | head -40
```
Expected: authored skills appear as symlinks; a sampling of consumed skills (e.g. `defuddle`, `improve`, `lark-base`, `grill-me`) appear; final line reports processed consumed sources. (Uses the real CLI + network; allow time.)

- [ ] **Step 4: Verify idempotency**

Run the same scratch-HOME command a second time.
Expected: completes without error; no duplicate/garbage entries.

- [ ] **Step 5: Clean up scratch HOME**

Run: `rm -rf "$SB"`

---

### Task 3: chezmoi PATH fix so phase 2 runs during bootstrap

**Files:**
- Modify: `~/.local/share/chezmoi/install/common/agent_skills.sh:21`

**Interfaces:**
- Consumes: mise shims at `~/.local/share/mise/shims` (created by runtimes script `20`, which runs before this script `50`).
- Produces: `npx` resolvable when `agent_skills.sh` invokes `agent-skills/install.sh` phase 2.

- [ ] **Step 1: Prepend mise shims to PATH**

Change line 21 from:
```sh
export PATH="/opt/homebrew/bin:${HOME}/.local/bin:${PATH}"
```
to:
```sh
# mise shims first so phase 2 of each repo's install.sh can find node/npx.
export PATH="${HOME}/.local/share/mise/shims:/opt/homebrew/bin:${HOME}/.local/bin:${PATH}"
```

- [ ] **Step 2: Verify npx resolves with this exact PATH**

Run:
```bash
env -i HOME="$HOME" PATH="${HOME}/.local/share/mise/shims:/opt/homebrew/bin:${HOME}/.local/bin:/usr/bin:/bin" \
  sh -c 'command -v npx && npx -v'
```
Expected: prints the shim path and a node-npx version (e.g. `11.x`).

- [ ] **Step 3: Verify the inlined wrapper still renders**

Run: `cd ~/.local/share/chezmoi && chezmoi cat ~/.local/share 2>/dev/null; chezmoi execute-template < home/.chezmoiscripts/common/run_onchange_after_50-link-agent-skills.sh.tmpl | head -30`
Expected: the rendered script includes the edited PATH line.

---

### Task 4: Converge this machine + reconcile lark source

**Files:** none (runtime state on this machine)

**Interfaces:**
- Consumes: the edited `install.sh` (Task 2), `consumed.skills` (Task 1).
- Produces: this machine's hub converged; `~/.agents/.skill-lock.json` re-sources lark from `larksuite/cli`.

- [ ] **Step 1: Snapshot current hub + lock**

Run:
```bash
cp ~/.agents/.skill-lock.json /tmp/skill-lock.before.json
ls -la ~/.agents/skills > /tmp/hub.before.txt
```

- [ ] **Step 2: Run install.sh against the real HOME**

Run: `~/.local/share/agent-skills/install.sh`
Expected: phase-1 summary (authored linked), phase-2 processes 8 sources; lark re-installed from `larksuite/cli`.

- [ ] **Step 3: Confirm lark re-sourced to GitHub**

Run: `python3 -c "import json;d=json.load(open('$HOME/.agents/.skill-lock.json'));print({n:e['source'] for n,e in d['skills'].items() if n.startswith('lark-')})" | tr ',' '\n' | head`
Expected: lark-* entries now show `source: larksuite/cli` (not `open.feishu.cn`).

- [ ] **Step 4: Confirm authored symlinks intact**

Run: `ls -la ~/.agents/skills | grep -E 'apple-app-design-guidelines|calm-dense-design|native-feel-desktop'`
Expected: all three are symlinks into `~/.local/share/agent-skills/skills/`.

---

### Task 5: Update agent-skills docs

**Files:**
- Modify: `~/.local/share/agent-skills/README.md` (Authoring section)
- Modify: `~/.local/share/agent-skills/AGENTS.md` (Install model section)

**Interfaces:** none (documentation).

- [ ] **Step 1: README — document the manifest + two phases**

Add to the Authoring/Install model area a short subsection: `install.sh` runs phase 1 (symlink authored `skills/*`, live edits) and phase 2 (replay `consumed.skills` via `npx skills add -g`). To add a consumed skill: add a line to `consumed.skills`, run `./install.sh`, commit. Note authored skills are NOT in the manifest.

- [ ] **Step 2: AGENTS.md — extend the Install model section**

State that consumed third-party skills are declared in `consumed.skills` (one `owner/repo[#ref] [skill ...]` per line) and reproduced by `install.sh` phase 2; chezmoi orchestrates only this repo. Keep root lean: `consumed.skills` is the only new root file.

- [ ] **Step 3: Verify both files reference `consumed.skills`**

Run: `grep -l consumed.skills ~/.local/share/agent-skills/README.md ~/.local/share/agent-skills/AGENTS.md`
Expected: both paths listed.

---

### Task 6: Commit, push both repos, update memory

**Files:**
- Modify: `~/.claude/projects/-Users-wangxingbin--local-share-chezmoi/memory/agent-skills-management.md`

- [ ] **Step 1: Commit agent-skills**

```bash
cd ~/.local/share/agent-skills
git add consumed.skills install.sh README.md AGENTS.md
git commit -m "feat(skills): declare consumed skills in consumed.skills, install via phase 2"
```

- [ ] **Step 2: Commit chezmoi PATH fix + this plan**

```bash
cd ~/.local/share/chezmoi
git add install/common/agent_skills.sh docs/superpowers/plans/2026-06-25-converge-skills-into-agent-skills.md
git commit -m "fix(skills): put mise node/npx on PATH for agent-skills phase-2 bootstrap"
```

- [ ] **Step 3: Push both**

```bash
cd ~/.local/share/agent-skills && git push
cd ~/.local/share/chezmoi && git push
```
Expected: both push to their `main` on GitHub (so the office device can relay).

- [ ] **Step 4: Update the agent-skills-management memory**

Record: consumed set now declared in `consumed.skills` (public agent-skills repo) and reproduced by `install.sh` phase 2; lark re-sourced from `larksuite/cli` (well-known dropped); chezmoi adds mise shims to PATH for bootstrap.

---

## Self-Review

- **Spec coverage:** §1 layering → Tasks 2,3; §2 manifest → Task 1; §3 phase 2 → Task 2; §4 PATH fix → Task 3; §4 migration → Task 4; §5 docs → Task 5; memory → Task 6. All covered.
- **Placeholders:** none — manifest, phase-2 code, and PATH line are literal.
- **Type/name consistency:** `consumed.skills`, `repo_dir`, `manifest`, `source`/`skills` vars consistent across Tasks 1–2; PATH string in Task 3 matches Task 2 Step 3's scratch invocation.
