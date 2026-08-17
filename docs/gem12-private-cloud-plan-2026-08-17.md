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
| NIC | 2.5GbE × 2 (`eno1`, `enp5s0`) — 현재 둘 다 링크 다운, Wi-Fi로 운영 중 |
| 현재 디스크 사용량 | 621GB / 929GB (59%) |

### 실측값이 계획에 미치는 영향

**빈 슬롯 `U93`가 있다.** 다만 `dmidecode`의 슬롯 목록에는 M.2뿐 아니라 OCuLink와 Wi-Fi도 섞여 있으므로, 이것이 NVMe를 꽂을 수 있는 M.2 슬롯인지는 케이스를 열어 확인해야 한다. M.2로 확인되면 2TB를 추가해 §2의 용량 압박이 사라지고, 모델과 미디어를 별도 디스크로 분리할 수 있다.

**NVMe 수명 소모가 1%다.** 사실상 새 디스크이므로 그대로 재사용한다.

**RAM 증설은 교체를 뜻한다.** 슬롯 2개가 모두 차 있어 늘리려면 기존 32GB 두 장을 빼고 48GB 두 장으로 바꿔야 한다. §4의 LXC 할당 합계가 54GB라 지금은 필요하지 않다.

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

**Jellyfin이 유일한 미결 변수다.** 블루레이 리핑본은 디스크당 20~40GB라 10장이면 400GB로 예산을 넘긴다. 리핑 계획이 아직 없으므로 **Jellyfin은 설치와 기동 확인까지만 하고 미디어는 나중에 판단**한다.

`U93`가 M.2로 확인되면 이 압박이 사라진다. 2TB를 추가해 모델과 미디어를 옮기면 1TB는 시스템과 앱 데이터 전용이 되고, 위 배분에서 230GB(모델 150G + ComfyUI 80G)가 풀린다. 리핑을 시작하는 시점이 곧 디스크 추가 시점이다.

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
| **n8n** | 자동화. |
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
| ZFS mirror / RAIDZ | 디스크가 1개다. btrfs 단일 볼륨과 스냅샷을 쓴다. **이 시스템에는 디스크 이중화가 없다** — §5의 백업이 유일한 방어선이라는 뜻이다. |
| Kubernetes / Ceph / 분산 DB | 단일 노드에 운영 복잡도만 늘린다. |

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
├── core-lxc          2 vCPU / 6GB
│   ├── Forgejo              ← Git 저장소, GitHub 미러 복제
│   ├── Headscale            ← 개인 VPN 컨트롤 플레인
│   └── (후순위) Uptime Kuma / Prometheus / Grafana
│
├── ci-lxc            6 vCPU / 8GB
│   ├── Forgejo Runner
│   └── Docker / BuildKit / 빌드 캐시
│
├── apps-lxc          4 vCPU / 8GB
│   ├── n8n
│   ├── 업무기록 / 지식저장소 / 온톨로지 백엔드
│   ├── SQLite (서비스별 파일 분리)
│   └── Litestream → Google Drive / S3 호환
│
├── ai-lxc            6 vCPU / 24GB   ← /dev/dri (7900 XTX)
│   ├── llama.cpp (Muse Glimmer 30B + DFlash drafter)
│   └── ComfyUI (클라우드 모델 라우팅 + 로컬 노드)
│
└── media-lxc         4 vCPU / 8GB    ← /dev/dri (780M)
    ├── Immich
    └── Jellyfin
