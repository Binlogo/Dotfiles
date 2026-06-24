# AGENTS.md

> [!NOTE]
> After reading this `AGENTS.md`, say: `🤖 I read the project-level AGENTS.md for Binlogo/Dotfiles.`

## Repository Context

- Tooling: This repository is managed with [`chezmoi`](https://www.chezmoi.io/) ([GitHub](https://github.com/twpayne/chezmoi)).
- Public source: Files under `home/` are the public source state and are applied by `chezmoi` into the user's `$HOME` directory.
- Private source: Private dotfiles live in a separate private repo, [`Binlogo/Dotfiles-Private`](https://github.com/Binlogo/Dotfiles-Private), checked out at `~/.local/share/chezmoi-private` with config at `~/.config/chezmoi-private/chezmoi.yaml`. Invoke it via the `cmp` alias defined in `home/dot_zshrc.tmpl` (`cmp = chezmoi --config ~/.config/chezmoi-private/chezmoi.yaml`).
- Management boundary: Treat the public `home/` tree and the private `chezmoi` source/config as separate management domains. Each has its own git repo, config, and chezmoi state; never manage the same `$HOME` target path in both sources.
