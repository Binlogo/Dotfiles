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

- `dot_zshrc.tmpl` / `dot_zprofile` / `dot_zshenv` — zsh configuration
- `dot_gitconfig.tmpl` — git user info is templated
- `private_dot_ssh/config.tmpl` — ssh config (work-only blocks gated on `.work`)
- `dot_config/` — application configs (mise, starship, nvim, helix, alacritty, kitty, btop, zellij, karabiner)
- `dot_agents/dot_skill-lock.json` — Claude Code skills manifest (managed by `npx skills`)
- `run_onchange_before_10-install-packages-darwin.sh.tmpl` — `brew bundle`
- `run_onchange_after_20-install-runtimes.sh.tmpl` — `mise install`
- `run_onchange_after_30-install-skills.sh.tmpl` — restore Claude Code skills from the lock file
- `run_onchange_after_40-install-plugins.sh.tmpl` — install Claude Code plugins declared in `dot_claude/settings.json`

## Skills workflow

Claude Code skills live at `~/.agents/skills/` (symlinked into `~/.claude/skills/`). Only
the lock file is committed — skill content comes from upstream GitHub repos. To add/update:

```sh
npx skills add <owner/repo> -g -a claude-code -s <name>   # install
npx skills update                                         # refresh all
chezmoi re-add ~/.agents/.skill-lock.json                 # pull lock into source
```

Then commit the updated `dot_agents/dot_skill-lock.json`. On a fresh machine,
`run_onchange_after_30-install-skills.sh.tmpl` replays the lock.

## Plugins workflow

Claude Code plugins are declared in `dot_claude/settings.json` (`enabledPlugins` +
`extraKnownMarketplaces`). Because `enabledPlugins` only *toggles* a plugin and never
downloads it, `run_onchange_after_40-install-plugins.sh.tmpl` registers each declared
marketplace and installs each enabled plugin on a fresh machine. To add one:

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
- `brew` installs tooling; `mise` installs interpreters. No overlap.
