# Proxmox 부트스트랩 스크립트

GEM12를 Proxmox VE 서버로 세우는 스크립트 모음. 설계 근거는 `docs/gem12-private-cloud-plan-2026-08-17.md`에 있다.

## stow 패키지가 아니다

`zsh/`, `nvim/` 같은 최상위 디렉토리와 달리 이 디렉토리는 `~/`에 심볼릭 링크를 걸지 않는다. 세 가지 이유가 있다.

- 설정 대상이 `/etc/network/interfaces`, `/etc/pve/lxc/*.conf` 같은 시스템 경로다
- 맥북에서 `bootstrap.sh`를 돌릴 때 서버 설정이 딸려 들어가면 안 된다
- `/etc/pve`는 Proxmox 클러스터 파일시스템이라 심볼릭 링크를 만들 수 없다

그래서 `commands/llamacpp/`, `commands/ollama/`와 같은 성격으로, **서버에서 직접 실행하는 스크립트**로 둔다.

## 실행 순서

Proxmox VE 설치를 마치고 콘솔에 로그인한 상태에서 시작한다. 저장소를 받아올 네트워크가 아직 없으므로 **1번은 USB나 손으로 옮겨 실행**한다.

```bash
# 1. 네트워크 — Wi-Fi 연결과 NAT 브리지
#    저장소를 아직 받을 수 없으므로 USB로 옮기거나 손으로 친다
./01-network.sh

# 인터넷이 연결되면 저장소를 받는다. 공개 저장소이므로 HTTPS로 받으면
# 인증이 필요 없다 — SSH 키는 1Password 에이전트에 있어 서버에서 바로 쓸 수 없다.
git clone https://github.com/huskyhoochu/dotfiles.git ~/dotfiles
cd ~/dotfiles/commands/proxmox

# 2. 호스트 기본 설정 — 저장소, 시간대, SSH, 셸
#    맥북 공개키를 미리 넘기면 입력을 건너뛴다
SSH_PUBKEY="ssh-ed25519 AAAA..." ./02-host.sh

# 3. LXC 5개 생성
./03-containers.sh

# 4. 컨테이너별 런타임 설치 (Docker 또는 Podman)
./04-runtime.sh
```

각 스크립트는 여러 번 실행해도 안전하다. 이미 적용된 항목은 건너뛴다.

## 스크립트

| 파일 | 역할 |
|---|---|
| `01-network.sh` | Wi-Fi(`wlp6s0`) 연결, NAT 브리지 `vmbr0` 구성 |
| `02-host.sh` | 무료 저장소 전환, 시간대, SSH 키 인증, 방화벽 |
| `03-containers.sh` | `containers.conf` 정의대로 LXC 생성, GPU 장치 바인드 |
| `04-runtime.sh` | 컨테이너별 Docker/Podman 설치 |
| `containers.conf` | LXC 정의 (이름, 자원, IP, 런타임, GPU) |
| `lib.sh` | 공통 함수 (로깅, 확인, 멱등성 검사) |

## 셸

Proxmox와 Debian 13 모두 로그인 셸은 bash이고 `/bin/sh`는 dash다. 모든 스크립트는 `#!/usr/bin/env bash`로 시작하며 bash 문법을 쓴다.

서버에 zsh은 설치하지 않는다. 이 저장소의 `zsh/` 설정은 zinit과 oh-my-posh, 런타임 관리자(fnm/pyenv/SDKMAN)를 전제하는 개발 환경용이라 서버에서는 시작 시간만 늘린다.

## 자격증명

서버에서 쓸 것은 **포맷 전에 맥북에서 발급해 1Password에 넣어둔다.** 발급 자체에 브라우저가 필요하기 때문이다.

| 항목 | 발급 방법 | 서버에서 쓰는 법 |
|---|---|---|
| 맥북 SSH 공개키 | `cat ~/.ssh/id_ed25519.pub` | `SSH_PUBKEY=... ./02-host.sh` |
| Claude Code 토큰 | `claude setup-token` | `CLAUDE_CODE_OAUTH_TOKEN` 환경변수 |
| rclone Google Drive | `rclone authorize "drive"` | `rclone config` 에 붙여넣기 |

토큰은 `~/.bashrc.local` 에 두거나 1Password에서 주입한다. 이 저장소에 넣지 않는다.

## 주의

- `01-network.sh`는 네트워크 설정을 바꾸므로 **콘솔(모니터+키보드)에서 실행**한다. SSH로 실행하면 연결이 끊긴 채 되돌릴 수 없다.
- `03-containers.sh`는 컨테이너를 만들 뿐 서비스를 설치하지 않는다. 서비스 배포는 각 컨테이너 안에서 따로 한다.
- 시크릿(Wi-Fi 비밀번호, SSH 공개키)은 이 저장소에 넣지 않는다. `01-network.sh`는 실행 시점에 입력받고, SSH 공개키는 `02-host.sh` 실행 전에 환경변수로 넘긴다.
