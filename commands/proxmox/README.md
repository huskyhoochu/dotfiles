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
./01-network.sh

# 여기서 인터넷이 되면 저장소를 clone 하고 나머지를 실행한다

# 2. 호스트 기본 설정 — 저장소, 시간대, SSH, 방화벽
./02-host.sh

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

## 주의

- `01-network.sh`는 네트워크 설정을 바꾸므로 **콘솔(모니터+키보드)에서 실행**한다. SSH로 실행하면 연결이 끊긴 채 되돌릴 수 없다.
- `03-containers.sh`는 컨테이너를 만들 뿐 서비스를 설치하지 않는다. 서비스 배포는 각 컨테이너 안에서 따로 한다.
- 시크릿(Wi-Fi 비밀번호, SSH 공개키)은 이 저장소에 넣지 않는다. `01-network.sh`는 실행 시점에 입력받고, SSH 공개키는 `02-host.sh` 실행 전에 환경변수로 넘긴다.
