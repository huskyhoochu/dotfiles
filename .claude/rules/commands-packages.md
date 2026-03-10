---
paths:
  - "commands/**"
---

# Package Scripts and Lists

## Package list format

- `packages_homebrew.txt`: Two sections separated by `formula:` and `cask:` headers. Keep them distinct.
- `packages_fedora.txt`: One package per line. Lines starting with `#` and blank lines are skipped. No inline comments.
- `packages_fedora_sway_atomic.txt`: Fedora Sway Atomic only. Exclude packages already included in the base image.
- `packages_aur.txt`: Arch Linux AUR packages.

## Install scripts

- `install_deps_mac.sh` — reads `packages_homebrew.txt`, reports failed packages separately
- `install_deps_fedora.sh` — reads `packages_fedora.txt`, handles COPR repos manually
- `install_deps_fedora_sway_atomic.sh` — reads `packages_fedora_sway_atomic.txt`, uses rpm-ostree
- `install_deps_arch.sh` — reads `packages_aur.txt`

## Setup scripts

- `setup_greetd.sh` — installs and configures greetd + tuigreet (requires sudo)
- `setup_swaylock.sh` — installs swaylock-effects from COPR (requires sudo)

These setup scripts target `/etc/` and require elevated privileges. They are not run by `bootstrap.sh` automatically.
