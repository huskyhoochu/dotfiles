---
paths:
  - "commands/**"
---

# Package Scripts and Lists

## Package list format

- `packages_homebrew.txt`: Two sections separated by `formula:` and `cask:` headers. Keep them distinct.
- `packages_fedora.txt`: One package per line. Lines starting with `#` and blank lines are skipped. No inline comments.

## Install scripts

- `install_deps_mac.sh` — reads `packages_homebrew.txt`, reports failed packages separately
- `install_deps_fedora.sh` — reads `packages_fedora.txt`, handles COPR repos manually
