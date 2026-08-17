# GEM12 기반 1인용 Private Cloud 구축 계획

> 날짜: 2026-08-17 (월)
> 대상 장비: Tianbei GEM12 (Ryzen 7 8845HS / 60GB RAM / NVMe 1TB / RX 7900 XTX via OCuLink)
> 현재 Fedora Workstation 데스크톱을 포맷하고 Proxmox 전용 서버로 전환한다.

## 한줄 요약

혼자 쓰는 개인 서버를 만든다. Git 저장소와 CI/CD, 업무 기록과 지식저장소, 로컬 LLM 추론, 이미지·영상 작업 환경, 사진과 미디어 보관을 한 장비에서 돌린다. 디스크가 1개뿐이라 이중화가 없으므로 **백업이 유일한 방어선**이고, 모든 설정을 Git에 남겨 **다른 장비에서 그대로 재구축할 수 있는 상태**를 유지한다. 2027년 초 새 장비(WTR MAX)로 옮길 때 이 설정을 재적용해 서비스가 살아나는지가 최종 검증이다.

---

## 1. 장비 실측

2026-08-17 측정값이다. 이 문서의 모든 용량 계산은 이 숫자에 근거한다.

| 항목 | 실측값 |
|---|---|
| CPU | AMD HawkPoint (8845HS 계열), 8코어 16스레드 |
| RAM | 32GB × 2 = 64GB (60GB 사용 가능), DIMM 슬롯 2개 모두 사용 중 |
| NVMe | 1TB × 1 (SHPP41-1000GM), 현재 btrfs, **수명 소모 1%** |
| 확장 슬롯 | 5개 중 4개 사용(J97 / J98 / J103 / J91), **`U93` 1개 비어 있음** |
| HDD | 없음 |
| iGPU | Radeon 780M (`c8:00.0`, IOMMU 그룹 23 단독) |
| dGPU | RX 7900 XTX (`03:00.0`, IOMMU 그룹 17 단독, OCuLink PCIe 4.0 x4) |
| 유선 NIC | 2.5GbE × 2 (`eno1`, `enp5s0`) — 랜선이 없어 사용하지 않음 |
| 무선 NIC | Intel Wi-Fi 6 AX200 (`wlp6s0`, `iwlwifi`) — **주 연결** |
| 현재 디스크 사용량 | 621GB / 929GB (59%) |

### 공식 스펙과 대조

AOOSTAR GEM12+ 공식 사양은 다음과 같다. 실측값과 맞춰보면 확장 여지가 분명해진다.

| 항목 | 공식 최대 | 현재 | 여유 |
|---|---|---|---|
| M.2 2280 NVMe (PCIe 4.0 x4) | **2슬롯, 8TB** | 1TB × 1 | **슬롯 1개 비어 있음** |
| DDR5-5600 SO-DIMM | 2슬롯, 128GB | 32GB × 2 | 교체하면 증설 가능 |
| 2.5GbE RJ45 | 2포트 | 미사용 | |
| OCuLink | 1포트 | 7900 XTX 연결 | |

공식 문서가 **"OCuLink 포트는 M.2 슬롯을 점유하지 않는다"**고 명시한다. 즉 외장 GPU를 연결한 상태에서도 M.2 2개를 온전히 쓸 수 있다.

### 실측값이 계획에 미치는 영향

**빈 M.2 슬롯이 있다.** `dmidecode`가 보고한 빈 슬롯 `U93`가 이것이다. 2TB를 꽂으면 §2의 용량 압박이 사라지고 모델과 미디어를 별도 디스크로 분리할 수 있다. 다만 **당분간 하드웨어를 추가하지 않기로 했으므로 1TB 안에서 운영한다.**

**NVMe 수명 소모가 1%다.** 사실상 새 디스크이므로 그대로 재사용한다.

**RAM 증설은 교체를 뜻한다.** 슬롯 2개가 모두 차 있어 늘리려면 기존 32GB 두 장을 빼야 한다. 공식 최대가 128GB이므로 48GB나 64GB 두 장으로 바꿀 수 있다. §4의 LXC 할당 합계가 54GB라 지금은 필요하지 않다.

---

## 2. 디스크 예산

### 지금 지우는 것

게임을 하지 않기로 했고 서버에는 데스크톱 환경이 없으므로 다음은 전부 사라진다.

| 항목 | 크기 | 근거 |
|---|---:|---|
| `.local/share/Steam` | 149G | 게임 안 함 |
| `.local/share/containers` (podman overlay) | 66G | 이미지 재빌드 가능 |
| `.cache` | 63G | 재생성됨 |
| `Videos/Wallpapers` (wallpaperengine) | 55G | 서버에 데스크톱 없음 |
| `.npm` | 13G | 재생성됨 |
| `Library` / `.var` / `bottles` / `waydroid` / `flatpak` | ~28G | 데스크톱 전용 |
| **소계** | **~374G** | |

포맷하면 어차피 전부 사라지지만, **백업 대상에서 제외할 목록**이라는 점이 중요하다.

### 지켜야 하는 데이터

| 항목 | 크기 | 복구 경로 |
|---|---:|---|
| `Documents/models` (LLM GGUF) | 63G | HuggingFace 재다운로드 — 느리지만 가능 |
| `comfyui-playground/data/models` | 65G | 재다운로드 가능 |
| 코드 저장소 (`transcodes`, `bfai`, `personal_labs`, `moon_bird`) | ~30G | Git 원격 — 포맷 전 확인 필요 |
| `obsidian/cyprien_vault` | 1.1G | GitHub 원격에 있음 (확인됨) |
| `Pictures` | 717M | Immich 초기 데이터로 사용 |
| `Dropbox` / `Downloads` | ~15G | 선별 필요 |
| `dotfiles` | 2G | GitHub |

### 신규 시스템 용량 배분 (1TB 기준)

```text
Proxmox 호스트 + LXC 루트                    ~120G
LLM 모델 (Muse Glimmer 30B + drafter + 여유)  ~150G
ComfyUI 모델 (로컬 노드용 최소 구성)           ~80G
Forgejo 저장소 + CI 캐시                       ~80G
앱 데이터 / SQLite / n8n / 온톨로지            ~50G
Immich 원본                                   ~50G
Jellyfin 미디어                                미정
────────────────────────────────────────────────
합계                                         ~530G + Jellyfin
```

