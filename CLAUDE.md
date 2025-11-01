# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## 리포지토리 개요

개인 dotfiles 리포지토리로 macOS와 Linux (Fedora) 환경의 설정 파일들을 관리합니다. GNU Stow를 사용하여 심볼릭 링크 기반으로 dotfiles를 관리합니다.

**지원 환경:**
- macOS: AeroSpace 윈도우 매니저
- Linux: Fedora Sway Atomic (Wayland 네이티브)

## 디렉토리 구조

각 디렉토리는 독립적인 패키지로 취급되며 Stow로 심볼릭 링크를 생성합니다:

**공통 설정:**
- `zsh/` - Zsh 쉘 설정 (zinit, oh-my-posh, fzf-tab)
- `nvim/` - Neovim 설정 (LazyVim 기반)
- `tmux/` - tmux 설정 (catppuccin 테마, vim-tmux-navigator)
- `git/` - Git 설정 (SSH 서명 사용)
- `ghostty/` - Ghostty 터미널 설정
- `fonts/` - Nerd Fonts 등 폰트 파일
- `backgrounds/` - 배경 이미지

**macOS 전용:**
- `aerospace/` - AeroSpace 윈도우 매니저 설정

**Linux (Fedora Sway) 전용:**
- `sway/` - Sway 타일링 윈도우 매니저 설정
- `waybar/` - Waybar 상태 바 설정
- `wofi/` - Wofi 애플리케이션 런처 설정
- `greetd/` - greetd + tuigreet 디스플레이 매니저 설정 (/etc로 배포)
- `swaylock/` - swaylock-effects 화면 잠금 설정

**기타:**
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

**Fedora Workstation (dnf/COPR):**
```bash
cd commands
./install_deps_fedora.sh
```
`packages_fedora.txt`에서 패키지를 읽어 dnf로 설치합니다. COPR 리포지토리가 필요한 패키지는 수동 설치 안내가 제공됩니다. 로그 파일이 자동 생성됩니다.

**Fedora Sway Atomic (rpm-ostree):**
```bash
cd commands
./install_deps_fedora_sway_atomic.sh
```
`packages_fedora_sway_atomic.txt`에서 패키지를 읽어 rpm-ostree로 설치합니다. Sway 생태계는 기본 포함되어 있어 추가 패키지만 설치합니다. 설치 후 재부팅이 필요합니다.

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

### 플랫폼별 윈도우 매니저
각 플랫폼에 최적화된 윈도우 매니저를 사용합니다:
- **macOS**: AeroSpace (타일링 윈도우 매니저)
- **Linux (Fedora Sway Atomic)**: Sway + Waybar + Wofi (Wayland 네이티브)

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

## Sway 설정 (Linux/Wayland)

### 핵심 구성 요소
- **디스플레이 매니저**: greetd + tuigreet (Wayland 네이티브, SDDM 대체)
- **화면 잠금**: swaylock-effects (블러 효과, 시계 표시)
- **타일링 매니저**: Sway (Wayland 네이티브)
- **상태 바**: Waybar
- **런처**: Wofi
- **한글 입력**: Fcitx5 (Wayland 네이티브 지원)
- **알림**: mako
- **네트워크**: nmtui (터미널 UI, XWayland 불필요)

### 주요 키 바인딩
- `Mod+Return`: 터미널 (ghostty)
- `Mod+d`: 앱 런처 (wofi)
- `Mod+n`: 네트워크 설정 (nmtui)
- `Mod+l`: 화면 잠금 (swaylock)
- `Mod+Shift+q`: 창 닫기
- `Mod+Shift+e`: Sway 종료
- `Mod+r`: 리사이즈 모드
- 미디어 키: 재생/일시정지, 다음/이전 (playerctl)
- 밝기 키: 화면 밝기 조절 (brightnessctl)
- 볼륨 키: 오디오 제어 (pamixer)

### Fedora 43 특화 설정
- Wayland 전용 환경 변수 설정 (`dbus-update-activation-environment`)
- Fcitx5 환경 변수를 Sway config에서 직접 설정 (`.xprofile` 미사용)
- XWayland 의존성 최소화 (1Password, Dropbox 제외)

### greetd + tuigreet 설치 (디스플레이 매니저)

경량 Wayland 네이티브 디스플레이 매니저로 SDDM을 대체합니다.

