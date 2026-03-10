---
globs: ["sway/**", "waybar/**", "wofi/**", "greetd/**", "swaylock/**"]
---

# Fedora Sway Atomic — Linux/Wayland Rules

This is a Wayland-only environment (Fedora 43+). No X11 session exists.

## Key components

- **Display manager**: greetd + tuigreet (config in `/etc/greetd/`, deploy via `commands/setup_greetd.sh`)
- **Screen lock**: swaylock-effects (COPR: eddsalkield/swaylock-effects)
- **Input method**: Fcitx5 (env vars set in sway config, not `.xprofile`)
- **Notifications**: mako
- **Network**: nmtui (terminal UI, no XWayland dependency)

## Conventions

- Prefer terminal-based tools (nmtui, nmcli) over system tray apps (nm-applet) to avoid XWayland.
- Fcitx5 environment variables must be set inside sway config, not in shell profile.
- swaylock config uses Catppuccin Mocha theme — maintain color consistency.
- `greetd/` deploys to `/etc/`, not `~/.config/`. Never use `stow greetd` directly.

## After editing

- Sway config: reload with `Mod+Shift+c` or `swaymsg reload`
- Waybar: `killall waybar && waybar &`
- swaylock: test with `swaylock -f`
- SELinux: if permission issues after stow, run `restorecon -Rv ~/`

## rpm-ostree workflow

Package changes require rpm-ostree and a reboot:
```bash
rpm-ostree install <package>
systemctl reboot
```

For COPR packages:
```bash
sudo dnf copr enable <user>/<repo>
rpm-ostree install <package>
systemctl reboot
```