### 사진과 미디어는 외장 SSD가 원본이다

사진과 블루레이 백업본의 원본은 **외장 SSD에 있다.** 서버의 Immich와 Jellyfin에 넣는 것은 사본이므로, 서버에 다 들어가지 않아도 데이터를 잃지 않는다.

이 사실이 두 가지를 바꾼다.

**용량 계획에 여유가 생긴다.** 위 배분에서 Immich 50GB와 Jellyfin 몫은 상한이 아니라 "들어가는 만큼 넣는다"가 된다. 부족하면 선택적으로 정리하면 되고, 서버가 원본을 책임지지 않으므로 무엇을 뺄지 자유롭게 정할 수 있다.

**백업 등급이 내려간다.** 서버의 사진은 이미 사본이므로 Google Drive까지 3중으로 올릴 필요가 약하다. §6에서 "여유가 되면 백업"으로 분류한다. 다만 외장 SSD도 고장 나고 두 사본이 모두 집 안에 있으면 화재나 도난에 함께 사라지므로, **외장 SSD의 SMART 상태를 정기적으로 확인**한다.

빈 M.2 슬롯이 하나 있으므로 나중에 2TB를 추가할 수 있다. 모델과 미디어를 옮기면 1TB는 시스템과 앱 데이터 전용이 되고 위 배분에서 230GB(모델 150G + ComfyUI 80G)가 빠진다. 다만 **당분간은 디스크를 추가하지 않고 1TB로 운영한다.**

---

## 3. 서비스 구성

### 무엇을 두는가

| 서비스 | 역할 |
|---|---|
| **Forgejo + Actions** | Git 저장소와 CI/CD. GitHub로 미러 복제. |
| **Headscale** | 개인 VPN 컨트롤 플레인. 회사 Tailscale과 완전 분리. |
| **llama.cpp + Muse Glimmer 30B** | 로컬 LLM 추론. 7900 XTX 사용. |
| **ComfyUI** | 이미지·영상 작업. 클라우드 모델(Seedream / GPT Image / Veo / Gemini) 위주, 로컬 노드 병행. |
| **SQLite + Litestream** | 업무 기록, 지식저장소, 온톨로지의 저장 계층. 서비스별 파일 분리. |
| **n8n** | 자동화 워크플로. 외부 서비스 연동은 n8n 웹 UI에서 설정한다. |
| **Immich** | 개인 사진 보관. 최소 구성. |
| **Jellyfin** | 개인 블루레이 백업 재생. 최소 구성. |
| **Uptime Kuma / Prometheus / Grafana** | 모니터링. 다른 서비스가 안정적으로 돌아간 뒤 추가. |

### 무엇을 두지 않는가

혼자 쓰는 시스템이므로 다음은 필요하지 않다. 나중에 사람이 늘면 그때 다시 판단한다.

| 구성요소 | 근거 |
|---|---|
| IdP / SSO (Authentik 류) | 사용자가 1명이면 통합할 계정 체계가 없다. 서비스별 단일 계정으로 충분하다. |
| 그룹 기반 접근제어 | 위와 같다. |
| 자체 시크릿 서버 (Vaultwarden 류) | 이미 1Password를 쓰고 있고 SSH 에이전트도 연동돼 있다. `op` CLI로 시크릿을 주입한다. |
| 자체 PaaS (Coolify / Dokploy 류) | 여러 사람이 배포할 때 값어치가 있다. 혼자면 Forgejo Actions에서 `docker compose`로 직접 배포하는 편이 단순하고 빠르다. |
| ZFS | 디스크가 1개라 ZFS의 강점이 나오지 않는다. 아래 참조. |
| Kubernetes / Ceph / 분산 DB | 단일 노드에 운영 복잡도만 늘린다. |

### 파일시스템 — btrfs를 유지한다

Proxmox 설치 관리자는 ZFS를 기본으로 권하지만, 이 장비에서는 현재 쓰고 있는 **btrfs를 유지한다.**

둘은 성격이 비슷하다. 모두 Copy-on-Write 방식이라 스냅샷이 순간이고 용량을 거의 쓰지 않으며, 체크섬으로 데이터 손상(bit rot)을 탐지하고, 전원이 나가도 `fsck` 없이 복구된다. 백업 1단계의 스냅샷은 어느 쪽에서든 똑같이 동작한다.

차이는 여러 디스크를 묶을 때 나온다. RAID 구성, 손상 자동 복구(체크섬이 틀리면 다른 디스크의 사본으로 고침), 풀 확장이 그것이다. **디스크가 1개면 이 이점이 전부 사라진다.** 체크섬이 손상을 탐지해도 고칠 사본이 없어 "이 파일이 망가졌다"고 알려주는 데서 끝난다.

남는 차이는 세 가지이고, 모두 btrfs 쪽이 유리하다.

- **ZFS는 RAM을 많이 쓴다.** ARC 캐시가 기본적으로 RAM 절반을 가져간다. 이 시스템은 60GB 중 54GB를 LXC에 할당하므로 ARC를 강제로 제한해야 하는데, 굳이 제약을 만들 이유가 없다.
- **ZFS는 커널 모듈을 다시 컴파일해야 한다.** CDDL과 GPL이 충돌해 ZFS는 커널에 포함될 수 없고, DKMS가 설치 시점에 소스를 컴파일해 모듈을 만든다. 커널을 올릴 때마다 이 과정이 반복되며, 새 커널의 내부 API에 OpenZFS가 아직 대응하지 않았으면 컴파일이 실패한다. 루트 파일시스템이 ZFS면 부팅 자체가 막힌다. Proxmox는 커널과 OpenZFS 버전 조합을 검증해 내보내고 이전 커널을 남겨두는 방식으로 이 위험을 관리하지만, 위험 자체가 없어지지는 않는다. btrfs는 커널 메인라인에 있어 이 문제가 아예 없다.
- **btrfs는 이미 깔려 있고 잘 돌아간다.** Fedora가 몇 년째 기본값으로 쓰는 구성이다.

