# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## 리포지토리 개요

개인 dotfiles 리포지토리로 macOS와 Arch Linux 환경의 설정 파일들을 관리합니다. GNU Stow를 사용하여 심볼릭 링크 기반으로 dotfiles를 관리합니다.

## 디렉토리 구조

각 디렉토리는 독립적인 패키지로 취급되며 Stow로 심볼릭 링크를 생성합니다:

- `zsh/` - Zsh 쉘 설정 (zinit, oh-my-posh, fzf-tab)
- `nvim/` - Neovim 설정 (LazyVim 기반)
- `tmux/` - tmux 설정 (catppuccin 테마, vim-tmux-navigator)
- `git/` - Git 설정 (SSH 서명 사용)
- `aerospace/` - AeroSpace 윈도우 매니저 설정 (macOS)
- `ghostty/` - Ghostty 터미널 설정
- `kitty/` - Kitty 터미널 설정
- `lazygit/` - LazyGit 설정
- `sketchybar/`, `yabai/`, `skhd/` - macOS 윈도우 관리
- `i3/`, `polybar/`, `sway/`, `waybar/`, `rofi/`, `wofi/` - Linux 윈도우 관리
- `commands/` - 패키지 설치 스크립트
- `claude/` - Claude Code 설정

## 주요 명령어

### 패키지 설치

**macOS (Homebrew):**
```bash
cd commands
./install_deps_mac.sh
```
`packages_homebrew.txt`에서 formula와 cask를 읽어 설치합니다. 실패한 패키지는 별도로 보고됩니다.

**Arch Linux (AUR):**
```bash
cd commands
./install_deps_arch.sh
```
`packages_aur.txt`에서 패키지를 읽어 yay로 설치합니다. 로그 파일이 자동 생성됩니다.

### Dotfiles 배포

**특정 패키지 적용:**
```bash
stow <package_name>
```

**모든 패키지 적용:**
```bash
stow */
```

**패키지 제거:**
```bash
stow -D <package_name>
```

**충돌 확인 및 시뮬레이션:**
```bash
stow -n <package_name>
```

## 아키텍처 특징

### Stow 기반 관리
각 디렉토리는 `~/.config` 또는 `~/`에 매핑되는 구조를 따릅니다. 예를 들어:
- `zsh/.zshrc` → `~/.zshrc`
- `nvim/.config/nvim/` → `~/.config/nvim/`

### 멀티 플랫폼 지원
macOS와 Linux 환경 모두 지원하며, 각 플랫폼별 설정이 별도 디렉토리로 구분됩니다:
- macOS: aerospace, sketchybar, yabai, skhd
- Linux: i3, sway, polybar, waybar, rofi, wofi

### Zsh 설정 구조
- Zinit 플러그인 매니저 사용
- Oh My Posh 프롬프트 테마 (star 테마)
- fzf-tab으로 탭 완성 향상
- Catppuccin 색상 테마
- 런타임 매니저 통합: fnm (Node.js), pyenv (Python), SDKMAN (JVM), pnpm
- 1Password SSH 에이전트 통합

### Neovim 설정
LazyVim 배포판을 기반으로 구축되어 있으며, `nvim/.config/nvim/lua/` 디렉토리에서 설정과 플러그인을 관리합니다.

### Tmux 설정
- Prefix: `Ctrl+s`
- TPM (Tmux Plugin Manager) 사용
- vim-tmux-navigator로 Neovim과 seamless 통합
- Catppuccin 테마 (mocha flavor)

### Git 설정
SSH 키로 커밋 서명 (`gpg.format = ssh`)을 사용하며, 기본 브랜치는 `main`입니다.

## 수정 시 주의사항

### 패키지 목록 수정
- `commands/packages_homebrew.txt`: `formula:` 섹션과 `cask:` 섹션을 명확히 구분
- `commands/packages_aur.txt`: 주석(`#`)과 빈 줄은 자동으로 스킵됨

### Stow 충돌 방지
새 설정을 추가할 때는 반드시 `stow -n` 명령으로 충돌을 먼저 확인하세요.

### 플랫폼 특정 설정
macOS와 Linux 전용 설정을 수정할 때는 대상 플랫폼을 명확히 인지하고 작업하세요.
