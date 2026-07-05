# AGENTS.md

Personal dotfiles repository managing macOS and Linux (Fedora) configurations via GNU Stow symlinks.

## Machines

Deployed on multiple machines — a MacBook Pro (Apple Silicon, macOS) and a Fedora Workstation 44 (GNOME) desktop, as of 2026-07. Never assume which one you are on; check `uname -s` before platform-specific work. Shared config (`zsh/`, `nvim/`, `tmux/`, etc.) must stay cross-platform: branch on `uname` inside the config rather than forking per-machine files.

## Commands

### Bootstrap (full setup)

```bash
./bootstrap.sh              # detect OS, install packages, stow all
./bootstrap.sh --skip-install  # stow only, no package install
```

### Stow operations

```bash
stow <package>        # deploy one package
stow */               # deploy all packages
stow -D <package>     # remove symlinks for a package
stow -n <package>     # dry-run — check for conflicts before deploying
```

### Package installation (standalone)

```bash
cd commands
./install_deps_mac.sh                    # macOS — Homebrew
./install_deps_fedora.sh                 # Fedora Workstation — dnf
```

## Directory Structure

Each top-level directory is an independent Stow package. Stow maps its contents to `~/` or `~/.config/`.

Example: `zsh/.zshrc` → `~/.zshrc`, `nvim/.config/nvim/` → `~/.config/nvim/`

### Cross-platform

| Package | Purpose |
|---------|---------|
| `zsh/` | Zsh shell (zinit, oh-my-posh star theme, fzf-tab, catppuccin) |
| `nvim/` | Neovim (LazyVim-based, plugins in `nvim/.config/nvim/lua/`) |
| `tmux/` | tmux (prefix `Ctrl+s`, TPM, vim-tmux-navigator, catppuccin mocha) |
| `git/` | Git config (SSH commit signing via `gpg.format = ssh`) |
| `ghostty/` | Ghostty terminal |
| `fonts/` | Nerd Fonts |
| `backgrounds/` | Wallpapers |

### macOS only

| Package | Purpose |
|---------|---------|
| `aerospace/` | AeroSpace tiling window manager |

### Other

| Package | Purpose |
|---------|---------|
| `commands/` | Package install scripts and package lists |
| `codex/` | Codex settings and skills (stowed to `~/.codex/`) |

## Architecture

### Zsh runtime managers

fnm (Node.js), pyenv (Python), SDKMAN (JVM), pnpm. 1Password SSH agent integration.

### Platform-specific window managers

- **macOS**: AeroSpace
- **Linux**: GNOME (Fedora Workstation) — no WM config in this repo

### Catppuccin Mocha theme

Used across tmux and zsh. When adding new tool configs, prefer Catppuccin Mocha for consistency.

## Editing Rules

- Always run `stow -n <package>` before deploying new configs to check for conflicts.
- Identify the target platform before editing: macOS-only (`aerospace/`), Linux-only (`deskflow-linux/`), or cross-platform.
- Some packages need COPR repos: `oh-my-posh` (chronoscrat).

## File References

- Package lists: `commands/packages_homebrew.txt`, `commands/packages_fedora.txt`
- Neovim plugins: `nvim/.config/nvim/lua/plugins/`
- Codex skills: `codex/.codex/skills/`