빈 슬롯에 2TB를 추가하더라도 판단은 그대로다. 별도 볼륨으로 쓰면 btrfs로 충분하고, 두 디스크를 미러로 묶더라도 btrfs RAID1은 안정적이다.

### HDD 여러 개로 확장할 때는 ZFS로 간다

디스크가 4개 이상이 되면 판단이 뒤집힌다. **btrfs RAID5/6를 쓸 수 없기 때문이다.**

btrfs RAID5/6에는 "write hole" 문제가 있다. 스트라이프를 쓰는 도중 전원이 나가면 데이터와 패리티가 어긋난 채 남고, 나중에 디스크 하나가 죽어 복구를 시도하면 그 잘못된 패리티로 멀쩡한 데이터까지 망가뜨린다. 커널 문서가 지금도 프로덕션 사용을 경고한다.

그러면 btrfs로 4디스크를 쓰는 방법은 RAID1(미러)뿐인데 용량 효율이 50%다. 20TB 4개면 40TB만 쓴다. ZFS RAIDZ1은 같은 구성에서 60TB를 쓰고, 가변 폭 스트라이프를 쓰기 때문에 write hole이 구조적으로 생기지 않는다.

| 구성 | 파일시스템 | 근거 |
|---|---|---|
| NVMe 1개 (현재) | btrfs | RAID 기능을 쓸 데가 없다 |
| NVMe 2개 | btrfs | RAID1로 충분하고 갈아엎을 이유가 없다 |
| HDD 4개 이상 | ZFS RAIDZ1 또는 RAIDZ2 | btrfs RAID5/6를 쓸 수 없고, RAID1은 용량 절반을 잃는다 |

한 장비에서 두 파일시스템을 함께 써도 된다. Proxmox는 스토리지를 여러 개 등록하는 것이 정상적인 운영 방식이므로, NVMe는 btrfs로 두고 HDD 풀만 ZFS로 구성하면 된다.

**확장을 대비해 지금 해둘 일이 있다.** btrfs를 ZFS로 변환하는 방법은 없으므로, 확장 시점에는 데이터를 옮겼다가 되돌려야 한다. 이 작업을 줄이려면 **서비스 데이터를 마운트 지점으로 추상화한다.** 컨테이너가 `/mnt/data/immich` 같은 경로만 알고 그 아래가 어떤 파일시스템인지 모르게 해두면, 스토리지를 바꿀 때 마운트만 옮기면 된다. compose 파일에 호스트 경로를 직접 적어두면 이 작업이 훨씬 번거로워진다.

---

## 4. 가상화 — VM이 아니라 LXC

Proxmox VE를 베어메탈에 설치하고, 서비스는 **LXC 컨테이너**로 나눈다.

### LXC를 택한 이유

**첫째, GPU 문제다.** RDNA3(7900 XTX)는 vendor-reset을 지원하지 않아 VM 패스스루 후 재시작 시 GPU가 복구되지 않는 사례가 알려져 있다. LXC는 호스트 커널의 `amdgpu` 드라이버를 공유하고 `/dev/dri` 노드만 바인드마운트하므로 이 문제를 구조적으로 회피한다.

**둘째, llama.cpp가 Vulkan 백엔드를 쓴다** (`run-muse-glimmer-server.sh`의 `-dev Vulkan0`). ROCm이었다면 `/opt/rocm` 전체 스택과 커널 모듈 버전 맞추기 때문에 컨테이너 이미지가 수십 GB로 커지지만, Vulkan은 호스트 `amdgpu` + `/dev/dri/renderD*` + Mesa RADV만 있으면 된다. 바인드마운트 한 줄이면 된다.

**셋째, 60GB RAM 제약이다.** VM 5개는 게스트 커널과 메모리 예약이 각각 필요해 60GB로는 여유가 없지만, LXC는 커널을 공유해 오버헤드가 훨씬 작다.

### 구성도

```text
GEM12 / Proxmox VE (베어메탈)
│
├── core-lxc          2 vCPU / 6GB    Debian 13 + Podman
│   ├── Forgejo              ← Git 저장소, GitHub 미러 복제
│   ├── Headscale            ← 개인 VPN 컨트롤 플레인
│   └── (후순위) Uptime Kuma / Prometheus / Grafana
│
├── ci-lxc            6 vCPU / 8GB    Debian 13 + Docker
│   ├── Forgejo Runner
│   └── Docker / BuildKit / 빌드 캐시
│
├── apps-lxc          4 vCPU / 8GB    Debian 13 + Docker
│   ├── n8n
│   ├── 업무기록 / 지식저장소 / 온톨로지 백엔드
│   ├── SQLite (서비스별 파일 분리)
│   └── Litestream → 로컬 경로 (rclone이 Drive로 올림, §6 참조)
│
├── ai-lxc            6 vCPU / 24GB   Debian 13 + Podman  ← /dev/dri (7900 XTX)
│   ├── llama.cpp (Muse Glimmer 30B + DFlash drafter)
│   └── ComfyUI (클라우드 모델 라우팅 + 로컬 노드)
│
└── media-lxc         4 vCPU / 8GB    Debian 13 + Podman  ← /dev/dri (780M)
    ├── Immich
    └── Jellyfin
```

RAM 합계 54GB로 60GB 안에 들어간다. LXC는 미사용 메모리를 호스트에 반납하므로 실제 여유는 더 크다.

### 운영체제 — Debian 13, 데스크톱 환경 없음

모든 LXC에 **Debian 13(Trixie) 최소 구성**을 쓴다. Proxmox 자체가 Debian 기반이라 LXC 템플릿이 공식 제공되고 가장 검증된 조합이다. 서버에는 릴리스 주기가 짧은 배포판보다 안정성이 우선이다.

**데스크톱 환경은 어디에도 설치하지 않는다.** Wayland나 X11 컴포지터가 없으면 패키지가 줄고 공격 표면도 작아진다. 접근 경로는 세 가지다.