```

RAM 합계 54GB로 60GB 안에 들어간다. LXC는 미사용 메모리를 호스트에 반납하므로 실제 여유는 더 크다.

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

### 순환 의존 대비

Headscale이 GEM12 안에 있으므로 서버가 죽으면 들어갈 VPN도 함께 죽는다. 대비책은 **LAN 직접 SSH**다.

- 2.5GbE 유선(`eno1`)에 고정 IP 부여. 현재 둘 다 링크 다운이므로 **유선 연결이 선행 작업**이다
- 키 인증 전용 SSH, 비밀번호 로그인 차단
- 집 내부망에서만 접근하므로 외부 노출 없음

외출 중 장애는 복구를 포기하고 귀가 후 처리한다. 혼자 쓰는 시스템에서 이 정도 가용성이면 충분하고, 외부 VPS를 두는 비용과 의존이 더 크다.

### 공개 범위

당분간 인터넷에 공개하는 서비스는 없다. 모든 접근은 Headscale VPN을 거친다.

| 대상 | 접근 경로 |
|---|---|
| Proxmox / SSH / Forgejo / n8n / Immich / Jellyfin / ComfyUI / llama.cpp / 모니터링 | VPN 전용 |

외부에 공개할 서비스가 생기면 그때 리버스 프록시와 도메인을 설정한다. **주소는 IP가 아니라 도메인으로 구성**해서, 장비를 옮길 때 DNS만 바꾸면 되게 한다.

---

## 6. 백업 — 이 시스템의 유일한 방어선

디스크가 1개라 RAID도 ZFS mirror도 없다. **디스크가 죽으면 전부 잃는다.** 3단계 백업은 선택이 아니다.

### 1단계 — 로컬 스냅샷 (실수 복구)

btrfs 스냅샷. 디스크 고장은 막지 못하지만 실수 삭제와 잘못된 업데이트 되돌리기에 쓴다.

### 2단계 — Google Drive (재해 복구)

개인 Google Drive 약 5TB. **전체 디스크가 아니라 필수 요소만** 올린다. 로컬에서 먼저 암호화한다 (`rclone crypt` 또는 `restic`). 평문 DB나 시크릿을 그대로 올리지 않는다.

**반드시 백업**

- Forgejo 저장소 전체
- SQLite DB (업무기록 / 지식저장소 / 온톨로지) — Litestream 실시간 복제
- n8n 워크플로와 자격증명
- Immich 원본
- 각 서비스 설정과 compose 파일 (Forgejo에도 있지만 이중화)
- Headscale DB와 프리어스키

**백업하지 않음 (재생성 가능)**

- LLM / ComfyUI 모델 가중치. 128GB나 되고 재다운로드할 수 있다. **다만 목록과 다운로드 스크립트는 Git에 남긴다.** 이것이 실질적인 백업이다.
- CI 캐시, Docker 레이어
- Jellyfin 메타데이터, 트랜스코딩 임시파일
- Immich 썸네일

### 3단계 — 오프라인 사본

암호화된 외장 SSD. 계정 잠김이나 클라우드 접근 불가에 대비한다. 분기 1회 갱신이면 충분하다.

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

인프라 재구축에 필요한 설정은 가능한 한 Forgejo에 저장한다. 다만 시크릿은 Git에 넣지 않는다.

---

## 8. 구축 순서

각 단계에 검증 조건을 달았다. 조건을 만족하지 못하면 다음으로 넘어가지 않는다.

### 0단계 — 포맷 전 (가장 중요)

1. 유선 랜 연결 (`eno1` 링크 업 확인). 이것이 없으면 복구 경로가 없다
2. 케이스를 열어 `U93` 슬롯이 M.2인지 확인. M.2면 2TB 추가를 검토한다
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
6. dotfiles 커밋과 push

**검증**: 이 장비를 지금 잃어도 잃는 것이 없는 상태인가?

### 1단계 — Proxmox 설치

Proxmox VE를 베어메탈에 설치한다. 데스크톱 환경은 설치하지 않는다.

**검증**: 맥북에서 LAN SSH 접속과 웹 UI 접근 성공

### 2단계 — core-lxc

Headscale 먼저, 그다음 Forgejo.

**검증**: 맥북에서 개인 VPN 접속 후 Forgejo에 push 성공. 회사 Tailscale 프로파일로 전환해도 회사 서버에 정상 접속.

### 3단계 — ai-lxc

`run-muse-glimmer-server.sh`를 컨테이너와 systemd 서비스로 옮긴다. 현재는 zsh 함수(`glimmer-up`)로 수동 실행하지만, 서버에서는 부팅 시 자동 기동해야 한다.

**검증**: 맥북에서 VPN 경유로 llama.cpp API 호출 성공. 생성 속도가 기존 실측(29~68 tok/s) 수준.

> **주의**: 이 단계 검증에는 GPU 부하가 걸린다. 실행 전 알릴 것.

### 4단계 — ci-lxc + apps-lxc

Forgejo Runner 등록, n8n, SQLite와 Litestream.

**검증**: 저장소에 push하면 Actions가 자동 실행되고 배포까지 완료. Litestream 복제 상태 정상.

### 5단계 — media-lxc + ComfyUI

우선순위 최하. 설치와 기동 확인까지만 하고 데이터는 나중에 채운다.

**검증**: Immich에 사진 업로드 가능, Jellyfin 기동, ComfyUI에서 클라우드 모델 호출 성공.

### 6단계 — 모니터링

Uptime Kuma를 먼저 붙이고, 필요해지면 Prometheus와 Grafana를 추가한다.

최소 알림 대상은 다음과 같다.

```text
디스크 사용량 > 85%
NVMe 수명 경고 / SMART 경고
RAM 사용량 > 90%
비정상 CPU 온도

