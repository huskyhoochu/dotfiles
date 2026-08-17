# 첫 부팅 튜토리얼 — Fedora Server 설치 직후 Wi-Fi · 1Password CLI · Claude Code

> 날짜: 2026-08-17 (월)
> 대상: GEM12 (Intel AX200 무선랜, 인터페이스 `wlp6s0`)
> 상황: Fedora Server를 막 설치했고, 랜선이 없고, **저장소를 아직 받을 수 없다**

이 문서는 서버가 인터넷에 붙기 전에 필요하므로 서버에서 열 수 없다. **맥북이나 휴대폰 브라우저로 GitHub에서 열어** 옆에 두고 따라간다.

```text
https://github.com/huskyhoochu/dotfiles/blob/main/docs/gem12-first-wifi-tutorial-2026-08-17.md
```

모든 명령은 서버 앞에 앉아 모니터와 **유선 키보드**로 친다.

**콘솔 작업은 `02-host.sh`가 끝나는 순간까지다.** 그 시점에 맥북 공개키가 등록되므로, `ssh root@<서버 IP>` 성공을 확인한 뒤에는 모니터와 키보드를 치워도 된다. Anaconda 설치 때 "비밀번호로 root SSH 로그인 허용"을 켰다면 첫 부팅부터 SSH가 되므로 콘솔 작업은 설치 자체로 끝난다 — 이 허용은 `02-host.sh`가 키 등록 후 자동으로 제거한다. 서버 IP는 콘솔에서 `ip -br addr show wlp6s0`으로 확인한다.

---

## 설치 관리자에서 놓치면 안 되는 것 — btrfs 파티셔닝

Anaconda의 설치 대상 화면에서 디스크만 선택하고 넘어가면 **자동 파티셔닝(LVM + xfs, 루트 16GB)**이 적용된다. 이 경로에는 파일시스템 선택지가 화면에 나타나지 않으므로, btrfs를 받으려면 능동적으로 들어가야 한다.

1. **설치 대상** 화면에서 NVMe 디스크 선택
2. 저장소 구성에서 **"사용자 정의(Custom)"** 를 선택하고 완료(Done)
3. 수동 파티셔닝 화면에서 **파티셔닝 스킴 드롭다운을 "Btrfs"로 변경**
4. **"자동으로 마운트 지점 생성"** 을 눌러 btrfs 기준 레이아웃을 만들게 한 뒤 완료

`02-host.sh`가 루트 파일시스템을 검사해서 btrfs가 아니면 중단하므로, 여기서 놓치면 부트스트랩 단계에서 걸린다.

---

## 미리 알아둘 사실

**Fedora Server는 Wi-Fi를 기본 지원한다.** `NetworkManager-wifi`와 `wpa_supplicant`가 Fedora 28부터 Server 기본 구성에 들어 있고, AX200 펌웨어도 기본 설치되는 `linux-firmware`에 포함돼 있다. 즉 **아무것도 설치하지 않고 `nmcli` 명령만으로 연결할 수 있다.**

가장 좋은 경로는 **설치 중에 연결해두는 것**이다. Anaconda 설치 관리자의 "네트워크와 호스트 이름" 화면에서 Wi-Fi를 연결하면 그 설정이 설치된 시스템으로 넘어와, 첫 부팅부터 인터넷이 붙어 있다. 이 경우 아래 1단계 확인만 하고 끝난다.

---

## 1. 이미 연결돼 있는지 확인

root로 로그인한 뒤 친다.

```bash
nmcli device
```

`wlp6s0` 줄의 STATE가 `connected`(연결됨)이면 이미 붙어 있는 것이다. 인터넷까지 확인한다.

```bash
ping -c 3 1.1.1.1
```

응답이 오면 끝이다. 맨 아래 **[검증]** 절로 건너뛴다.

---

## 2. 손으로 연결하기

### 2-1. 무선이 켜져 있는지 본다

```bash
nmcli radio wifi
```

`disabled`(꺼짐)라고 나오면 켠다.

```bash
nmcli radio wifi on
```

### 2-2. 주변 네트워크를 찾는다

```bash
nmcli device wifi rescan
nmcli device wifi list
```

목록에서 집 공유기의 SSID를 확인한다. 몇 초 기다렸다가 다시 `list`를 쳐야 나올 때도 있다.

### 2-3. 연결한다