```text
맥북 → Headscale VPN ─┬→ Proxmox 웹 UI    (호스트와 LXC 관리, noVNC 콘솔 내장)
                      ├→ 각 서비스 웹 UI  (Forgejo, n8n, Immich, ComfyUI …)
                      └→ SSH              (LXC 직접 접속)
```

Proxmox 웹 UI에 noVNC 콘솔이 들어 있어 SSH가 막혀도 브라우저에서 LXC 셸에 들어갈 수 있다. 데스크톱 환경이 필요 없는 이유다.

### 브라우저가 없어도 OAuth 인증은 된다

서버에 브라우저가 없으면 OAuth 로그인이 막힐 것 같지만, **인증을 맥북에서 하고 토큰만 서버로 옮기면 된다.** OAuth 인증 코드는 브라우저와 같은 기기의 `localhost`로 돌아오지만, 그렇게 발급된 토큰에는 기기 정보가 없어 어디서든 쓸 수 있다.

이 시스템에서 OAuth가 실제로 필요한 곳은 **rclone의 Google Drive 연결 하나**다. rclone은 이 상황을 위한 명령을 제공한다.

```bash
# 맥북 (브라우저 있음)
rclone authorize "drive"        # 브라우저가 열리고, 터미널에 토큰 JSON이 출력된다

# 서버 (브라우저 없음)
rclone config                   # 자동 인증 여부를 묻는 항목에 N을 답하고 토큰을 붙여넣는다
```

한 번만 하면 된다. 이후에는 refresh token으로 갱신되므로 재인증이 필요 없다.

SSH 포트 포워딩으로도 된다. `ssh -L 53682:localhost:53682 <서버>`로 터널을 만들면 서버가 연 localhost 포트를 맥북 브라우저가 볼 수 있어, 서버에서 직접 `rclone config`를 돌려도 인증이 끝난다.

나머지 서비스는 OAuth가 필요 없거나 브라우저 문제와 무관하다.

| 서비스 | 인증 방식 |
|---|---|
| Forgejo → GitHub 미러 | Personal Access Token |
| Headscale 노드 등록 | 프리어스키 |
| Immich / Jellyfin | 자체 계정 |
| ComfyUI 클라우드 모델 | API 키 |
| n8n의 외부 연동 | n8n 웹 UI에서 처리. OAuth 창은 **맥북 브라우저**에 뜨므로 서버에 브라우저가 없는 것과 무관하다. 리다이렉트 URL만 서버 주소로 맞춘다 |

### 브라우저 자동화는 headless로 돌린다

Playwright, Puppeteer, chrome-devtools MCP 같은 도구는 브라우저를 필요로 하지만 **데스크톱 환경은 필요로 하지 않는다.** Chromium은 `--headless` 모드에서 화면 없이 렌더링하고, X11이나 Wayland 없이 공유 라이브러리 몇 개만 있으면 된다. CI 파이프라인이 매일 이 방식으로 브라우저 테스트를 돌린다.

앞 절의 OAuth와는 성격이 다르다. OAuth는 **사람이 보는 화면**이 필요해 맥북에서 처리하지만, 브라우저 자동화는 **프로그램이 조작하는 엔진**이 필요할 뿐이라 서버에서 그대로 돌아간다.

배치는 용도에 따라 갈린다.

| 상황 | 브라우저가 도는 곳 | 조치 |
|---|---|---|
| 맥북에서 Claude Code 실행 (평소) | 맥북 Chrome | 서버에 필요한 것이 없다. MCP 서버는 Claude Code가 도는 기기에서 실행되므로 서버가 관여하지 않는다 |
| CI의 E2E 테스트 | ci-lxc | Playwright 공식 이미지(`mcr.microsoft.com/playwright`)를 쓰면 의존성이 모두 들어 있다 |
| 서버에서 SSH로 Claude Code 실행 | ci-lxc 또는 apps-lxc | `npx playwright install --with-deps chromium`으로 headless Chromium을 설치한다 |
| n8n 워크플로의 스크래핑 | apps-lxc | 위와 같다 |

평소 작업은 맥북에서 하므로 첫 줄이 기본이다. 나머지는 필요해질 때 해당 LXC에 추가한다.

ai-lxc만 예외를 검토한다. RDNA3 Vulkan은 최신 Mesa가 유리한데 Debian 13의 Mesa로 충분한지는 실제로 올려봐야 안다. 부족하면 `backports`로 올리고, 그래도 모자라면 이 LXC만 Fedora로 바꾼다.

### 컨테이너 런타임 — LXC별로 나눈다

Docker와 Podman 중 하나로 통일하지 않는다. **이미 용도가 갈려 있고 그 분업이 합리적이다.** 현재 이 장비에서 업무 프로젝트는 Docker로(`docker-compose.yml` 10개 이상), GPU 작업은 Podman으로(`comfyui-rocm`, `rocm/pytorch`) 돌고 있다.

| LXC | 런타임 | 근거 |
|---|---|---|
| core-lxc | **Podman** | 데몬이 없어 systemd가 컨테이너를 직접 관리한다. Headscale이 죽으면 서버에 들어갈 VPN이 죽으므로, 이 계층은 데몬 하나에 운명을 묶지 않는다 |
| ci-lxc | **Docker** | Forgejo Actions Runner가 Docker 소켓을 전제한다. BuildKit도 Docker 쪽이 성숙하다 |
| apps-lxc | **Docker** | 기존 compose 파일을 그대로 쓴다. n8n 공식 문서도 Docker 기준이다 |
| ai-lxc | **Podman** | 이미 ComfyUI를 Podman으로 운영 중이다. rootless로 `/dev/dri`를 넘기는 방식이 깔끔하다 |
| media-lxc | **Podman** | 780M VAAPI 접근이 같은 이유로 유리하다 |

core-lxc에서 Podman을 쓰는 이유를 더 적어둔다. Docker는 `dockerd`가 모든 컨테이너의 부모여서 데몬이 죽으면 그 아래가 전부 죽고, systemd 입장에서는 개별 컨테이너가 보이지 않는다. Podman은 각 컨테이너가 독립 프로세스라 Quadlet(`.container` 파일)로 정의하면 **systemd가 일반 서비스처럼 다룬다.** 부팅 순서, 의존성, 재시작 정책이 전부 systemd 표준 방식으로 관리된다.