**자동 설치:**
```bash
cd commands
sudo ./setup_greetd.sh
systemctl reboot
```

**수동 설치:**
```bash
# 1. 패키지 설치 (rpm-ostree)
rpm-ostree install greetd greetd-tuigreet
systemctl reboot

# 2. 설정 파일 배포
sudo cp -r greetd/etc/greetd/* /etc/greetd/

# 3. SDDM 비활성화 및 greetd 활성화
sudo systemctl disable sddm
sudo systemctl enable greetd
systemctl reboot
```

**커스터마이징:**
- 환영 메시지 변경: `/etc/greetd/config.toml`에서 `--greeting` 옵션 수정
- 자동 로그인: `/etc/greetd/config.toml`에 `[initial_session]` 섹션 추가
- 전체 옵션: `tuigreet --help`

**롤백:**
```bash
sudo systemctl disable greetd
sudo systemctl enable sddm
systemctl reboot
```

### swaylock-effects 설치 (화면 잠금)

Sway용 향상된 화면 잠금 도구로 블러 효과, 시계 표시 등 다양한 기능을 제공합니다.

**자동 설치:**
```bash
cd commands
sudo ./setup_swaylock.sh
systemctl reboot

# 재부팅 후 설정 배포
stow swaylock
```

**수동 설치:**
```bash
# 1. COPR 활성화
sudo dnf copr enable eddsalkield/swaylock-effects

# 2. 패키지 설치
rpm-ostree install swaylock-effects
systemctl reboot

# 3. 설정 파일 배포
stow swaylock
```

**사용법:**
- 수동 잠금: `swaylock -f` 또는 `Mod+l` 단축키
- 자동 잠금: swayidle로 5분 후 자동 잠금 (sway config에 설정됨)
- 절전 전 잠금: 자동으로 잠금 후 절전 모드 진입

**주요 기능:**
- Catppuccin Mocha 테마
- 블러 효과 및 비네트 효과
- 시계 및 날짜 표시
- Grace 기간 (2초 이내 마우스/터치 없이 즉시 해제)
- Caps Lock 상태 표시
- 키보드 레이아웃 표시 (한/영)

**커스터마이징:**
`~/.config/swaylock/config` 파일 수정 후 `stow swaylock`으로 재배포

## 수정 시 주의사항

### 패키지 목록 수정
- `commands/packages_homebrew.txt`: `formula:` 섹션과 `cask:` 섹션을 명확히 구분
- `commands/packages_fedora.txt`: 주석(`#`)과 빈 줄은 자동으로 스킵됨. 인라인 주석 사용 금지
- `commands/packages_fedora_sway_atomic.txt`: Fedora Sway Atomic 전용. 기본 포함된 패키지는 제외됨

### Fedora COPR 사용
일부 패키지는 Fedora 공식 리포지토리에 없어 COPR(Community Projects Repository)가 필요합니다:
- `swaylock-effects`: eddsalkield/swaylock-effects
- `oh-my-posh`: chronoscrat/oh-my-posh

COPR 활성화: `sudo dnf copr enable 사용자명/프로젝트명`

Fedora Sway Atomic에서는 rpm-ostree 사용:
```bash
sudo dnf copr enable 사용자명/프로젝트명
rpm-ostree install 패키지명
systemctl reboot
```

### Stow 충돌 방지
새 설정을 추가할 때는 반드시 `stow -n` 명령으로 충돌을 먼저 확인하세요.

### 플랫폼 특정 설정
macOS와 Fedora 전용 설정을 수정할 때는 대상 플랫폼을 명확히 인지하고 작업하세요:
- **macOS 전용**: `aerospace/`
- **Fedora 전용**: `sway/`, `waybar/`, `wofi/`, `greetd/`, `swaylock/`
- **공통**: `zsh/`, `nvim/`, `tmux/`, `git/`, `ghostty/`

### Fedora 43 Wayland 전용 고려사항
- X11 세션이 완전히 제거되었으므로 모든 앱은 Wayland 네이티브이거나 XWayland를 통해 실행됨
- 시스템 트레이 앱(nm-applet 등)보다 터미널 기반 도구(nmtui, nmcli) 권장
- SELinux가 기본 활성화됨: Stow 배포 후 권한 문제 발생 시 `restorecon -Rv ~/` 실행