`<SSID>` 자리에 실제 이름을 넣는다. `--ask`를 쓰면 비밀번호를 화면에 보이지 않게 따로 물어보므로, 명령 히스토리에 비밀번호가 남지 않는다.

```bash
nmcli --ask device wifi connect "<SSID>"
```

`successfully activated`(활성화 성공)가 나오면 연결된 것이다.

### 2-4. 인터넷을 확인한다

```bash
ping -c 3 1.1.1.1        # 바깥으로 나가는가
getent hosts github.com  # 도메인 이름이 풀리는가 (DNS)
```

둘 다 응답하면 성공이다.

---

## 3. 문제가 생겼을 때

| 증상 | 확인 | 조치 |
|---|---|---|
| `nmcli device`에 wifi 장치가 없다 | `rfkill list` — `Soft blocked: yes`인가 | `rfkill unblock wifi` 후 다시 시도 |
| 여전히 장치가 없다 | `dmesg \| grep iwlwifi` — 펌웨어 로드 오류가 있는가 | 아래 "USB 테더링" 참조 |
| 패키지가 없다고 나온다 | `rpm -q NetworkManager-wifi wpa_supplicant` | 표준 Server 설치에서는 일어나지 않는다. 최소 구성으로 깔았다면 아래 "USB 테더링"으로 설치 |
| 비밀번호를 잘못 넣었다 | — | `nmcli connection delete "<SSID>"` 후 2-3부터 다시 |
| 연결은 됐는데 ping이 안 된다 | `nmcli device show wlp6s0 \| grep GATEWAY` 후 그 주소로 ping | 게이트웨이도 안 되면 공유기 문제. 게이트웨이는 되는데 1.1.1.1이 안 되면 공유기의 인터넷 회선 문제 |
| ping은 되는데 도메인이 안 풀린다 | `cat /etc/resolv.conf` | DNS 문제. `nmcli connection modify "<SSID>" ipv4.dns "1.1.1.1"` 후 `nmcli connection up "<SSID>"` |

### 최후 수단 — 휴대폰 USB 테더링

Wi-Fi가 어떤 이유로든 안 되면 휴대폰으로 임시 회선을 만든다. USB 테더링은 서버에 **유선 랜처럼 잡히므로** 무선 패키지가 전혀 없어도 동작한다.

1. 휴대폰을 USB 케이블로 서버에 연결한다
2. 휴대폰 설정에서 "USB 테더링"을 켠다
3. `nmcli device` — 새 ethernet 장치가 `connected`로 나타난다 (DHCP 자동)
4. 이 회선으로 부족한 것을 설치한다

```bash
dnf install -y NetworkManager-wifi wpa_supplicant
systemctl restart NetworkManager
```

그다음 2단계로 돌아가 Wi-Fi를 연결한다.

---

## 검증 — 재부팅 후에도 붙는가

연결 프로파일은 기본으로 자동 연결이 켜진 채 저장되지만, 서버는 무인으로 재부팅될 것이므로 반드시 확인한다.

```bash
nmcli -f NAME,AUTOCONNECT connection show
```

만든 연결의 AUTOCONNECT가 `yes`인지 본다. `no`라면 켠다.

```bash
nmcli connection modify "<SSID>" connection.autoconnect yes
```

마지막으로 실제 재부팅으로 검증한다.

```bash
systemctl reboot
# 재부팅 후 로그인해서
nmcli device        # wlp6s0 이 connected 인가
ping -c 3 1.1.1.1   # 인터넷이 붙는가
```

둘 다 통과하면 네트워크는 끝났다.

---

## 저장소 받기와 부트스트랩 (2026-08-18 실행 검증)

맥북에서 SSH로 들어간다. 재설치한 경우 서버 호스트 키가 바뀌었으므로 옛 키부터 지운다.

```bash
# 맥북에서
ssh-keygen -R 192.168.35.69    # 재설치 후 첫 접속 때만
ssh root@192.168.35.69
```

서버에서 저장소를 받는다. git은 Server 기본 구성에 없으므로 먼저 설치한다. 공개 저장소이므로 HTTPS clone에는 인증이 필요 없다.

```bash
# 서버에서 (root)
dnf install -y git
git clone https://github.com/huskyhoochu/dotfiles.git ~/dotfiles
cd ~/dotfiles/commands/incus
```

호스트 설정은 인자 없이 실행한다.

```bash
./02-host.sh
```