CI는 CPU를 순간적으로 많이 쓰므로 다른 서비스와 분리하고, Runner에 CPU와 메모리 상한을 설정한다.

### GPU 배분

두 GPU가 서로 다른 IOMMU 그룹에 단독으로 있어, 각각 다른 컨테이너에 할당할 수 있다.

```text
IOMMU 17 → 03:00.0  RX 7900 XTX  → ai-lxc     (LLM 추론 + ComfyUI)
IOMMU 23 → c8:00.0  Radeon 780M  → media-lxc  (VAAPI 트랜스코딩)
```

**서버로 전환하면 VRAM 여유가 생긴다.** 현재 Muse Glimmer는 24560MiB 중 21734MiB를 점유하고 나머지 2826MiB를 데스크톱 렌더링이 쓰고 있다. 데스크톱이 없어지면 이 2826MiB를 **ComfyUI 로컬 노드에 배정한다**. 평소 ComfyUI는 클라우드 모델을 쓰므로 VRAM을 거의 안 쓰지만, 업스케일이나 컨트롤넷을 로컬에서 실행할 때 이 3GB가 필요하다. Glimmer 설정 자체는 128k 컨텍스트 그대로 둔다(학습된 상한이 131072라 더 늘려도 실익이 없다).

---

## 5. 네트워크

### 회사 Tailscale과 완전 분리

Tailscale은 **회사 서버 접속 전용**이다. 이 개인 서버는 회사 tailnet에 절대 등록하지 않고, 서버에 회사 Tailscale 클라이언트를 설치하지도 않는다.

회사 tailnet에 개인 서버를 등록하면 (1) 회사 관리자가 개인 서버 노드를 보게 되고, (2) ACL 정책을 스스로 정할 수 없으며, (3) 계정이 회수되면 개인 인프라 접근도 함께 끊긴다. 개인 인프라는 개인이 통제해야 하므로 자체 Headscale을 쓴다.

```text
GEM12 (서버)
  └── Headscale 컨트롤 플레인 + 자기 자신이 노드
        회사 Tailscale 클라이언트 설치하지 않음

MacBook Pro / 휴대 기기 (클라이언트)
  ├── 프로파일 A: 회사 Tailscale  (업무용)
  └── 프로파일 B: 개인 Headscale  (이 서버용)
        tailscale switch 로 전환
```

Tailscale 클라이언트는 여러 컨트롤 서버 프로파일을 저장하고 `tailscale switch`로 오갈 수 있다. 동시 접속은 안 되지만, **서버 쪽에서 회사 tailnet을 아예 쓰지 않으므로 문제되지 않는다.**

### 물리 연결 — Wi-Fi로 운영한다

랜선이 부족하므로 **Wi-Fi(Intel AX200, `wlp6s0`)를 주 연결로 쓴다.** AX200은 `iwlwifi` 메인라인 드라이버를 쓰고 Proxmox는 Debian 기반이라, `firmware-iwlwifi`와 `wpasupplicant`만 설치하면 동작한다.

두 가지를 유의한다.

**Proxmox ISO 설치 관리자에는 Wi-Fi 설정 화면이 없다.** 설치는 네트워크 없이 끝나고, 첫 부팅 후 콘솔에서 직접 Wi-Fi를 연결해야 한다. 따라서 모니터와 **유선 키보드·마우스**가 필요하다. 유선 랜이라면 이 단계가 자동으로 넘어가지만, 어차피 Proxmox 설치 자체에 모니터가 필요하므로 추가 부담은 없다.

블루투스 키보드·마우스는 설치에 쓸 수 없다. 블루투스 어댑터가 AX200에 통합돼 있고(`8087:0029`), UEFI 펌웨어와 설치 관리자는 USB HID만 인식한다. 게다가 포맷하면 `/var/lib/bluetooth`의 페어링 키가 사라지므로, 새 시스템에서 페어링하려면 그 작업을 할 입력 장치가 먼저 필요한 순환에 빠진다. 설치를 마친 뒤에는 `bluetoothctl`로 페어링해 쓸 수 있으나, 서버 운영 중에는 콘솔을 쓸 일이 드물어 실익이 적다.

**무선에서는 일반적인 브리지가 동작하지 않는다.** 802.11 규격상 무선 클라이언트는 자기 MAC 주소로만 프레임을 보낼 수 있어, 컨테이너의 다른 MAC이 붙은 프레임을 공유기가 버린다. 그래서 컨테이너가 공유기에서 각자 IP를 받는 `vmbr0` 브리지 대신 **NAT 브리지**를 쓴다.

```text
wlp6s0 (공유기 DHCP)
   │ 마스커레이딩
   ▼
vmbr0  10.10.10.1/24  (내부 전용, 물리 포트 없음)
   ├── core-lxc    10.10.10.11
   ├── ci-lxc      10.10.10.12
   ├── apps-lxc    10.10.10.13
   ├── ai-lxc      10.10.10.14
   └── media-lxc   10.10.10.15
```

모든 접근이 Headscale VPN을 거치는 설계이므로 컨테이너가 LAN IP를 각자 가질 이유가 없다. 격리 면에서는 이쪽이 낫다.

대역폭은 5GHz Wi-Fi 6 기준 실효 300~600Mbps로, Git push나 사진 업로드에는 충분하다. 대용량 미디어를 처음 넣을 때만 USB로 직접 옮긴다.

랜선이 생기면 `eno1`을 연결해 `wlp6s0`를 대체한다. NAT 브리지 구조는 그대로 두고 상위 인터페이스만 바꾸면 된다.

### 순환 의존 대비

Headscale이 GEM12 안에 있으므로 서버가 죽으면 들어갈 VPN도 함께 죽는다. 대비책은 **모니터와 키보드를 직접 연결하는 것**이다. 집에 있는 장비이므로 이것으로 충분하다.