Forgejo 응답 없음
Litestream 복제 실패
Google Drive 백업 실패
```

---

## 9. 미결 사항

| # | 항목 | 결정 시점 |
|---|---|---|
| 1 | 빈 슬롯 `U93`가 M.2인지 물리 확인 → 2TB 추가 여부 | 포맷 전 |
| 2 | 데스크톱 완전 이관 가능 여부 (맥북만으로 충분한가) | 포맷 전 |
| 3 | 블루레이 리핑 규모 → 미디어 스토리지 계획 | 리핑 시작 시 |
| 4 | ComfyUI 로컬 모델 중 실제로 필요한 것 선별 (현재 65GB) | ai-lxc 구축 시 |
| 5 | 도메인 확보 여부 (서비스 주소용) | 외부 공개 시 |

특히 **2번이 되돌리기 어려운 결정이다.** Proxmox로 전환하면 이 장비에서 GNOME 데스크톱은 사라진다. 맥북만으로 평소 작업이 되는지 며칠 미리 시험해보는 편이 안전하다.

---

## 10. 설계 원칙

**1. 단일 노드에 최적화한다.** 지금 이 장비에서 안정적으로 돌아가는 것이 최우선이다. 분산 시스템을 미리 만들지 않는다.

**2. 다른 장비에서 재구축할 수 있어야 한다.** 서버에서 수동으로 한 설정은 반드시 Git에 파일로 남긴다. "일단 손으로 고치고 나중에 문서화"를 하지 않는다. 미룬 문서화는 대체로 하지 않게 된다.

**3. 백업이 이중화를 대신한다.** 디스크가 1개라 RAID가 없다. 복구 절차가 실제로 작동하는지 주기적으로 확인한다.

**4. 중요 데이터의 원본은 이 장비에 둔다.** 클라우드는 백업이지 원본이 아니다.

**5. 시크릿은 Git에 넣지 않되, 목록은 Git에 넣는다.** 어떤 시크릿이 어디에 필요한지 알 수 없으면 재구축이 불가능하다.

**6. 관리 인터페이스는 VPN 안에 둔다.** 인터넷에 공개하는 것은 실제로 공개해야 하는 서비스뿐이다.

---

## 11. 성공 기준

> **2027년 초 새 장비가 도착했을 때, Forgejo와 GitHub에 있는 인프라 설정을 `clone` 받아 재적용하는 것만으로 모든 서비스가 되살아나야 한다.**

이 장비에서 보내는 기간은 그 자체가 목적이 아니라 **재현성을 검증하는 기간**이다. 서비스가 돌아가는 것만으로는 성공이 아니고, 처음부터 다시 세울 수 있어야 성공이다.