맥북 공개키는 스크립트가 GitHub(`huskyhoochu.keys` 첫 줄)에서 직접 받는다 — 1Password의 SSH 키가 GitHub에 등록돼 있어 손으로 칠 필요가 없다. 일상 접속용 사용자는 `b95labs`가 기본이며, 그 사용자에게 SSH 키 등록과 `incus-admin` 그룹 추가까지 처리한다. 다른 값이 필요하면 환경변수로 덮어쓴다: `SSH_PUBKEY="..." ADMIN_USER=other ./02-host.sh`

정상 실행이면 로그에 **`btrfs 스토리지 풀 생성`**이 보인다. 루트가 btrfs가 아니면 여기서 멈춘다 (맨 위 파티셔닝 절 참조).

이어서 컨테이너와 런타임까지 마친다.

```bash
./03-containers.sh
./04-runtime.sh
```

검증:

```bash
incus storage show default | grep driver     # driver: btrfs
incus list                                   # core/ci/apps/ai/media 5개 RUNNING
incus exec ci -- docker run --rm hello-world
# 맥북에서: ssh b95labs@192.168.35.69 → sudo -v, incus list
```

이후 절차는 `commands/incus/README.md`와 `gem12-private-cloud-plan-2026-08-17.md` §8을 따른다.

---

## 1Password CLI 설치와 인증

서버에서 쓸 시크릿은 1Password의 **Personal 금고**에 있다. `op` CLI를 인증해두면 평문 파일 대신 금고에서 직접 읽는다.

```bash
export OPENROUTER_API_KEY="$(op read 'op://Personal/OPENROUTER_API_KEY/credential')"
```

이 계정의 금고는 `BFAI`(회사), `CGHDS`, `Personal`(개인) 3개다. 서버 시크릿은 전부 Personal에 있다. Personal 금고는 개인 전용이라 **계정 인증으로만 읽을 수 있다.** 아래 절차는 데스크톱 앱과 브라우저 없이 콘솔에서 끝난다.

### 준비물 — Secret Key

계정 인증에는 로그인 주소, 이메일, 마스터 비밀번호에 더해 **Secret Key**가 필요하다. `A3-` 로 시작하는 34자 문자열로, 두 곳에서 확인할 수 있다.

- 휴대폰 1Password 앱 → 계정 설정
- Emergency Kit (종이로 보관 중인 복구 문서)

### 설치

1Password 공식 rpm 저장소를 등록하고 설치한다.

```bash
sudo rpm --import https://downloads.1password.com/linux/keys/1password.asc

sudo tee /etc/yum.repos.d/1password.repo >/dev/null <<'EOF'
[1password]
name=1Password Stable Channel
baseurl=https://downloads.1password.com/linux/rpm/stable/$basearch
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://downloads.1password.com/linux/keys/1password.asc
EOF

sudo dnf install -y 1password-cli
op --version
```

### 계정 등록과 로그인

```bash
op account add
```

로그인 주소(`my.1password.com`), 이메일, Secret Key, 마스터 비밀번호를 차례로 묻는다. 등록은 한 번만 하면 된다.

등록한 뒤 세션을 연다.

```bash
eval "$(op signin)"
```

마스터 비밀번호를 입력하면 `OP_SESSION` 환경변수에 세션 토큰이 담긴다.

### 확인

```bash
op vault list    # BFAI / CGHDS / Personal 세 금고가 나오는가
op read 'op://Personal/OPENROUTER_API_KEY/credential'    # 실제 항목이 읽히는가
```

### 경로는 필드 id로 쓴다

`op://<금고>/<항목 이름>/<필드>` 형식에서 마지막 필드 자리에는 **필드 id**를 쓴다. 이 계정은 앱이 한국어라 화면에는 라벨이 "자격 증명"으로 보이지만, 경로에 그 라벨을 쓰면 읽히지 않는다. API 자격 증명 항목의 필드 id는 `credential`이다 (2026-08-17 실제 검증).

```bash
op read 'op://Personal/OPENROUTER_API_KEY/credential'   # 동작한다 — 필드 id
op read 'op://Personal/OPENROUTER_API_KEY/자격 증명'     # 읽히지 않는다 — 화면 라벨
```

### 서버에서 실제로 읽을 항목 (Personal 금고)