Wi-Fi가 끊기면 원격 복구가 불가능하지만, 이는 유선이어도 서버 자체가 죽으면 마찬가지다. 외출 중 장애는 복구를 포기하고 귀가 후 처리한다. 혼자 쓰는 시스템에서 이 정도 가용성이면 충분하고, 외부 VPS를 두는 비용과 의존이 더 크다.

LAN 안에서는 키 인증 전용 SSH를 열어두되 비밀번호 로그인은 차단한다.

### 공개 범위

당분간 인터넷에 공개하는 서비스는 없다. 모든 접근은 Headscale VPN을 거친다.

| 대상 | 접근 경로 |
|---|---|
| Proxmox / SSH / Forgejo / n8n / Immich / Jellyfin / ComfyUI / llama.cpp / 모니터링 | VPN 전용 |

외부에 공개할 서비스가 생기면 그때 리버스 프록시와 도메인을 설정한다. **주소는 IP가 아니라 도메인으로 구성**해서, 장비를 옮길 때 DNS만 바꾸면 되게 한다.

---

## 6. 백업 — 이 시스템의 유일한 방어선

디스크가 1개라 RAID가 없다. btrfs 체크섬이 손상을 탐지해도 고칠 사본이 없으므로, **서버에만 있는 데이터는 디스크가 죽으면 전부 잃는다.** 3단계 백업은 선택이 아니다.

다만 모든 데이터가 같은 등급은 아니다. 사진과 미디어는 외장 SSD에 원본이 있고 모델 가중치는 재다운로드할 수 있으므로, **서버가 유일한 사본인 것**을 먼저 지킨다.

### 1단계 — 로컬 스냅샷 (실수 복구)

btrfs 스냅샷. 디스크 고장은 막지 못하지만 실수 삭제와 잘못된 업데이트 되돌리기에 쓴다.

### 2단계 — Google Drive (재해 복구)

개인 Google Drive 약 5TB. **전체 디스크가 아니라 필수 요소만** 올린다. 로컬에서 먼저 암호화한다 (`rclone crypt` 또는 `restic`). 평문 DB나 시크릿을 그대로 올리지 않는다.

**반드시 백업** — 서버가 유일한 사본이다

- Forgejo 설정 DB (Issue, PR, Actions 설정, 사용자·조직 설정, 웹훅). 저장소 내용 자체는 GitHub 미러가 맡으므로 제외한다
- SQLite DB (업무기록 / 지식저장소 / 온톨로지)
- n8n 워크플로와 자격증명
- 각 서비스 설정과 compose 파일 (Forgejo에도 있지만 이중화)
- Headscale DB와 프리어스키

**Forgejo 저장소 내용은 백업하지 않는다.** GitHub 미러가 이미 사본이므로 Drive까지 올리면 3중이 된다. 다만 미러가 옮기는 것은 Git 저장소뿐이고 Issue와 Actions 설정은 넘어가지 않으므로, **설정 DB만** 백업한다.

**여유가 되면 백업** — 다른 곳에 사본이 있다

- Immich 사진. 원본이 외장 SSD에 있어 서버 쪽은 이미 사본이다. 다만 두 사본이 모두 집 안에 있으므로 화재나 도난에는 함께 사라진다. 용량이 허락하면 올린다.

**백업하지 않음** — 재생성하거나 다시 받을 수 있다

- Forgejo 저장소 내용. GitHub 미러가 사본이다
- LLM / ComfyUI 모델 가중치. 128GB나 되고 재다운로드할 수 있다. **다만 목록과 다운로드 스크립트는 Git에 남긴다.** 이것이 실질적인 백업이다.
- Jellyfin 미디어. 원본이 외장 SSD에 있다.
- CI 캐시, Docker 레이어
- Jellyfin 메타데이터, 트랜스코딩 임시파일
- Immich 썸네일

### Litestream은 Google Drive에 직접 쓸 수 없다

Litestream이 지원하는 대상은 S3 API 계열(S3, GCS, Azure Blob, SFTP)이고 **Google Drive는 여기에 없다.** WAL 프레임을 초 단위로 증분 업로드하며 세대를 관리하려면 객체 스토리지의 조건부 쓰기가 필요한데, 파일 동기화용인 Drive API는 이를 제공하지 않는다.

`rclone mount`로 Drive를 파일시스템처럼 붙이는 우회는 **쓰지 않는다.** 네트워크 마운트 위에서 SQLite 잠금이 깨지면 DB가 손상된다. 백업하려다 원본을 망가뜨리는 구조다.

대신 두 단계로 나눈다.

```text
SQLite (apps-lxc)
   │ Litestream — 초 단위 증분 복제
   ▼
서버 내 별도 경로 (/mnt/data/litestream)
   │ rclone sync — 시간 단위, 암호화
   ▼
Google Drive
```

Litestream은 로컬 경로(`file://`)로 복제하고, `rclone sync`가 그 결과를 주기적으로 Drive에 올린다. Drive 반영이 시간 단위로 늦어지지만 개인 업무 기록에서 그 정도 손실은 감당할 수 있고 비용이 들지 않는다.

실시간 오프사이트 복제가 필요해지면 Cloudflare R2 같은 S3 호환 서비스를 붙인다. 월 1~2달러 수준이고 Litestream이 직접 쓸 수 있다. **서버 안에 MinIO를 띄우는 방식은 의미가 없다** — 복제본이 원본과 같은 디스크에 남아 재해 복구가 되지 않는다.

### 3단계 — 오프라인 사본

암호화된 외장 SSD. 계정 잠김이나 클라우드 접근 불가에 대비한다. 분기 1회 갱신이면 충분하다.

사진과 미디어 원본이 담긴 외장 SSD도 이 등급에 속한다. 서버와 함께 이 SSD가 사진의 두 사본을 이루므로, **갱신할 때 SMART 상태를 함께 확인**한다.

```bash
sudo smartctl -H /dev/sdX
```

### 서버 밖에 둘 것

서버가 죽었을 때 필요한 정보는 서버 안에 두지 않는다.

- Google 계정 복구 정보
- 백업 암호화 키
- Proxmox root 비밀번호
- Headscale 프리어스키

