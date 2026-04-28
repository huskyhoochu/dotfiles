# CLAUDE.md

Personal dotfiles repository managing macOS and Linux (Fedora Workstation / Sway Atomic) configurations via GNU Stow symlinks.

## Current host

Verified via `uname -a` and `fastfetch` on 2026-04-28. The repo supports multiple targets, but **this machine is regular Fedora Workstation, not Sway Atomic** — so dnf (not rpm-ostree), GNOME (not Sway), and the `install_deps_fedora.sh` script apply here.

| | |
|---|---|
| Host | GEM12 (`fedora`) |
| OS | Fedora Linux 43 (Workstation Edition) x86_64 |
| Kernel | `6.19.12-200.fc43.x86_64` |
| DE / WM | GNOME 49.6 / Mutter (Wayland) |
| Shell | zsh 5.9 |
| CPU / GPU | AMD Ryzen 7 PRO 8845HS / Radeon 780M (integrated) |
| Memory | 60.6 GiB |
| Disk | btrfs, 928 GiB |
| Package managers in use | dnf (rpm), flatpak, Homebrew (linuxbrew at `/home/linuxbrew/.linuxbrew`) |
| Locale | `ko_KR.UTF-8` |

Implication: the `sway/`, `waybar/`, `wofi/`, `greetd/`, `swaylock/` Stow packages are not deployed on this host. Sway-Atomic-specific guidance (rpm-ostree reboots, SELinux relabel) does not apply here.

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
./install_deps_fedora_sway_atomic.sh     # Fedora Sway Atomic — rpm-ostree (reboot required)
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

### Linux (Fedora Sway Atomic) only

| Package | Purpose |
|---------|---------|
| `sway/` | Sway tiling WM (Wayland native) |
| `waybar/` | Status bar |
| `wofi/` | Application launcher |
| `greetd/` | greetd + tuigreet display manager (deploys to `/etc`, not via stow) |
| `swaylock/` | swaylock-effects screen lock |

### Other

| Package | Purpose |
|---------|---------|
| `commands/` | Package install scripts and package lists |
| `claude/` | Claude Code settings and skills (stowed to `~/.claude/`) |

## Architecture

### Zsh runtime managers

fnm (Node.js), pyenv (Python), SDKMAN (JVM), pnpm. 1Password SSH agent integration.

### Platform-specific window managers

- **macOS**: AeroSpace
- **Linux**: Sway + Waybar + Wofi (Wayland-only, no X11 session)

### Catppuccin Mocha theme

Used across tmux, zsh, swaylock. When adding new tool configs, prefer Catppuccin Mocha for consistency.

## Editing Rules

- Always run `stow -n <package>` before deploying new configs to check for conflicts.
- Identify the target platform before editing: macOS-only (`aerospace/`), Linux-only (`sway/`, `waybar/`, `wofi/`, `greetd/`, `swaylock/`), or cross-platform.
- `greetd/` targets `/etc/greetd/`, not `~/.config/`. Use `commands/setup_greetd.sh` for deployment.
- Fedora Sway Atomic uses rpm-ostree (requires reboot). SELinux is enabled — run `restorecon -Rv ~/` if permission issues arise after stow.
- Some packages need COPR repos: `swaylock-effects` (eddsalkield), `oh-my-posh` (chronoscrat).

## File References

- Package lists: `commands/packages_homebrew.txt`, `commands/packages_fedora.txt`, `commands/packages_fedora_sway_atomic.txt`
- Sway keybindings: `sway/.config/sway/config`
- Neovim plugins: `nvim/.config/nvim/lua/plugins/`
- Claude skills: `claude/.claude/skills/`