| 항목 | 경로 | 용도 |
|---|---|---|
| `Github SSH` | `op://Personal/Github SSH/public key` | 맥북 공개키. `02-host.sh`의 `SSH_PUBKEY` |
| `CLAUDE_CODE_OAUTH_TOKEN` | `op://Personal/CLAUDE_CODE_OAUTH_TOKEN/credential` | Claude Code 인증 (아래 절 참조) |
| `OPENROUTER_API_KEY` | `op://Personal/OPENROUTER_API_KEY/credential` | AI 파이프라인 리뷰 모델 |
| `ZENMUX_API_KEY` | `op://Personal/ZENMUX_API_KEY/credential` | `pi`의 zenmux 프로바이더 |
| `HUGGING_FACE_API_KEY` | `op://Personal/HUGGING_FACE_API_KEY/credential` | 모델 재다운로드 |

새 시크릿(rclone Google Drive 토큰 등)을 만들 때는 Personal 금고에 **API 자격 증명** 유형으로, 위처럼 대문자 스네이크 케이스 이름을 붙여 저장한다. 그러면 경로가 `op://Personal/<이름>/credential`로 일관된다.

### 세션은 30분 뒤 만료된다

비활성 30분이 지나면 세션이 끝나고, 다음 `op` 명령이 비밀번호를 다시 묻는다. 셸에 앉아 쓰는 용도로는 이대로 충분하다. `~/.bashrc.local`에서 `op read`로 토큰을 주입하는 경우, 셸을 열 때 비밀번호를 한 번 입력하는 흐름이 된다.

---

## Claude Code 설치

코딩 작업이 이뤄지는 곳에 설치한다 — 기본은 apps 컨테이너다. 호스트든 컨테이너든 전부 Fedora이므로 설치 방법은 같다.

### 저장소 등록과 설치

Claude Code는 서명된 공식 dnf 저장소를 제공한다. `stable` 채널은 대략 1주 묵은 버전을 제공하며 큰 회귀가 있는 릴리스를 건너뛴다 — 서버에 맞는 채널이다.

```bash
sudo tee /etc/yum.repos.d/claude-code.repo <<'EOF'
[claude-code]
name=Claude Code
baseurl=https://downloads.claude.ai/claude-code/rpm/stable
enabled=1
gpgcheck=1
gpgkey=https://downloads.claude.ai/keys/claude-code.asc
EOF

sudo dnf install claude-code
```

첫 설치 때 dnf가 서명 키 지문을 확인해 달라고 묻는다. 다음 값과 일치하는지 보고 수락한다.

```text
31DD DE24 DDFA B679 F42D 7BD2 BAA9 29FF 1A7E CACE
```

```bash
claude --version    # "2.x.x (Claude Code)" 가 나오면 설치 완료
```

### 인증 — 브라우저 없이 토큰으로

서버에는 브라우저가 없으므로 로그인 창을 띄우는 대신 **장기 토큰**을 환경변수로 넘긴다. 토큰은 맥북에서 `claude setup-token`으로 발급해 1Password에 저장돼 있다 (`CLAUDE_CODE_OAUTH_TOKEN` 항목, 2026-08-17 발급).

`~/.bashrc.local`에 다음 블록을 넣는다. 앞 절에서 등록해둔 `op`가 금고에서 읽어온다.

```bash
# 대화형 셸에서만 1Password 세션을 열어 Claude Code 토큰을 주입한다.
# op read 는 세션이 없을 때 스스로 로그인하지 못하므로 op signin 을 먼저 한다.
case $- in *i*)
  op whoami >/dev/null 2>&1 || eval "$(op signin)"
  export CLAUDE_CODE_OAUTH_TOKEN="$(op read "op://Personal/CLAUDE_CODE_OAUTH_TOKEN/credential")"
;; esac
```

`02-host.sh`가 배포하는 bashrc가 마지막에 `~/.bashrc.local`을 읽으므로, 셸을 새로 열면 토큰이 주입된다. op 세션(약 30분 유지)이 없으면 이때 1Password 마스터 비밀번호를 한 번 묻는다 (2026-08-18 실제 검증: `op read`는 세션이 없으면 `You are not currently signed in` 에러를 내므로 `op signin` 선행이 필수다).

### 검증

```bash
claude doctor       # 설치 상태 진단
claude -p "1+1"     # 응답이 오면 인증까지 완료
```

### 업데이트

dnf 저장소 설치는 자동 업데이트되지 않는다. 시스템 업데이트에 얹혀 간다.

```bash
sudo dnf upgrade claude-code
```
