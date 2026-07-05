---
paths:
  - "commands/**"
---

# Package Scripts and Lists

## Package list format

- `packages_homebrew.txt`: Two sections separated by `formula:` and `cask:` headers. Keep them distinct.
- `packages_fedora.txt`: Three sections separated by `dnf:`, `brew:`, `repo:` headers. `dnf:`/`brew:` are one package per line. `repo:` lines are `<repo-spec> <package>` where repo-spec is `copr:<user>/<project>` or a `.repo` file URL. Lines starting with `#` and blank lines are skipped. No inline comments.

## Install scripts

- `install_deps_mac.sh` — reads `packages_homebrew.txt`, reports failed packages separately
- `install_deps_fedora.sh` — reads `packages_fedora.txt` per section: dnf install, COPR/vendor repo registration (dnf5 `config-manager addrepo`), then brew install (skipped with a notice if linuxbrew is absent)