1Password에 넣되, **1Password 자체 복구 키는 종이로 오프라인 보관**한다.

---

## 7. Git 전략 — Forgejo + GitHub 미러

Forgejo가 주 저장소이고, GitHub에 미러로 복제한다.

```text
개발 (MacBook)
   │ git push
   ▼
Forgejo (GEM12)  ── Actions → 빌드/배포
   │ mirror push
   ▼
GitHub (개인)     ← 서버가 죽어도 코드는 남아 있음
```

이 구조의 실익은 **장비를 옮길 때 나타난다.** GEM12를 포맷하고 새 장비를 설치하는 동안에도 GitHub에 모든 코드와 인프라 설정이 있으므로, 새 장비에서 `clone` 받아 재구축하면 된다. Obsidian vault가 이미 GitHub에 있는 것과 같은 원리다.

Forgejo의 push mirror 기능을 쓰면 이 복제가 자동으로 이뤄진다.

**미러가 옮기는 것은 Git 저장소뿐이다.** Issue, PR, Actions 설정, 사용자와 조직 설정, 웹훅은 GitHub로 넘어가지 않는다. 그래서 §6에서 저장소 내용은 백업 대상에서 빼고 **Forgejo 설정 DB만** 백업한다.

인프라 재구축에 필요한 설정은 가능한 한 Forgejo에 저장한다. 다만 시크릿은 Git에 넣지 않는다.

---

## 8. 구축 순서

각 단계에 검증 조건을 달았다. 조건을 만족하지 못하면 다음으로 넘어가지 않는다.

### 0단계 — 포맷 전 (가장 중요)

1. 모니터와 **유선** 키보드·마우스 준비. 블루투스는 설치 단계에서 쓸 수 없다
2. Wi-Fi SSID와 비밀번호를 손으로 적어둠. 설치 직후 콘솔에서 입력해야 한다
3. 모든 코드 저장소의 원격 push 상태 확인
   ```bash
   for d in ~/Documents/*/*/; do
     git -C "$d" status -sb 2>/dev/null | head -1
   done
   ```
4. 원격이 없는 로컬 전용 데이터를 찾아 외장이나 클라우드로 옮김
5. 모델 파일 목록 저장 (재다운로드 스크립트 작성)
   ```bash
   find ~/Documents/models ~/Documents/personal_labs/comfyui-playground/data/models \
     -name "*.gguf" -o -name "*.safetensors" | sort > models-manifest.txt
   ```
6. **dotfiles 커밋과 push** — 이것을 빠뜨리면 부트스트랩 스크립트째 잃는다
7. 서버에서 쓸 자격증명을 미리 발급해 1Password에 보관
   - `claude setup-token` 으로 Claude Code 장기 토큰
   - 맥북 SSH 공개키 (`cat ~/.ssh/id_ed25519.pub`) — `02-host.sh` 에 넘긴다

**검증**: 이 장비를 지금 잃어도 잃는 것이 없는 상태인가?

7번을 포맷 전에 하는 이유는 발급 자체에 브라우저가 필요해서다. 포맷 후에는 맥북으로 옮겨가야 하므로 지금 해두는 편이 낫다.

### 1단계 — Proxmox 설치

Proxmox VE를 베어메탈에 설치한다. 데스크톱 환경은 설치하지 않는다.

설치 관리자에 Wi-Fi 항목이 없으므로 네트워크 없이 설치를 끝내고, 첫 부팅 후 콘솔에서 연결한다.

```bash
apt install firmware-iwlwifi wpasupplicant
wpa_passphrase '<SSID>' '<암호>' > /etc/wpa_supplicant/wpa_supplicant-wlp6s0.conf
systemctl enable --now wpa_supplicant@wlp6s0
```

그다음 `/etc/network/interfaces`에 `wlp6s0`(DHCP)와 NAT 브리지 `vmbr0`(`10.10.10.1/24`)를 설정한다.

이 과정은 `commands/proxmox/01-network.sh` 가 자동으로 한다. 다만 저장소를 받으려면 인터넷이 먼저 필요하므로, **첫 실행만 USB로 옮기거나 손으로 친다.**

**검증**: 재부팅해도 Wi-Fi가 자동 연결되고, 맥북에서 LAN SSH 접속과 웹 UI 접근 성공

### 1.5단계 — 저장소와 도구

인터넷이 연결되면 dotfiles를 받는다.

```bash
git clone https://github.com/huskyhoochu/dotfiles.git ~/dotfiles
cd ~/dotfiles/commands/proxmox
./02-host.sh
```

**HTTPS로 받는다.** 이 저장소는 공개이므로 인증이 필요 없다. SSH로 받으려면 GitHub 키가 있어야 하는데, 이 기기의 키는 1Password 에이전트에 있고 서버에서 그것을 쓰려면 `op` CLI 인증이 먼저 필요하다. 첫 clone만 HTTPS로 하면 이 순환을 피한다.

나중에 서버에서 push가 필요해지면 두 방법이 있다.

- 맥북에서 `ssh -A`로 접속해 맥북의 1Password 에이전트를 빌려 쓴다. 서버에 키를 두지 않아 더 안전하다
- 원격을 SSH로 바꾸고 서버 전용 배포 키를 발급한다

**서버에서 `stow`로 전체를 배포하지 않는다.** 서버에 필요한 것은 `commands/proxmox/` 스크립트뿐이고, `nvim`·`tmux`·`ghostty`·`aerospace` 는 데스크톱 설정이다. 셸 환경은 `02-host.sh` 가 별도로 배포한다.

#### Claude Code

서버에서 Claude Code를 쓰려면 인증 토큰이 필요하다. 브라우저가 없으므로 **맥북에서 발급해 옮긴다.**

```bash
# 맥북 (브라우저 있음)
claude setup-token          # 구독 계정으로 장기 토큰을 발급한다

# 서버
export CLAUDE_CODE_OAUTH_TOKEN="<발급받은 토큰>"
```

토큰은 `~/.bashrc.local` 이나 1Password에 두고 셸 시작 시 주입한다. 저장소에는 넣지 않는다.

