# dotfiles

Managed by [chezmoi](https://www.chezmoi.io). macOS + zsh + mise.

## Install on a new machine

```sh
# 1. Install Homebrew (https://brew.sh)
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# 2. Install chezmoi and initialize from this repo
brew install chezmoi
chezmoi init --apply Binlogo
```

## Layout

All chezmoi source state lives under `home/` (set by `.chezmoiroot`); the repo
root holds project plumbing (this README, `chezmoi.toml.example`) and the
`install/` scripts. Paths in this first list are relative to `home/`.

- `dot_zshrc.tmpl` / `dot_zprofile` / `dot_zshenv` — zsh configuration
- `dot_gitconfig.tmpl` — git user info is templated
- `private_dot_ssh/config.tmpl` — ssh config (work-only blocks gated on `.work`)
- `dot_config/` — application configs (mise, sheldon, starship, nvim, helix, alacritty, kitty, btop, zellij, karabiner)
- `dot_config/sheldon/plugins.toml` — zsh plugins (autosuggestions, syntax highlighting, OMZ git aliases)

### Provisioning scripts

Install logic lives in standalone, runnable shell scripts under `install/` (at
the repo root, *outside* `.chezmoiroot`, so chezmoi never copies them to `~`).
Each is a small library — doc header, named functions, a `main`, and a
`BASH_SOURCE`/`$0` guard so it also runs directly (`bash install/common/mise.sh`).

Thin chezmoi wrappers in `home/.chezmoiscripts/` pull each body in with
`{{ include "../install/…" }}` and append a hash of the relevant config, so
`chezmoi apply` replays a step only when its script or its config changes:

| Wrapper (`home/.chezmoiscripts/…`) | Includes | Does | Re-runs on |
| --- | --- | --- | --- |
| `macos/run_onchange_before_10-install-packages-darwin.sh.tmpl` | `install/macos/common/brew.sh` | `brew bundle` | the embedded Brewfile |
| `common/run_onchange_after_20-install-runtimes.sh.tmpl` | `install/common/mise.sh` | install `mise` (native) + `mise install` | `dot_config/mise/config.toml` |
| `common/run_onchange_after_25-install-zsh-plugins.sh.tmpl` | `install/common/sheldon.sh` | `sheldon lock` (clone zsh plugins) | `dot_config/sheldon/plugins.toml` |
| `common/run_onchange_after_40-install-plugins.sh.tmpl` | `install/common/claude_plugins.sh` | install Claude Code plugins | `dot_claude/settings.json` |

`before_` runs ahead of file apply (Homebrew installs `sheldon`, `jq`); the
`after_` steps run once those binaries exist. The runtimes step is self-bootstrapping:
it installs `mise` from its native installer (see `install/common/mise.sh`) before
pinning the runtimes, so it no longer depends on Homebrew.

## Plugins workflow

Claude Code plugins are declared in `dot_claude/settings.json` (`enabledPlugins` +
`extraKnownMarketplaces`). Because `enabledPlugins` only *toggles* a plugin and never
downloads it, the `after_40` plugins wrapper (→ `install/common/claude_plugins.sh`)
registers each declared marketplace and installs each enabled plugin on a fresh
machine. To add one:

```sh
claude plugin marketplace add <owner/repo>          # e.g. jarrodwatts/claude-hud
claude plugin install <plugin>@<marketplace> --scope user
```

Then mirror the marketplace + plugin into `dot_claude/settings.json` and commit. Both CLI
calls are idempotent, so the run_onchange script is safe to replay.

## Template data

Real user identity and any secrets live in `~/.config/chezmoi/chezmoi.toml` and are **never** committed. See `chezmoi.toml.example` for the expected shape.

## Philosophy

- Language runtimes (node / ruby / python / go / java) are managed by **mise**, declared in `dot_config/mise/config.toml`.
- `brew` installs tooling; `mise` installs interpreters. No overlap. `mise` itself is installed from its native installer ([mise.run](https://mise.run)), **not** Homebrew — jdx bakes binary optimizations into the release builds that Homebrew's build can't reproduce, and native builds keep `mise self-update`.
- The shell is **frameless zsh** — no oh-my-zsh. **sheldon** (a brew-installed plugin manager) loads plugins from `dot_config/sheldon/plugins.toml`; the prompt is **starship**. Tool hooks (direnv, zoxide, fzf, mise) are plain one-liners in `dot_zshrc.tmpl`.