`~/.claude/.credentials.json` 을 그대로 복사하는 방법도 되지만 쓰지 않는다. 기기에 묶인 세션 자격증명이라 갱신 동작이 예측하기 어렵고, 두 기기가 같은 파일을 쓰면 한쪽의 갱신이 다른 쪽을 무효화할 수 있다.

**검증**: 서버에서 `claude -p "1+1"` 이 응답

### 2단계 — core-lxc

Headscale 먼저, 그다음 Forgejo.

**검증**: 맥북에서 개인 VPN 접속 후 Forgejo에 push 성공. 회사 Tailscale 프로파일로 전환해도 회사 서버에 정상 접속.

### 3단계 — ai-lxc

`run-muse-glimmer-server.sh`를 컨테이너와 systemd 서비스로 옮긴다. 현재는 zsh 함수(`glimmer-up`)로 수동 실행하지만, 서버에서는 부팅 시 자동 기동해야 한다.

**검증**: 맥북에서 VPN 경유로 llama.cpp API 호출 성공. 생성 속도가 기존 실측(29~68 tok/s) 수준.

> **주의**: 이 단계 검증에는 GPU 부하가 걸린다. 실행 전 알릴 것.

### 4단계 — ci-lxc + apps-lxc

Forgejo Runner 등록, n8n, SQLite와 Litestream, `rclone sync` 스케줄.

이 단계에서 **rclone의 Google Drive 인증**을 한다. 맥북에서 `rclone authorize "drive"`로 토큰을 받아 서버에 붙여넣는다(§4의 OAuth 절 참조).

**검증**: 저장소에 push하면 Actions가 자동 실행되고 배포까지 완료. Litestream이 로컬 경로에 복제하고 `rclone sync`가 Drive에 올린 것까지 확인. GitHub 미러에 커밋이 반영되는지도 함께 본다.

### 5단계 — media-lxc + ComfyUI

우선순위 최하. 설치와 기동 확인까지만 하고 데이터는 나중에 채운다.

**검증**: Immich에 사진 업로드 가능, Jellyfin 기동, ComfyUI에서 클라우드 모델 호출 성공.

### 6단계 — 모니터링

Uptime Kuma를 먼저 붙이고, 필요해지면 Prometheus와 Grafana를 추가한다.

최소 알림 대상은 다음과 같다.

```text
디스크 사용량 > 85%
NVMe 수명 경고 / SMART 경고
btrfs 체크섬 오류 (고칠 사본이 없으므로 즉시 대응해야 한다)
RAM 사용량 > 90%
비정상 CPU 온도
Wi-Fi 연결 끊김

Forgejo 응답 없음
Litestream 로컬 복제 실패
rclone sync 실패 (Drive 반영 중단)
GitHub 미러 push 실패
```

btrfs 체크섬 오류는 `btrfs device stats /` 로 확인한다. 디스크가 1개라 자동 복구가 불가능하므로, 오류가 나오면 해당 파일을 백업에서 되살리고 디스크 교체를 검토한다.

---

## 9. 미결 사항

| # | 항목 | 결정 시점 |
|---|---|---|
| 2 | 데스크톱 완전 이관 가능 여부 (맥북만으로 충분한가) | 포맷 전 |
| 3 | 블루레이 리핑 규모 → 미디어 스토리지 계획 | 리핑 시작 시 |
| 4 | ComfyUI 로컬 모델 중 실제로 필요한 것 선별 (현재 65GB) | ai-lxc 구축 시 |
| 5 | 도메인 확보 여부 (서비스 주소용) | 외부 공개 시 |

특히 **2번이 되돌리기 어려운 결정이다.** Proxmox로 전환하면 이 장비에서 GNOME 데스크톱은 사라진다. 맥북만으로 평소 작업이 되는지 며칠 미리 시험해보는 편이 안전하다.

---

## 10. 설계 원칙

**1. 단일 노드에 최적화한다.** 지금 이 장비에서 안정적으로 돌아가는 것이 최우선이다. 분산 시스템을 미리 만들지 않는다.

**2. 다른 장비에서 재구축할 수 있어야 한다.** 서버에서 수동으로 한 설정은 반드시 Git에 파일로 남긴다. "일단 손으로 고치고 나중에 문서화"를 하지 않는다. 미룬 문서화는 대체로 하지 않게 된다.

**3. 백업이 이중화를 대신한다.** 디스크가 1개라 RAID가 없다. 복구 절차가 실제로 작동하는지 주기적으로 확인한다. 디스크를 여러 개로 늘리더라도 RAID는 백업을 대신하지 못한다.

**4. 중요 데이터의 원본은 내가 통제하는 장비에 둔다.** 클라우드는 백업이지 원본이 아니다. 사진과 미디어는 외장 SSD가, 나머지는 이 서버가 원본을 맡는다. 어느 데이터의 원본이 어디에 있는지 항상 알고 있어야 한다.

**5. 시크릿은 Git에 넣지 않되, 목록은 Git에 넣는다.** 어떤 시크릿이 어디에 필요한지 알 수 없으면 재구축이 불가능하다.

**6. 관리 인터페이스는 VPN 안에 둔다.** 인터넷에 공개하는 것은 실제로 공개해야 하는 서비스뿐이다.

**7. 서비스는 스토리지 구현을 모르게 한다.** 컨테이너에는 `/mnt/data/<서비스>` 같은 마운트 지점만 노출하고 호스트 경로나 파일시스템 종류를 적어두지 않는다. 디스크를 추가하거나 파일시스템을 바꿀 때 마운트만 옮기면 되게 하기 위해서다.

---

## 11. 성공 기준

> **2027년 초 새 장비가 도착했을 때, Forgejo와 GitHub에 있는 인프라 설정을 `clone` 받아 재적용하는 것만으로 모든 서비스가 되살아나야 한다.**

이 장비에서 보내는 기간은 그 자체가 목적이 아니라 **재현성을 검증하는 기간**이다. 서비스가 돌아가는 것만으로는 성공이 아니고, 처음부터 다시 세울 수 있어야 성공이다.
