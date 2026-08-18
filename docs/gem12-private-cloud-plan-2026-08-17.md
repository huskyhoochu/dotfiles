# GEM12 기반 1인용 Private Cloud 구축 계획

> 작성: 2026-08-17 (월) · 최근 갱신: 2026-08-18 — 서버 접속 실측 반영
> 대상 장비: Tianbei GEM12 (Ryzen 7 8845HS / 60GB RAM / NVMe 1TB / RX 7900 XTX via OCuLink)
> Fedora Server 44 베어메탈 + Incus 시스템 컨테이너로 가동 중이다.

## 한줄 요약

혼자 쓰는 개인 서버다. Git 저장소와 CI/CD, 업무 기록과 지식저장소, 로컬 LLM 추론, 이미지·영상 작업 환경, 사진과 미디어 보관을 한 장비에서 돌린다. 디스크가 1개뿐이라 이중화가 없으므로 **백업이 유일한 방어선**이고, 모든 설정을 Git에 남겨 **다른 장비에서 그대로 재구축할 수 있는 상태**를 유지한다. 2027년 초 새 장비(WTR MAX)로 옮길 때 이 설정을 재적용해 서비스가 살아나는지가 최종 검증이다.

---

## 1. 남은 작업

우선순위 순이다. 현재 가동 상태는 §2, 완료된 구축 단계와 검증 결과는 §12에 있다.

### 1-1. 백업 — 남은 단계

1·2단계(매시 btrfs 스냅샷 + restic→Drive)는 가동 중이다 — 구성은 §8, 구축 기록과 복원 리허설 결과는 §12 5단계.

3단계(오프라인 사본)는 가동 중이다 — `gem12-offline-copy`(`commands/incus/services/backup/offline-copy.sh`)가 매시 스냅샷 최신본에서 핵심 데이터 tar 를 외장 SSD `gem12-offline/` 에 뜬다. **비암호화** (사용자 결정 2026-08-18 — 집 안 보관 매체라 즉시 읽기 우선). 분기 1회 SSD 연결 시 실행하며 SMART 확인이 내장돼 있다. 첫 사본 2026-08-18: 183MB, 검증 통과, SMART PASSED.
- [ ] **rclone 개인 client_id 전환.** 공용 client_id 는 2026년 중 퇴역 예고(rclone 공지) + 분당 쿼터 공유로 403 재시도가 생긴다(복원 리허설 실측). 발급은 Google Cloud Console 에서 진행 중(2026-08-18) — 프로젝트 생성 → Drive API 활성화 → OAuth 동의 화면 외부 + **앱 게시(테스트 모드는 refresh token 7일 만료)** → 데스크톱 앱 클라이언트 ID. 발급되면 남은 처리:
  1. client_id/secret 을 `op://Personal/GEM12_RCLONE_CLIENT_ID`·`GEM12_RCLONE_CLIENT_SECRET` 에 보관
  2. 맥에서 재인증 — `rclone authorize "drive" "<client_id>" "<client_secret>"` (토큰은 클라이언트에 묶여 재발급 필요, "확인되지 않은 앱" 경고는 고급→이동), 새 토큰으로 `GEM12_RCLONE_DRIVE_TOKEN` 갱신
  3. 호스트 `[gdrive]` remote 에 client_id/secret/새 토큰 반영 (restic 저장소는 무관 — 기존 백업 이력 그대로)
  4. 다음 정각 회차에서 403 재시도 소멸 실측 → 이 항목 체크 + Changelog 기록

### 1-2. 구축 5단계 — media 컨테이너 + ComfyUI

**완료** (2026-08-18) — Immich·Jellyfin·ComfyUI 가동, 웹 초기 설정까지 종료. 구성과 검증 결과는 §12 7단계, 반입 절차는 `docs/gem12-media-import-tutorial-2026-08-18.md`. 외장 SSD 사진 반입은 진행 중이다 — 삼동이 앨범(274개)으로 경로 검증 후, 나머지는 SSD 를 서버에 직결해 폴더별 앨범으로 전송한다.

### 1-3. 모니터링 — 남은 단계

Uptime Kuma + 호스트 점검 타이머는 가동 중이다 — 구성과 점검 항목은 §12 6단계. 남은 것:

- [ ] **Kuma 알림 채널 등록** — 웹 UI 설정 → 알림에서 채널(Telegram·메일 등)을 만들고 `gem12-health` 모니터에 연결한다. 채널이 없는 동안 down 은 대시보드에서만 보인다 (2026-08-18 Kuma DB 실측: notification 테이블 비어 있음). 관리자 계정(SQLite 내장 DB)·push 모니터(하트비트 300초, 재시도 2)·`KUMA_PUSH_URL` 기입은 완료 — push 도달 실측 통과

Prometheus + Grafana 는 필요해지면 추가한다. 그때 온도 메트릭은 node_exporter 의 hwmon 컬렉터가 그대로 노출하므로(`k10temp`=CPU, `amdgpu`=GPU, `nvme`) 별도 도구가 필요 없다.

### 1-4. 운영 정비

- [ ] **LAN IP 고정 임대** — 공유기에서 gem12(192.168.35.191)를 고정 임대로 묶는다. 재설치 때 IP가 바뀐 전례가 있다

자동 보안 업데이트는 가동 중이다 — §12 6단계.

### 1-5. 미결 판단

| 항목 | 결정 시점 |
|---|---|
| 블루레이 리핑 규모 → 미디어 스토리지 계획 | 리핑 시작 시 |
| ComfyUI 로컬 모델 도입 여부 — 2026-08-18 클라우드 전용(OpenRouter)으로 가동, 로컬 모델(백업 목록 65GB)은 보류 | 로컬 생성 필요가 생길 때 |
| 도메인 확보 여부 (서비스 주소용) | 외부 공개 시 |
| 차기 장비 보드 확정 — Taichi Lite(우선) vs Steel Legend(절약, §1-6) | 구매 시 |
| 차기 장비 케이스 — 최종 후보 Jonsbo N5 vs Lian Li V3000 Plus (§1-6) | 시스템 구축 시 재검토 |

### 1-6. 차기 장비 (2027) — 사양 방향

OCuLink eGPU 구조를 버리고 **일반 데스크톱 직결 + NAS 케이스**로 간다. 2026-08-18 결정.

| 부품 | 선택 | 근거 |
|---|---|---|
| CPU | Ryzen 9 7900 (무인자, 65W TDP) | 24시간 가동에 맞는 전력. Raphael iGPU의 VCN이 media 트랜스코딩을 이어받는다 |
| 메인보드 | ASRock X870E Taichi Lite (E-ATX, 우선) — 절약 대안 X870 Steel Legend WiFi | 아래 '보드 선정' 참조 — 기존 GPU가 3슬롯 두께라 슬롯 간격이 결정 변수다 |
| 네트워크 | 내장 Wi-Fi 7 | **주거공간 제약으로 유선 불가 — Wi-Fi 운영은 차기 장비에서도 유지된다.** NAT 브리지 구조(§7)도 그대로. 공유기가 Wi-Fi 7을 지원하면 현 AX200(Wi-Fi 6) 대비 대역폭 향상 여지 |
| GPU | 7900 XTX ×2 (기존 ASRock Phantom Gaming OC + 중고 1대 추가, 직결) | VRAM 48GB — Glimmer 전속 1대 + ComfyUI 전속 1대로 경합 해소. 카드당 x8 Gen4는 현 OCuLink(x4 Gen4)의 2배 |
| RAM | 64GB (DDR5 UDIMM 32GB×2, 신규 구매) | 실측 근거: 개발 파이프라인 풀가동 피크 11.2G, 추론은 VRAM 상주(llama-server 호스트 몫 5.5G). 96GB 이상은 통합 메모리 추론 시나리오에서만 필요한데 dGPU 2대 구성이므로 해당 없음. GEM12의 SO-DIMM은 규격이 달라 이식 불가 |
| SSD | GEM12의 NVMe 1TB 이식 | 아래 레인 배치 참조 |
| HDD | WD Red Plus 4TB × 1로 시작 | 단일 구성은 Drive 백업이 실재할 때 성립 — 2026-08-18 가동·복원 리허설 통과로 충족(§12 5단계). 4대 이상으로 늘면 §5 원칙대로 ZFS RAIDZ 전환 |
| PSU | 기존 eGPU용 1200W 재활용 | GPU 355W×2 + CPU 65W급 커버. PCIe 8핀 케이블 수(XTX당 2~3개, 총 5~6개) 확인 필요 |

**시세 (다나와, 2026-08-18 조회)**

| 부품 | 최저가 기준 | 가격 |
|---|---|---:|
| Ryzen 9 7900 멀티팩 | | 468,000원 |
| 메인보드 | X870E Taichi Lite 약 750,000 / 절약 대안 X870 Steel Legend WiFi 279,000 | 279,000~750,000원 |
| 7900 XTX 중고 1대 | 중고 시세 (신품은 XFX MERC 310 1,710,000원) | 900,000~1,000,000원 |
| DDR5 64GB (32GB×2) | Crucial PRO 5600 1,114,000 / TEAMGROUP 6000 CL38 1,205,000 | 1,110,000~1,210,000원 |
| WD Red Plus 4TB | WD40EFZZ 305,000 / WD40EFPX(256MB 캐시) 339,000 | 305,000~339,000원 |
| 케이스 | 최종 후보 N5 269,000 / V3000 Plus는 구축 시 시세 확인 | 269,000원~ |
| PSU / SSD | 재활용·이식 | 0원 |
| **합계** | Taichi Lite안 약 380~415만 / Steel Legend안 약 335~365만 | |

DRAM 가격 급등기라 **RAM이 보드보다 비싼 두 번째 지출 항목**이다. 64GB로 유지하는 결정이 비용 면에서도 옳다 — 96GB(48GB×2)로 올리면 이 항목만 60만 원 이상 늘어난다.

**보드 선정 — 요건은 넷이다.** ① 3슬롯 카드 2장이 물리적으로 들어갈 것, ② GPU당 현 OCuLink(x4 Gen4) 이상의 대역폭 — 지금 Glimmer가 x4 Gen4에서 풀가동 중이므로 이것이 검증된 하한선이다, ③ NAS 운용 적합(SATA·M.2 확장 여지), ④ 최신/최상 칩셋일 필요는 없음. 조사 결과(2026-08-18):

| 후보 | 다나와 | GPU 2장 물리 | GPU2 대역폭 | 평가 |
|---|---:|---|---|---|
| **ASRock X870E Taichi Lite** (E-ATX) | 약 750,000원 | **4슬롯 간격 — 3슬롯 카드 2장 자유** | x8 Gen4 (CPU 직결) | M.2 4개(Gen5 ×1 + Gen4 ×3)가 GPU 슬롯과 비공유라 전부 사용 가능. Wi-Fi 7. **우선 후보** |
| ASUS ProArt X870E-Creator | 751,000원 | 3슬롯 간격 — 실사용 보고: 3슬롯 카드가 아래 슬롯을 막음 | x8 Gen4 | M.2_2 장착 시 슬롯2가 x4로 강등(공식 스펙). 10GbE는 Wi-Fi 전용 환경에서 무의미. 탈락 |
| ASRock X870 Steel Legend WiFi (ATX) | 279,000원 | PCIE2가 보드 하단이라 간섭 없음 | x4 Gen4 (칩셋 경유) | OCuLink와 명목 동급이나 칩셋 업링크(Gen4 x4)를 저장장치·Wi-Fi와 공유. M.2_3 장착 시 PCIE2 비활성. **절약 대안** (약 47만 원 절감) |
| X670E 계열 (구세대 x8/x8) | Taichi Carrara 1,218,000원 | — | — | 단종 프리미엄으로 가격 역전. 탈락 |
| Threadripper/서버 플랫폼 | — | — | — | 유휴 전력이 24시간 가동 목표와 상충. 탈락 |

**Taichi Lite를 우선 후보로 둔다.** 가격이 ProArt와 동급인 이상 구조적 여유(간격 보장, CPU 직결 x8, M.2 비공유)를 포기할 이유가 없다. Steel Legend는 요건 하한을 정확히 충족하면서 47만 원을 아끼는 대안으로, 구매 시점에 확정한다(§1-5).

**Taichi Lite 저장장치 수용력 (공식 스펙 확인, 2026-08-18)**: SATA3 6포트 — HDD 6대까지 온보드로 수용하므로 §5의 "4대 이상 → ZFS RAIDZ" 시나리오까지 보드 교체가 필요 없다. 7대 이상은 남는 M.2에 ASM1166 어댑터(6포트)로 확장 — M.2가 GPU 슬롯과 비공유라 이 여지가 살아 있다. 실질 상한은 케이스 베이(후보 모두 12)와 PSU의 SATA 전원 커넥터 수다.

레인 배치 (Taichi Lite 기준):

```text
PCIE1 (CPU Gen5, x8)  ← 기존 Phantom Gaming OC (3슬롯, 330mm)
PCIE2 (CPU Gen5, x8)  ← 중고 추가 카드 — 4슬롯 간격이라 두께 제약 없음
M2_1 (CPU Gen5 x4)    ← 기존 1TB NVMe 이식
M2_2~M2_4 (칩셋 Gen4 x4) ← 향후 증설 자유 (GPU 레인과 비공유)
```

Steel Legend 선택 시: PCIE1(x16 Gen5) + PCIE2(x4 Gen4 하단), M.2_3만 비운다(PCIE2와 배타).

**케이스 후보** — 요건: E-ATX + 두꺼운 GPU 2장 + 3.5" 다중 베이 + **NAS 외형** (PC 타워 외형은 취향 탈락 — 사용자 결정 2026-08-18). 구매 전 실물 치수로 GPU 간섭을 확인한다. (가격: 다나와 2026-08-18)

| 후보 | 3.5" 베이 | 확장 슬롯 | 가격 | 비고 |
|---|---|---|---:|---|
| SilverStone CS383 | 8 (핫스왑 백플레인, SAS-12G/SATA-6G) | 8 | 493,210원 | NAS/워크스테이션 하이브리드 섀시. **GPU ≤340mm·폭 164mm 공식 명시** — 기존 카드(330×140mm) 적합 확정. SSI-EEB까지 지원, 멀티 GPU 구성 명시 지원, 보조 PSU 슬롯 옵션 |
| Jonsbo N5 (원안) | 12 (핫스왑) | 8 | 269,000원 | 우드+알루미늄 NAS 외형. GPU ≤350mm(전면 팬 구성). E-ATX ≤330mm. 듀얼 GPU 배기 검증 필요 |

탈락 기록: Phanteks Enthoo Pro 2 Server V2(272,160원)·Fractal Meshify 2 XL(352,000원)은 요건은 충족하나 PC 타워 외형이라 취향 탈락. Jonsbo N6(2026-02 출시)은 mATX 전용 + GPU ≤320mm라 보드·카드 모두 불가.

두 후보 모두 확장 슬롯 8개라 Taichi Lite의 4슬롯 간격 배치(GPU2가 5~7번 슬롯 점유)가 정확히 들어간다.

**케이스 최종 후보 2개 — Jonsbo N5 vs Lian Li V3000 Plus. 시스템 구축 시 재검토해 확정한다 (사용자 결정 2026-08-18).**

| | Jonsbo N5 (269,000원) | Lian Li V3000 Plus |
|---|---|---|
| 미학 | 우드+알루미늄 NAS 외형 | 알루미늄 디자인 풀타워 (128L 대형) |
| 3.5" 베이 | 12 (핫스왑 백플레인) | 8 (+2.5" 8, 총 드라이브 16) |
| GPU | ≤350mm, 슬롯 8 | ≤589mm, 슬롯 8 — 여유 최대 |
| 알려진 약점 | 소음(1mm 강판 + HDD 진동 증폭, 12드라이브 풀장착 45~47dBA), 고무 트레이, 육각 나사 | 부피·무게, 핫스왑 백플레인 아님 |

N5의 커뮤니티 실사용 근거: 상하 분리 챔버 덕에 GPU 온도는 실측 안정(RTX 4080 사례) — 실질 리스크는 배기가 아니라 소음이다. N5 선택 시 빌드 체크리스트:

- 백플레인 SATA는 **메인보드 장착 전에 전부 연결** (조립 후 접근 불가)
- SATA 케이블 60cm 이상, 안쪽 1~4번 베이는 90cm 고려
- 백플레인 전원이 Molex ×3 + SATA ×2 — **Molex 스플리터 준비**
- 핫스왑 인식은 BIOS AHCI hot plug 활성화 필요 (미설정 시 재부팅해야 인식)
- 기본 팬은 시끄러움 — 팬커브 조정 또는 교체(Noctua 등), 백플레인 팬 헤더는 속도 제어가 안 되므로 메인보드에 직결
- CPU 쿨러 높이 ≤16cm

두 후보 모두 이탈 시 예비: SilverStone CS383(NAS 외형, GPU 적합 공식 보장), be quiet! Dark Base Pro 901(3.5" 7개·정숙 지향 — N5의 소음 약점 보완). Fractal North XL은 우드 미학이 좋으나 3.5" 베이가 없어 NAS 부적합.

**중고 카드 선별 기준.** 기존 ASRock Phantom Gaming OC는 **330 × 140 × 57.6mm, 약 3슬롯 두께**다. Taichi Lite의 4슬롯 간격에서는 3슬롯 카드 2장이 간섭 없이 들어가므로 **중고 매물의 두께 제약이 사라진다** — 확인할 것은 길이(케이스 GPU 한계 이내)와 케이스 확장 슬롯 수(하단 카드가 슬롯 아래로 1~2단 내려가는 몫)뿐이다. Steel Legend(절약 대안)를 고르는 경우에도 PCIE2가 보드 하단이라 두께 제약은 동일하게 사라진다.

**이식 방식과 성공 기준의 충돌.** NVMe를 그대로 옮기면 §11의 재구축 검증을 건너뛰게 된다. 절충: 이식으로 빠르게 가동하되, HDD를 스크래치 삼아 부트스트랩 스크립트만으로 재구축 리허설을 1회 수행해 §11을 별도로 통과시킨다. 무선 어댑터가 AX200에서 보드 내장 Wi-Fi 7로 바뀌므로 인터페이스 이름 변경에 따른 네트워크 설정 갱신은 어차피 필요하다.

### 1-7. Obsidian vault·블로그 저장소 이관 (2026-08-18 조사 완료, 실행 대기)

cyprien_vault 와 funes_days_alter 를 Forgejo 원본 + GitHub push mirror 체제로 옮기고,
vault 에서 문학 원고를 별도 vault 로 분리한다.

**실측 (2026-08-18)**:

- vault 로컬 클론은 `~/Documents/personal/cyprien_vault` 하나뿐 (638MB, obsidian-git
  자동 커밋). alter 의 스크립트들이 참조하는 `~/Documents/obsidian/cyprien_vault` 경로는
  존재하지 않는다 — **이관하는 김에 스크립트 경로를 고쳐야 한다**. alter 로컬 클론은
  없어서 `~/Documents/personal/funes_days_alter` 로 새로 받았다 (2026-08-18)
- 발행 파이프라인 (`funes_days_alter/scripts/`): `publish_post.sh` 가 ① og 카드 생성
  ② vault 커밋·push ③ alter 빈 커밋 push(배포 트리거) ④ gh commit status 폴링.
  Vercel 빌드는 `sync_remote.sh` 가 **GitHub 의 cyprien_vault 를 gh 로 clone** 해
  `Efforts/On/funes_days_blog/` → `src/content/posts` 로 복사 후 Astro SSG
- **이관 호환성**: GitHub 이 미러로 남으면 Vercel(GitHub 연결·gh clone 경로) 은 변경 없이
  동작한다. 미러 지연 경합(vault 미러 반영 전에 alter 빌드 시작) 가능성은
  publish_post.sh 에 GitHub vault HEAD 확인 단계를 넣어 흡수한다

**작업 순서 (실행 시)**:

1. 문학 원고를 새 vault 로 분리 (대상 폴더는 사용자 지정) → Forgejo 신규 저장소
2. cyprien_vault: Forgejo 로 이관(이슈 없음, 저장소만) → GitHub push mirror 설정
   → 맥 클론 origin 을 Forgejo 로 재지정 (polydeukes 전례: 기존 GitHub 은 `github` 리모트)
3. funes_days_alter: 같은 방식 이관 + 미러 → Vercel 배포 1회 실측 (미러 경유 트리거 검증)
4. 스크립트 정비: sync_local/publish_post 의 vault 경로 정정, 미러 반영 대기 단계 추가
5. 발행 리허설: publish_post.sh dry-run → 실발행 1회로 전 구간 검증

**확정 (사용자 결정 2026-08-18)**: 새 vault 이름 **manuscript_vault** / 분리는 **스냅샷
새출발**(15년 이력은 cyprien_vault 에 그대로 남는다 — obsidian-git 자동 커밋 위주라 추적
가치 낮음) / **GitHub 미러도 건다** (Forgejo + restic + GitHub 3겹). 실행은 별도 회차 —
남은 유일한 입력은 **문학 원고가 든 폴더 지정**(실행 시 확인).

---

## 2. 가동 상태 (2026-08-18 실측)

서버에 접속해 확인한 값이다.

| 계층 | 구성 | 상태 |
|---|---|---|
| 호스트 | Fedora Server 44 (커널 6.19.10), btrfs 단일 파티션 | 29G / 929G 사용 |
| Tailscale | 1.102.2, 노드 `gem12` (100.73.205.75), 서브넷 라우트 10.10.10.0/24 승인 | 키 만료 해제 확인 |
| core (10.10.10.11) | Forgejo 16.0.2 (Podman Quadlet, SQLite, Git SSH 2222) + Uptime Kuma 2.5 (Quadlet, :3001) | 전부 active |
| ci (10.10.10.12) | Forgejo Runner v13.0.0 (`gem12-ci`) + Docker + **에이전트 루프** (`/opt/agents`, node 24·tea·flue) | 전부 active |
| apps (10.10.10.13) | n8n · NocoDB (Docker), Litestream 0.5.16, op CLI, Claude Code | 전부 가동 |
| ai (10.10.10.14) | llama.cpp Vulkan — `glimmer.service`(:8081)·`lightning.service`(:8082) GPU 교대 + `comfyui.service`(:8188, --cpu, OpenRouter 클라우드 전용) | 전부 정상 |
| media (10.10.10.15) | Immich v3(Quadlet ×3, :2283) + Jellyfin 10(Quadlet, :8096, VAAPI H264/HEVC) | 전부 active |
| 백업 (호스트) | `backup.timer` 매시(btrfs 스냅샷 + restic→Drive), `backup-prune.timer` 주 1회, Incus 스냅샷 매일 04:00 (7d) | 첫 백업 87.4 MiB, 복원 리허설 통과 |
| 모니터링·업데이트 (호스트) | `healthcheck.timer` 5분(점검 → Kuma push), `dnf5-automatic.timer` 매일 06:00 보안 업데이트 (호스트 + 컨테이너 5개) | 전부 active |

GitHub push mirror는 polydeukes 최신 커밋이 GitHub에 반영된 것으로 확인했다.

접속 규약:

```bash
ssh b95labs@gem12                              # 호스트 (gem12.tail4555a7.ts.net)
ssh root@10.10.10.13                           # 컨테이너 — 서브넷 라우트로 직접
https://gem12.tail4555a7.ts.net:3000           # Forgejo  (tailscale serve, tailnet 전용)
https://gem12.tail4555a7.ts.net:3001           # Uptime Kuma
https://gem12.tail4555a7.ts.net:5678           # n8n
https://gem12.tail4555a7.ts.net:8080           # NocoDB
https://gem12.tail4555a7.ts.net:2283           # Immich
https://gem12.tail4555a7.ts.net:8096           # Jellyfin
https://gem12.tail4555a7.ts.net:8188           # ComfyUI
```

에이전트 루프 투입 (경계 원칙 — 맥은 단발 신호만, 루프·도구 실행·추론은 전부 서버 안):

```bash
echo "<과제>" | ssh b95labs@gem12 "sudo /root/dotfiles/commands/incus/services/agent-loop/agent-run.sh run <id> <owner/repo> [glimmer|lightning]"
ssh b95labs@gem12 "sudo .../agent-run.sh status <id>"   # 조회 — 로그·종료 코드
```

---

## 3. 장비 실측

2026-08-17 측정값이다. 이 문서의 모든 용량 계산은 이 숫자에 근거한다.

| 항목 | 실측값 |
|---|---|
| CPU | AMD HawkPoint (8845HS 계열), 8코어 16스레드 |
| RAM | 32GB × 2 = 64GB (60GB 사용 가능), DIMM 슬롯 2개 모두 사용 중 |
| NVMe | 1TB × 1 (SHPP41-1000GM), btrfs, **수명 소모 1%** |
| 확장 슬롯 | 5개 중 4개 사용(J97 / J98 / J103 / J91), **`U93` 1개 비어 있음** |
| HDD | 없음 |
| iGPU | Radeon 780M (`c8:00.0`, IOMMU 그룹 23 단독) |
| dGPU | RX 7900 XTX (`03:00.0`, IOMMU 그룹 17 단독, OCuLink PCIe 4.0 x4) |
| 유선 NIC | 2.5GbE × 2 (`eno1`, `enp5s0`) — 랜선이 없어 사용하지 않음 |
| 무선 NIC | Intel Wi-Fi 6 AX200 (`wlp6s0`, `iwlwifi`) — **주 연결** |
| 디스크 사용량 | 29GB / 929GB (2026-08-18, 서버 전환 후) |

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

**빈 M.2 슬롯이 있다.** `dmidecode`가 보고한 빈 슬롯 `U93`가 이것이다. 2TB를 꽂으면 §4의 용량 압박이 사라지고 모델과 미디어를 별도 디스크로 분리할 수 있다. 다만 **당분간 하드웨어를 추가하지 않기로 했으므로 1TB 안에서 운영한다.**

**NVMe 수명 소모가 1%다.** 사실상 새 디스크이므로 그대로 재사용한다.

**RAM 증설은 교체를 뜻한다.** 슬롯 2개가 모두 차 있어 늘리려면 기존 32GB 두 장을 빼야 한다. 공식 최대가 128GB이므로 48GB나 64GB 두 장으로 바꿀 수 있다. §6의 컨테이너 할당 합계가 54GB라 지금은 필요하지 않다.

---

## 4. 디스크

### 데이터 원본 위치

어느 데이터의 원본이 어디에 있는지가 백업 등급(§8)을 결정한다.

| 데이터 | 원본 위치 | 복구 경로 |
|---|---|---|
| 코드 저장소 | Forgejo (core) | GitHub push mirror |
| SQLite DB (arxiv-candidates 등) | apps `/mnt/data/sqlite/` | Litestream → `/mnt/data/backup/litestream/` |
| LLM 모델 (GGUF) | ai `/mnt/data/models/` | HuggingFace 재다운로드 — `commands/incus/services/glimmer/download.sh` |
| Obsidian vault | GitHub | clone |
| 사진 · 블루레이 백업본 | **외장 SSD** | 서버의 Immich/Jellyfin 몫은 사본 |
| dotfiles | GitHub | clone (서버 사본: `/root/dotfiles`) |

### 용량 배분 (1TB 기준)

```text
Fedora Server 호스트 + 컨테이너 루트          ~120G
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

**백업 등급이 내려간다.** 서버의 사진·미디어는 이미 사본이므로 Google Drive 백업에서 제외한다 (§8 "백업하지 않음", 2026-08-18 확정). 외장 SSD 원본 + 서버 사본의 이중화가 방어선이고, 두 사본이 모두 집 안에 있는 잔여 위험은 수용한다. 그래서 **외장 SSD의 SMART 상태를 정기적으로 확인**한다 — `gem12-offline-copy` 실행에 내장돼 있다.

빈 M.2 슬롯이 하나 있으므로 나중에 2TB를 추가할 수 있다. 모델과 미디어를 옮기면 1TB는 시스템과 앱 데이터 전용이 되고 위 배분에서 230GB(모델 150G + ComfyUI 80G)가 빠진다. 다만 **당분간은 디스크를 추가하지 않고 1TB로 운영한다.**

---

## 5. 서비스 구성

### 무엇을 두는가

| 서비스 | 역할 |
|---|---|
| **Forgejo + Actions** | Git 저장소와 CI/CD. GitHub로 미러 복제. |
| **Tailscale** (호스트) | 개인 계정 tailnet 접속 + 컨테이너 대역(10.10.10.0/24) 서브넷 라우팅. 컨테이너가 아니라 호스트에 직접 설치한다. |
| **llama.cpp + Muse Glimmer 30B** | 로컬 LLM 추론. 7900 XTX 사용. |
| **ComfyUI** | 이미지·영상 작업. OpenRouter 클라우드 전용 — ByteDance Seedream 5.0(이미지)·Seedance 2.5/2.0(비디오)을 자작 노드로, 기타 모델은 커뮤니티 챗 노드로. 로컬 모델은 보류(§1-5). |
| **SQLite + Litestream** | 업무 기록, 지식저장소, 온톨로지의 저장 계층. 서비스별 파일 분리. |
| **n8n** | 자동화 워크플로. 외부 서비스 연동은 n8n 웹 UI에서 설정한다. |
| **NocoDB** | SQLite 위 그리드 UI. 사람이 후보를 보고 고르는 화면. |
| **Immich** | 개인 사진 보관. 최소 구성. |
| **Jellyfin** | 개인 블루레이 백업 재생. 최소 구성. |
| **Uptime Kuma** | 모니터링. 호스트 점검 타이머(`gem12-healthcheck`)의 push 를 받아 상태 이력과 알림을 맡는다. Prometheus / Grafana 는 필요해지면 추가. |

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

### 파일시스템 — btrfs를 쓴다

Fedora Server 설치 기본값은 LVM 위 xfs지만, 이 장비는 수동 파티셔닝으로 지정한 **btrfs 단일 파티션**으로 돌아간다. Incus의 btrfs 스토리지 드라이버가 컨테이너 스냅샷과 복제를 CoW로 처리하므로 궁합도 맞는다.

btrfs와 ZFS는 성격이 비슷하다. 모두 Copy-on-Write 방식이라 스냅샷이 순간이고 용량을 거의 쓰지 않으며, 체크섬으로 데이터 손상(bit rot)을 탐지하고, 전원이 나가도 `fsck` 없이 복구된다. 백업 1단계의 스냅샷은 어느 쪽에서든 똑같이 동작한다.

차이는 여러 디스크를 묶을 때 나온다. RAID 구성, 손상 자동 복구(체크섬이 틀리면 다른 디스크의 사본으로 고침), 풀 확장이 그것이다. **디스크가 1개면 이 이점이 전부 사라진다.** 체크섬이 손상을 탐지해도 고칠 사본이 없어 "이 파일이 망가졌다"고 알려주는 데서 끝난다.

남는 차이는 세 가지이고, 모두 btrfs 쪽이 유리하다.

- **ZFS는 RAM을 많이 쓴다.** ARC 캐시가 기본적으로 RAM 절반을 가져간다. 이 시스템은 60GB 중 54GB를 컨테이너에 할당하므로 ARC를 강제로 제한해야 하는데, 굳이 제약을 만들 이유가 없다.
- **ZFS는 커널 모듈을 다시 컴파일해야 한다.** CDDL과 GPL이 충돌해 ZFS는 커널에 포함될 수 없고, DKMS가 설치 시점에 소스를 컴파일해 모듈을 만든다. 커널을 올릴 때마다 이 과정이 반복되며, 새 커널의 내부 API에 OpenZFS가 아직 대응하지 않았으면 컴파일이 실패한다. 루트 파일시스템이 ZFS면 부팅 자체가 막힌다. Fedora는 커널을 빠르게 올리는 배포판이라 이 위험이 다른 어디보다 크다. btrfs는 커널 메인라인에 있어 이 문제가 아예 없다.
- **btrfs는 Fedora가 몇 년째 기본값으로 쓰는 구성이다.**

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

한 장비에서 두 파일시스템을 함께 써도 된다. Incus는 스토리지 풀을 여러 개 등록하는 것이 정상적인 운영 방식이므로, NVMe는 btrfs로 두고 HDD 풀만 ZFS로 구성하면 된다. 다만 Fedora에서 ZFS는 OpenZFS 저장소를 따로 추가해야 한다.

**확장을 대비해 지금 해둘 일이 있다.** btrfs를 ZFS로 변환하는 방법은 없으므로, 확장 시점에는 데이터를 옮겼다가 되돌려야 한다. 이 작업을 줄이려면 **서비스 데이터를 마운트 지점으로 추상화한다.** 컨테이너가 `/mnt/data/immich` 같은 경로만 알고 그 아래가 어떤 파일시스템인지 모르게 해두면, 스토리지를 바꿀 때 마운트만 옮기면 된다. compose 파일에 호스트 경로를 직접 적어두면 이 작업이 훨씬 번거로워진다.

---

## 6. 가상화 — Incus 시스템 컨테이너

Fedora Server를 베어메탈에 설치하고, 서비스는 **Incus 시스템 컨테이너**로 나눈다.

### Fedora Server + Incus를 쓰는 근거

- **이미 아는 운영체제다.** 관리 지식(dnf, systemd, SELinux, firewalld)이 Fedora에 쌓여 있다. Server 에디션은 같은 체계에서 데스크톱만 뺀 구성이다.
- **Incus가 필요한 것을 전부 다룬다.** 컨테이너 생성, 자원 제한, NAT 네트워크, GPU 장치 연결, 스냅샷을 CLI 하나로 관리한다. 이 계획의 가상화 요구사항이 그것의 전부다.
- **Incus는 Fedora 공식 저장소에 있다.** `dnf install incus`로 깔리고 배포판 업데이트와 함께 관리된다.

### 시스템 컨테이너를 택한 이유

**첫째, GPU 문제다.** RDNA3(7900 XTX)는 vendor-reset을 지원하지 않아 VM 패스스루 후 재시작 시 GPU가 복구되지 않는 사례가 알려져 있다. 시스템 컨테이너는 호스트 커널의 `amdgpu` 드라이버를 공유하고 `/dev/dri` 노드만 넘겨받으므로 이 문제를 구조적으로 회피한다.

**둘째, llama.cpp가 Vulkan 백엔드를 쓴다.** ROCm이었다면 `/opt/rocm` 전체 스택과 커널 모듈 버전 맞추기 때문에 컨테이너 이미지가 수십 GB로 커지지만, Vulkan은 호스트 `amdgpu` + `/dev/dri/renderD*` + Mesa RADV만 있으면 된다. Incus의 gpu 장치 한 줄이면 된다.

**셋째, 60GB RAM 제약이다.** VM 5개는 게스트 커널과 메모리 예약이 각각 필요해 60GB로는 여유가 없지만, 시스템 컨테이너는 커널을 공유해 오버헤드가 훨씬 작다.

### 구성도

```text
GEM12 / Fedora Server (베어메탈) + Incus
│
├── core          2 vCPU / 6GB    Fedora + Podman
│   ├── Forgejo              ← Git 저장소, GitHub 미러 복제
│   └── Uptime Kuma          ← 모니터링 (호스트 점검 push 수신 + 알림)
│
├── ci            6 vCPU / 8GB    Fedora + Docker
│   ├── Forgejo Runner
│   └── Docker / BuildKit / 빌드 캐시
│
├── apps          4 vCPU / 8GB    Fedora + Docker
│   ├── n8n / NocoDB
│   ├── 업무기록 / 지식저장소 / 온톨로지 백엔드
│   ├── SQLite (서비스별 파일 분리)
│   └── Litestream → 로컬 경로 (rclone이 Drive로 올림, §8 참조)
│
├── ai            6 vCPU / 24GB   Fedora + Podman  ← /dev/dri (7900 XTX)
│   ├── llama.cpp (Muse Glimmer 30B + DFlash drafter / Lightning 교대)
│   └── ComfyUI (--cpu, OpenRouter 클라우드 전용 — Seedream·Seedance)
│
└── media         4 vCPU / 8GB    Fedora + Podman  ← /dev/dri (780M)
    ├── Immich
    └── Jellyfin
```

RAM 합계 54GB로 60GB 안에 들어간다. 컨테이너는 미사용 메모리를 호스트에 반납하므로 실제 여유는 더 크다.

### 운영체제 — 호스트와 컨테이너 모두 Fedora, 데스크톱 환경 없음

모든 컨테이너에 **Incus 공식 이미지 서버의 Fedora**(`images:fedora/44`)를 쓴다. 호스트와 배포판을 통일하면 패키지 관리(dnf), systemd 관례, 보안 업데이트 주기를 한 벌만 알면 된다. Fedora는 릴리스 주기가 짧지만 호스트가 이미 Fedora이므로 어차피 따라가야 하는 주기이고, 컨테이너는 업그레이드 전에 스냅샷을 찍어두면 되돌리기도 쉽다.

**데스크톱 환경은 어디에도 설치하지 않는다.** Wayland나 X11 컴포지터가 없으면 패키지가 줄고 공격 표면도 작아진다. 접근 경로는 세 가지다.

```text
맥북 → Tailscale VPN ─┬→ Cockpit 웹 UI    (Fedora Server 기본 포함, 웹 터미널 내장)
                      ├→ 각 서비스 웹 UI  (Forgejo, n8n, NocoDB, Immich, ComfyUI …)
                      └→ SSH              (호스트와 컨테이너 직접 접속)
```

Cockpit에 웹 터미널이 들어 있어 SSH가 막혀도 브라우저에서 호스트 셸에 들어갈 수 있고, 거기서 `incus exec <이름> bash`로 컨테이너 셸에 들어간다. 데스크톱 환경이 필요 없는 이유다.

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
| Tailscale 노드 등록 | 브라우저 로그인 (개인 계정) |
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
| CI의 E2E 테스트 | ci 컨테이너 | Playwright 공식 이미지(`mcr.microsoft.com/playwright`)를 쓰면 의존성이 모두 들어 있다 |
| 서버에서 SSH로 Claude Code 실행 | ci 컨테이너 또는 apps 컨테이너 | `npx playwright install --with-deps chromium`으로 headless Chromium을 설치한다 |
| n8n 워크플로의 스크래핑 | apps 컨테이너 | 위와 같다 |

평소 작업은 맥북에서 하므로 첫 줄이 기본이다. 나머지는 필요해질 때 해당 컨테이너에 추가한다.

RDNA3 Vulkan은 최신 Mesa가 유리한데, Fedora는 Mesa를 빠르게 올리는 배포판이라 이 걱정이 없다. 컨테이너를 Fedora로 통일한 실익이 ai 컨테이너에서 가장 크다. 단, media 컨테이너의 VAAPI 코덱(H.264/HEVC)은 특허 문제로 Fedora 기본 Mesa에서 빠져 있으므로 RPM Fusion의 `mesa-va-drivers-freeworld`로 바꿔야 한다 — `04-runtime.sh`가 처리하며, 현재 보류 상태는 §1-2 참조.

### 컨테이너 런타임 — 컨테이너별로 나눈다

Docker와 Podman 중 하나로 통일하지 않는다. **용도가 갈려 있고 그 분업이 합리적이다.** 업무 프로젝트는 Docker(`docker-compose.yml` 다수), GPU 작업은 Podman으로 운영해온 이력이 있다. Podman은 Fedora가 만든 도구라 컨테이너 안에서도 저장소 추가 없이 깔린다.

| 컨테이너 | 런타임 | 근거 |
|---|---|---|
| core | **Podman** | 데몬이 없어 systemd가 컨테이너를 직접 관리한다. Git 저장소는 다른 서비스를 복구할 때의 기반이므로, 이 계층은 데몬 하나에 운명을 묶지 않는다 |
| ci | **Docker** | Forgejo Actions Runner가 Docker 소켓을 전제한다. BuildKit도 Docker 쪽이 성숙하다 |
| apps | **Docker** | 기존 compose 파일을 그대로 쓴다. n8n 공식 문서도 Docker 기준이다 |
| ai | **Podman** | ComfyUI를 Podman으로 운영해온 이력이 있다. rootless로 `/dev/dri`를 넘기는 방식이 깔끔하다 |
| media | **Podman** | 780M VAAPI 접근이 같은 이유로 유리하다 |

core에서 Podman을 쓰는 이유를 더 적어둔다. Docker는 `dockerd`가 모든 컨테이너의 부모여서 데몬이 죽으면 그 아래가 전부 죽고, systemd 입장에서는 개별 컨테이너가 보이지 않는다. Podman은 각 컨테이너가 독립 프로세스라 Quadlet(`.container` 파일)로 정의하면 **systemd가 일반 서비스처럼 다룬다.** 부팅 순서, 의존성, 재시작 정책이 전부 systemd 표준 방식으로 관리된다.

CI는 CPU를 순간적으로 많이 쓰므로 다른 서비스와 분리하고, Runner에 CPU와 메모리 상한을 설정한다.

### GPU 배분

두 GPU가 서로 다른 IOMMU 그룹에 단독으로 있어, 각각 다른 컨테이너에 할당한다.

```text
IOMMU 17 → 03:00.0  RX 7900 XTX  → ai     (LLM 추론 + ComfyUI)
IOMMU 23 → c8:00.0  Radeon 780M  → media  (VAAPI 트랜스코딩)
```

서버 전환으로 데스크톱 렌더링 몫이 사라져 VRAM에 여유가 있다. Muse Glimmer는 24560MiB 중 19171MiB를 점유한다(2026-08-18 실측). ComfyUI 는 클라우드 전용 `--cpu` 로 돌아 VRAM 을 아예 쓰지 않는다(§12 7단계) — 남는 약 5GB 는 로컬 노드를 도입하는 경우의 몫으로 남아 있다(§1-5 보류). Glimmer 설정은 128k 컨텍스트 그대로 둔다(학습된 상한이 131072라 더 늘려도 실익이 없다).

---

## 7. 네트워크

### VPN — 개인 Tailscale 계정, 회사 tailnet과 완전 분리

서버는 **개인 Tailscale 계정의 tailnet**에 등록되어 있다 (2026-08-18, 노드명 `gem12`, 100.73.205.75, MagicDNS `gem12.tail4555a7.ts.net`). 회사 tailnet에는 절대 등록하지 않는다 — 개인 tailnet은 노드 목록과 ACL을 개인이 통제하고, 회사 계정이 회수돼도 개인 인프라 접근이 유지된다.

```text
GEM12 (서버)
  └── tailscaled — 개인 tailnet 노드 + 10.10.10.0/24 서브넷 라우터

MacBook Pro / 휴대 기기 (클라이언트)
  ├── 프로파일 A: 회사 tailnet  (업무용)
  └── 프로파일 B: 개인 tailnet  (이 서버용)
        tailscale switch 로 전환
```

Tailscale 클라이언트는 여러 프로파일을 저장하고 `tailscale switch`로 오갈 수 있다. 동시 접속은 안 되지만, 서버가 개인 tailnet에만 있으므로 문제되지 않는다.

### 호스트 설치 절차 (2026-08-18 실측 검증)

재구축 시 그대로 따라한다.

```bash
sudo dnf config-manager addrepo --from-repofile=https://pkgs.tailscale.com/stable/fedora/tailscale.repo
sudo dnf install tailscale
sudo systemctl enable --now tailscaled

# 서브넷 라우팅에 필요한 IP 포워딩
sudo tee /etc/sysctl.d/99-tailscale.conf >/dev/null <<'EOF'
net.ipv4.ip_forward = 1
net.ipv6.conf.all.forwarding = 1
EOF
sudo sysctl -p /etc/sysctl.d/99-tailscale.conf

# 출력되는 URL을 브라우저에서 열어 개인 계정으로 인증한다
sudo tailscale up --advertise-routes=10.10.10.0/24

# 포워딩 허용 — tailscale0 에는 테일넷 인증을 통과한 트래픽만 흐른다.
# 존 미지정 인터페이스는 기본 존(FedoraServer)에 떨어져 포워딩이 거부된다.
sudo firewall-cmd --permanent --zone=trusted --add-interface=tailscale0
sudo firewall-cmd --reload
```

관리 콘솔(login.tailscale.com/admin/machines)에서 두 가지를 설정한다. 현재 서버에는 둘 다 적용되어 있다 (키 만료 해제는 2026-08-18 실측 확인).

1. `gem12`의 서브넷 라우트 `10.10.10.0/24` **승인** — 광고만으로는 라우팅되지 않는다
2. **Disable key expiry** — 서버 노드는 키가 만료되면 재인증 전까지 tailnet에서 떨어진다

이후 어느 네트워크에서든 MagicDNS 이름으로 접속한다.

```bash
ssh b95labs@gem12          # 호스트 (전체 도메인: gem12.tail4555a7.ts.net)
ssh root@10.10.10.13       # 컨테이너 — 서브넷 라우트로 직접 닿는다
```

### 웹 콘솔 — tailscale serve 포트 노출

웹 UI가 있는 서비스는 `tailscale serve --https=<컨테이너 포트>`로 `https://gem12.tail4555a7.ts.net:<포트>`에 노출한다 (tailnet 전용, 인증서 자동). 포트는 컨테이너 내부 포트를 그대로 쓴다 — Forgejo :3000, n8n :5678, NocoDB :8080. Tailscale Services(`svc:`)는 베타 후 과금이 미정이라 쓰지 않기로 결정했다.

### 물리 연결 — Wi-Fi로 운영한다

랜선이 부족하므로 **Wi-Fi(Intel AX200, `wlp6s0`)를 주 연결로 쓴다.** AX200은 `iwlwifi` 메인라인 드라이버를 쓰고, Fedora Server는 `NetworkManager-wifi`·`wpa_supplicant`·AX200 펌웨어(`linux-firmware`)를 기본 포함하므로 추가 설치 없이 동작한다.

**무선에서는 일반적인 브리지가 동작하지 않는다.** 802.11 규격상 무선 클라이언트는 자기 MAC 주소로만 프레임을 보낼 수 있어, 컨테이너의 다른 MAC이 붙은 프레임을 공유기가 버린다. 그래서 컨테이너가 공유기에서 각자 IP를 받는 물리 브리지 대신 **NAT 브리지**를 쓴다. Incus가 기본으로 만드는 구조가 정확히 이것이다 — `incusbr0`의 DHCP/DNS(dnsmasq)와 마스커레이딩을 Incus가 직접 관리한다.

```text
wlp6s0 (공유기 DHCP, 192.168.35.191)
   │ 마스커레이딩 (Incus 관리)
   ▼
incusbr0  10.10.10.1/24  (내부 전용, 물리 포트 없음)
   ├── core    10.10.10.11
   ├── ci      10.10.10.12
   ├── apps    10.10.10.13
   ├── ai      10.10.10.14
   └── media   10.10.10.15
```

모든 접근이 Tailscale VPN을 거치는 설계이므로 컨테이너가 LAN IP를 각자 가질 이유가 없다. 격리 면에서는 이쪽이 낫다.

대역폭은 5GHz Wi-Fi 6 기준 실효 300~600Mbps로, Git push나 사진 업로드에는 충분하다. 대용량 미디어를 처음 넣을 때만 USB로 직접 옮긴다.

랜선이 생기면 `eno1`을 연결해 `wlp6s0`를 대체한다. Incus의 마스커레이딩은 호스트 라우팅을 따라가므로 NAT 브리지 쪽은 바꿀 것이 없다.

### 장애 대비

VPN 컨트롤 플레인은 Tailscale 호스팅 서비스에 있으므로 서버 장애와 무관하게 살아 있다. 다만 서버 자체가 죽으면 원격으로 들어갈 곳이 없으니, 대비책은 **모니터와 키보드를 직접 연결하는 것**이다. 집에 있는 장비이므로 이것으로 충분하다.

Wi-Fi가 끊기면 원격 복구가 불가능하지만, 이는 유선이어도 서버 자체가 죽으면 마찬가지다. 외출 중 장애는 복구를 포기하고 귀가 후 처리한다. 혼자 쓰는 시스템에서 이 정도 가용성이면 충분하고, 외부 VPS를 두는 비용과 의존이 더 크다.

LAN 안에서는 키 인증 전용 SSH를 열어두되 비밀번호 로그인은 차단한다.

### 공개 범위

모든 접근은 Tailscale VPN을 거친다.

| 대상 | 접근 경로 |
|---|---|
| Cockpit / SSH / Forgejo / n8n / NocoDB / Immich / Jellyfin / ComfyUI / llama.cpp / 모니터링 | VPN 전용 |

외부에 공개할 서비스가 생기면 그때 리버스 프록시와 도메인을 설정한다. **주소는 IP가 아니라 도메인으로 구성**해서, 장비를 옮길 때 DNS만 바꾸면 되게 한다.

---

## 8. 백업 — 이 시스템의 유일한 방어선

디스크가 1개라 RAID가 없다. btrfs 체크섬이 손상을 탐지해도 고칠 사본이 없으므로, **서버에만 있는 데이터는 디스크가 죽으면 전부 잃는다.** 3단계 백업은 선택이 아니다. 가동 현황과 남은 단계는 §1-1에 있다.

다만 모든 데이터가 같은 등급은 아니다. 사진과 미디어는 외장 SSD에 원본이 있고 모델 가중치는 재다운로드할 수 있으므로, **서버가 유일한 사본인 것**을 먼저 지킨다.

### 1단계 — 로컬 스냅샷 (실수 복구)

디스크 고장은 막지 못하지만 실수 삭제와 잘못된 업데이트 되돌리기에 쓴다. 두 갈래로 돈다 (`commands/incus/services/backup/`).

- **호스트 데이터**: `backup.timer` 가 매시 루트 서브볼륨을 읽기전용 스냅샷으로 뜬다 (`/.snapshots/auto-<ts>`, 24시간 유지 — 더 긴 이력은 2단계 restic 이 맡는다). `/mnt/data` 는 루트 서브볼륨 위의 일반 디렉토리라 함께 잡힌다.
- **컨테이너 루트fs**: Incus 풀이 별도 서브볼륨이라 위 스냅샷에 안 잡힌다. Incus 내장 스케줄로 매일 04:00 스냅샷, 7일 보존 (`profile default` 의 `snapshots.schedule`/`snapshots.expiry`).

### 2단계 — Google Drive (재해 복구)

개인 Google Drive 약 5TB. **전체 디스크가 아니라 필수 요소만** 올린다. 도구는 **restic(rclone 백엔드)** 로 확정 — 암호화·중복제거·버전 이력·무결성 검사(`restic check`)를 restic 이 맡고, Drive 전송만 rclone 이 한다. 평문 DB나 시크릿이 그대로 올라가지 않는다.

매시 `backup.timer` 가 1단계 스냅샷에서 restic 백업을 뜬다 — SQLite(WAL)가 가동 중이어도 스냅샷 시점으로 crash-consistent 하다. 실행은 **호스트**에서 한다: 스냅샷 권한과 전 컨테이너 데이터(`/mnt/data/*`)는 호스트에만 있다. 보존은 시간 24 · 일 7 · 주 8, 실데이터 회수(prune)와 검사는 주 1회 `backup-prune.timer`.

**반드시 백업** — 서버가 유일한 사본이다

- **Forgejo 데이터 디렉토리 전체** — 설정 DB(Issue, PR, Actions 설정, 사용자·조직 설정, 웹훅), **미러 없는 Forgejo 태생 저장소**(gem12-agents, model-arena), **모든 위키 repo**(`<repo>.wiki.git` — push mirror 는 위키를 옮기지 않는다)
- SQLite DB (업무기록 / 지식저장소 / 온톨로지)
- n8n 워크플로와 자격증명
- 각 서비스 설정과 compose 파일 (Forgejo에도 있지만 이중화)

Forgejo 는 선별하지 않고 디렉토리 통째로 싣는다 (2026-08-18 결정) — 현재 전체가 57MB 라 GitHub 미러가 있는 저장소를 걸러내는 로직의 위험이 절감 효과보다 크다. 용량이 문제될 때 미러 있는 저장소의 git 내용만 선별 제외로 전환한다.

**백업하지 않음** — 다른 곳에 원본이 있거나 재생성할 수 있다

- **Immich 사진 라이브러리 · Jellyfin 미디어** — 원본이 외장 SSD 다. 용량(사진 55G + 영화 126G)이 Drive 백업에 맞지 않아 제외한다 (사용자 결정 2026-08-18, backup.sh 의 exclude). 서버 사본 + SSD 원본의 이중화로 방어하되, 두 사본이 모두 집 안에 있어 화재·도난에는 함께 사라진다 — 이 잔여 위험은 수용한다. **Immich 의 postgres(앨범 구조·메타데이터)는 소용량이라 Drive 백업에 남는다**

- LLM / ComfyUI 모델 가중치. 재다운로드할 수 있다. **다만 목록과 다운로드 스크립트는 Git에 남긴다.** 이것이 실질적인 백업이다.
- Jellyfin 미디어. 원본이 외장 SSD에 있다.
- CI 캐시, Docker 레이어
- Jellyfin 메타데이터, 트랜스코딩 임시파일
- Immich 썸네일

### Litestream은 Google Drive에 직접 쓸 수 없다

Litestream이 지원하는 대상은 S3 API 계열(S3, GCS, Azure Blob, SFTP)이고 **Google Drive는 여기에 없다.** WAL 프레임을 초 단위로 증분 업로드하며 세대를 관리하려면 객체 스토리지의 조건부 쓰기가 필요한데, 파일 동기화용인 Drive API는 이를 제공하지 않는다.

`rclone mount`로 Drive를 파일시스템처럼 붙이는 우회는 **쓰지 않는다.** 네트워크 마운트 위에서 SQLite 잠금이 깨지면 DB가 손상된다. 백업하려다 원본을 망가뜨리는 구조다.

대신 두 단계로 나눈다.

```text
SQLite (apps 컨테이너)
   │ Litestream — 초 단위 증분 복제
   ▼
서버 내 별도 경로 (/mnt/data/backup/litestream)
   │ restic — 매시, 암호화·중복제거 (rclone 백엔드)
   ▼
Google Drive
```

Litestream은 로컬 경로(`file://`)로 복제하고, 매시 restic 백업이 그 결과를 Drive에 올린다. Drive 반영이 시간 단위로 늦어지지만 개인 업무 기록에서 그 정도 손실은 감당할 수 있고 비용이 들지 않는다.

실시간 오프사이트 복제가 필요해지면 Cloudflare R2 같은 S3 호환 서비스를 붙인다. 월 1~2달러 수준이고 Litestream이 직접 쓸 수 있다. **서버 안에 MinIO를 띄우는 방식은 의미가 없다** — 복제본이 원본과 같은 디스크에 남아 재해 복구가 되지 않는다.

### 3단계 — 오프라인 사본

외장 SSD(SanDisk Extreme 1TB, exFAT)에 핵심 데이터의 비암호화 tar 를 둔다. 계정 잠김이나 클라우드 접근 불가에 대비하며, 집 안 보관 매체라 즉시 읽기를 암호화보다 우선한다 (사용자 결정 2026-08-18). 분기 1회, SSD 를 서버에 연결한 김에 실행한다.

```bash
sudo mount -o rw /dev/sdX1 /mnt/ssd
sudo gem12-offline-copy     # commands/incus/services/backup/offline-copy.sh
```

매시 btrfs 스냅샷의 최신본에서 restic 과 같은 제외 규칙으로 tar 를 떠 `gem12-offline/` 에 최신 2개를 보존하고, SSD 의 SMART 확인(USB 브리지라 `-d sat` 필요 — 실측)까지 겸한다.

이 SSD 는 사진·영화의 **원본** 보관도 겸한다 — 서버 사본과 함께 미디어의 이중화를 이루는 매체가 같은 물건이다.

### 서버 밖에 둘 것

서버가 죽었을 때 필요한 정보는 서버 안에 두지 않는다.

- Google 계정 복구 정보
- 백업 암호화 키
- 서버 root 비밀번호

1Password에 넣되, **1Password 자체 복구 키는 종이로 오프라인 보관**한다.

---

## 9. Git 전략 — Forgejo + GitHub 미러

Forgejo가 주 저장소이고, GitHub에 미러로 복제한다. push mirror는 가동 중이며 polydeukes에서 refs 일치를 검증했다 (8시간 주기 + sync_on_commit, PAT는 `op://Personal/GITHUB_MIRROR_PAT`).

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

**미러가 옮기는 것은 Git 저장소뿐이다.** Issue, PR, Actions 설정, 사용자와 조직 설정, 웹훅은 GitHub로 넘어가지 않는다. 그래서 §8에서 저장소 내용은 백업 대상에서 빼고 **Forgejo 설정 DB만** 백업한다.

인프라 재구축에 필요한 설정은 가능한 한 Forgejo에 저장한다. 다만 시크릿은 Git에 넣지 않는다.

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

---

## 12. 구축 이력 — 완료 단계와 검증 결과

구축 순서의 완료분이다. 각 단계는 검증 조건을 통과한 시점에 닫혔다.

### 0단계 — 포맷 전 준비 (2026-08-17)

- 모든 코드 저장소의 원격 push 상태 확인, 로컬 전용 데이터 대피
- 모델 파일 manifest 저장 (`models-manifest.txt`) — 재다운로드 스크립트의 근거
- dotfiles 커밋·push
- 자격증명 선발급: `claude setup-token` 장기 토큰, 맥북 SSH 공개키 (1Password 보관)

**검증 통과**: 장비를 잃어도 잃는 것이 없는 상태.

### 1단계 — Fedora Server 설치 (2026-08-18)

첫 설치(08-17)는 Anaconda 자동 파티셔닝이 LVM+xfs(루트 16GB)로 잡혀 재설치했고, 두 번째는 수동 파티셔닝으로 **btrfs 단일 파티션 997GB**를 지정해 정상. Wi-Fi는 Anaconda 네트워크 화면에서 연결해 첫 부팅부터 인터넷이 붙었다. 콘솔 절차는 `gem12-first-wifi-tutorial-2026-08-17.md` 참조. 블루투스 키보드는 설치에 쓸 수 없다(UEFI·Anaconda는 USB HID만 인식) — 유선 키보드로 진행했다.

**검증 통과**: 재부팅 후 Wi-Fi 자동 연결, LAN SSH, Cockpit 접근. 호스트 전체 업데이트(372건) + 재부팅 자동 복귀.

### 1.5단계 — 저장소와 도구 (2026-08-18)

- dotfiles: `/root/dotfiles`에 HTTPS로 clone. 갱신은 서버에서 `git pull`. `stow` 전체 배포는 하지 않는다 — 서버에 필요한 것은 `commands/incus/` 스크립트뿐이고 셸 환경은 `02-host.sh`가 배포한다
- 부트스트랩 01~04 스크립트 전체 통과, 컨테이너 5개 생성 (core/ci/apps/ai/media, Incus btrfs 풀)
- 1Password CLI 2.39.0: 호스트 + apps. apps는 `op account add` 등록 완료
- Claude Code 2.1.224: apps에서 검증. 토큰은 `/root/.bashrc.local`에서 `op read`로 주입 — `~/.claude/.credentials.json` 복사 방식은 기기 간 세션 무효화 위험이 있어 쓰지 않는다
- 일상 접속 사용자 `b95labs` (wheel + incus-admin), root는 키 인증만

**검증 통과**: 서버에서 `claude -p "1+1"` 응답.

### Tailscale (2026-08-18)

§7의 절차대로 설치·인증. 서브넷 라우트 승인, 키 만료 해제. 맥 → 컨테이너 5개 SSH 전 구간 검증 통과.

### 2단계 — core 컨테이너 (2026-08-18)

Forgejo 16.0.2: Podman Quadlet(`commands/incus/services/forgejo/`), SQLite, Git SSH 2222, 가입 차단. 관리자 `b95labs` (dfg1499@gmail.com — 개인 이메일). polydeukes를 GitHub에서 이관(이슈·PR 58건)하고 push mirror를 걸어 refs 일치를 검증했다. 맥북 polydeukes의 origin은 Forgejo, 기존 GitHub은 `github` 리모트.

**검증 통과**: 맥북에서 Tailscale 경유 push, 회사 tailnet 프로파일 전환 후에도 회사 서버 정상 접속.

### 3단계 — ai 컨테이너 (2026-08-18)

`glimmer.service`: llama.cpp Vulkan 빌드(`/opt/llama.cpp`), 모델 `/mnt/data/models`. 스크립트는 `commands/incus/services/glimmer/{build,download,deploy}.sh`. 컨테이너 재시작 시 자동 기동 검증.

**검증 통과**: 맥북 pi에서 `--provider muse-glimmer-gem12`로 접속. VRAM 19171/24560 MiB, 생성 29.0 tok/s(자유 서술) ~ 43.2 tok/s(정형 출력), DFlash 채택률 13.6~24.4%.

### 4단계 — ci + apps 컨테이너 (2026-08-18, rclone 제외)

- Forgejo Actions 활성화(quadlet `FORGEJO__actions__ENABLED`), Runner v13.0.0을 ci에 설치·등록 (`gem12-ci`, systemd `forgejo-runner.service`, 라벨 ubuntu-latest/node-24/docker). gem12-agents에 타입체크 CI 부착, arxiv_youtube에 PR 자동 리뷰 워크플로 부착
- n8n: apps Docker, `:5678`. 저장소 `/mnt/data/arxiv` 마운트. 공식 이미지에 Node v24 포함이라 Execute Command로 스크립트 직접 실행 가능. tailscale serve 뒤라 `N8N_SECURE_COOKIE=false` 필수
- NocoDB: apps Docker(단일 컨테이너 + SQLite 메타), `:8080`. base `arxiv`에 외부 SQLite(arxiv-candidates.db) 연결 — candidate·video_order 그리드 노출. 어드민 비밀번호는 `op://Personal/GEM12_NOCODB`
- Litestream 0.5.16: RPM 설치, `/etc/litestream.yml`, `file://` 복제 → `/mnt/data/backup/litestream/`. 대상 DB는 WAL 모드 + **`busy_timeout=5000` 필수** (미설정 시 동시 쓰기 97% 실패 실측). 복원 검증 완료
- rclone → Drive는 §1-1로 이어진다

**검증 통과**: 저장소 push 시 Actions 자동 실행, GitHub 미러 커밋 반영, Litestream 로컬 복제·복원.

### 5단계 — 백업 파이프라인 + 재현성 회수 (2026-08-18)

- 백업: `commands/incus/services/backup/` — 매시 `backup.timer` 가 btrfs 루트 스냅샷(24시간 유지) 후 스냅샷에서 restic 백업(rclone `gdrive` 백엔드, ai·ci 제외), 주 1회 `backup-prune.timer` 가 prune + `check --read-data-subset=5%`. Incus 컨테이너 스냅샷은 내장 스케줄(매일 04:00, 7d). 시크릿은 `op://Personal/GEM12_RCLONE_DRIVE_TOKEN` · `GEM12_RESTIC_PASSWORD` → 호스트 600 파일
- 구축 중 실측 함정 2건: **/root 아래 스크립트는 SELinux(admin_home_t)가 systemd 실행을 거부** → `/usr/local/sbin/gem12-backup` 으로 설치. **systemd 서비스에 HOME 이 없어** restic 캐시·rclone 설정 탐색 실패 → 유닛에 `Environment=HOME=/root`
- 재현성 회수(§10 원칙 2): litestream.yml, n8n·NocoDB `docker run` 인자(비밀번호는 `/etc/nocodb.env` 로 분리), 러너 유닛·등록 절차, tailscale serve 규약을 `commands/incus/services/{litestream,n8n,nocodb,forgejo-runner,tailscale-serve}/` 로 고정. 전부 멱등 재실행 검증

**검증 통과**: 맥에서 **Drive 사본과 1Password 시크릿만으로**(서버 무접촉) restic 복원 87.4 MiB — gitea.db `integrity_check` ok, 미러 없는 저장소(model-arena) clone 후 HEAD 일치, litestream 복제본에서 DB 재구성 ok.

### 6단계 — 모니터링 + 자동 보안 업데이트 (2026-08-18)

media(§1-2)보다 먼저 올렸다 — 이미 돌고 있는 서비스와 백업의 감시가 우선이다. Prometheus 없이 **Uptime Kuma push 모니터(dead-man switch) 방식**으로 §1-3 알림 목록을 덮는 결정 — 점검 스크립트가 5분마다 결과를 신고하고, 신고가 끊기는 것 자체도 down 으로 잡힌다.

- Uptime Kuma 2.5: core 에 Quadlet(`commands/incus/services/uptime-kuma/`), `:3001` + tailscale serve 등록. 데이터는 `/mnt/data/uptime-kuma`(호스트 `/mnt/data/core/` 아래)라 매시 restic 백업에 자동 포함
- 호스트 점검 타이머: `commands/incus/services/healthcheck/` — 5분마다 `/usr/local/sbin/gem12-healthcheck` 실행. 점검 항목: 디스크 >85% · RAM >90% · `btrfs device stats --check`(고칠 사본이 없으므로 오류가 나오면 해당 파일을 백업에서 되살리고 디스크 교체를 검토한다) · `smartctl -H` · 온도(k10temp Tctl >95°C, amdgpu junction >105°C·mem >100°C, nvme Composite >70°C) · 기본 라우트(Wi-Fi 단절) · 컨테이너 5개 RUNNING 전수 · Forgejo healthz · llm 추론 계층(glimmer :8081 과 lightning :8082 는 GPU 를 두고 교대 운용되므로 **둘 중 하나** 응답이면 정상 — glimmer 단독 점검은 lightning 가동 중 오탐, 실측) · n8n · NocoDB health · forgejo-runner(ci) · litestream(apps) · `backup.service` Result 와 `backup.timer`(rclone→Drive 중단 감지) · GitHub 미러 push(전 저장소 push mirror 의 `last_error` 를 Forgejo API 로 조회). 실패 시 실패한 점검 이름 목록과 함께 down 을 push 한다 — 모니터는 하나지만 알림 본문(msg)에서 어느 컨테이너·서비스가 문제인지 바로 보인다
- 시크릿: `/etc/gem12-healthcheck.env`(600) 에 `KUMA_PUSH_URL`(분실 시 Kuma 모니터 화면에서 재확인)과 `FORGEJO_TOKEN`(read:repository — deploy.sh 가 Forgejo CLI 로 발급·기입, 분실 시 재발급). 둘 다 재발급 가능해 1Password 에 두지 않는다
- 온도 센서는 hwmon 인덱스가 아니라 **칩 이름 + 라벨로 매칭** — amdgpu 가 2개(XTX·780M)인데 junction/mem 라벨은 XTX 만 내주므로 라벨이 dGPU 를 고른다
- 자동 보안 업데이트: `commands/incus/services/dnf-automatic/` — 호스트 + 컨테이너 5개에 `dnf5-plugin-automatic` 설치, `/etc/dnf/automatic.conf` 에 `upgrade_type=security`·`apply_updates=yes`, `dnf5-automatic.timer`(매일 06:00 + 무작위 60분). Fedora 44 는 dnf5 라 패키지·타이머 이름이 dnf5-* 다
- 실측 함정: 루프 안 `incus exec` 가 stdin 을 삼켜 컨테이너 목록 순회가 첫 항목에서 끊긴다 — `</dev/null` 필수

**검증 통과**: 6곳 모두 `dnf5-automatic.timer` enabled·active + 설정 md5 일치. 첫 healthcheck 전 항목 통과. Kuma `:3001` HTTP 응답. UI 초기 설정(내장 SQLite 선택 — Litestream 은 물리지 않는다: 모니터링 이력은 시간 단위 손실 허용이고 매시 restic 백업에 이미 포함) 후 push 도달 실측 통과, `gem12-health` 모니터 Up.

### 7단계 — media 컨테이너 + ComfyUI (2026-08-18)

**Immich** (media, Quadlet 4개 — `commands/incus/services/immich/`): server v3 + PostgreSQL(VectorChord, 공식 조합 태그) + Valkey 9, 사용자 정의 네트워크로 이름 DNS. ML 컨테이너는 미배포(최소 구성, 사용자 결정) — 웹 설정에서 ML 비활성화 필요(§1-2). DB 비밀번호 `op://Personal/GEM12_IMMICH_DB` → `/etc/immich.env`.

**Jellyfin** (media, Quadlet — `services/jellyfin/`): 보류됐던 mesa-va-drivers-freeworld 가 26.1.6 리빌드 등장으로 해소 — deploy.sh 의 멱등 전제 단계가 설치하고 `vainfo` 의 H264/HEVC 프로파일 등장을 게이트로 삼는다(통과 실측). 실측 함정: Quadlet `AddDevice` 는 디렉토리(/dev/dri)로 주면 "no devices found" — **개별 노드**(card0·renderD129)로 적어야 한다.

**ComfyUI** (ai, native systemd — `services/comfyui/`): v0.33.2 고정, python3.13 venv(ai 기본 3.14 는 torch 생태계 cp314 휠 공백), CPU torch, `--cpu` 로 VRAM 경합 봉쇄(배포 전후 VRAM 불변 실측). 클라우드는 OpenRouter 단일 키(`LLM_KEY`) —

- **ByteDance 최신 라인업은 전용 엔드포인트에 있다** (챗 완성 `/models` 목록에는 없음, 사용자 정정으로 발견): 이미지 `POST /api/v1/images` 에 seedream-5-0-pro/lite(2026-08 출시), 비디오 `POST /api/v1/videos`(잡 제출→폴링→다운로드) 에 seedance-2.5/2.0 계열
- 자작 노드 2개(`services/comfyui/openrouter-media/` → custom_nodes)로 연결 — Seedream Image·Seedance Video. 실측 반영: seedream 5.0 은 해상도 2K/4K 만 수용, `unsigned_urls` 는 이름과 달리 Bearer 인증 필요
- 커뮤니티 챗 노드(gabe-init/ComfyUI-Openrouter_node, 커밋 고정)는 gemini/gpt 이미지 계열용으로 병행
- **비용 실측**: seedream-5.0-lite 2K 이미지 $0.035, seedance-2.5 4초 720p **$0.92** — 비디오는 초 단위 과금이 크므로 시험은 seedance-2.0-mini 로

**검증 통과**: Immich ping·3컨테이너 가동 + 웹 초기 설정(관리자·ML off) 후 **외장 SSD 사진 274개(1.9GB)를 immich-cli 로 앨범 업로드, 사용자 확인** — 반입 규약은 폴더당 앨범 1개, `._*`(exFAT 의 macOS AppleDouble) 제외, API 키 최소 권한은 asset 업로드·읽기 + album 전부 + **user.read**(CLI 접속 확인용, 실측). Jellyfin /health·VAAPI 프로파일 + 웹 마법사 완료(VAAPI `renderD129`, Nfo·아트워크 파일 저장 켬 — 재구축 원칙, 트릭플레이·챕터 추출 끔 — 파생물 생성 배제). ComfyUI 클라우드 이미지 생성 성공(gemini 1장 + seedream 2K 1장 실측). healthcheck 3항목 추가 후 OK·`DOWN: jellyfin` 회귀 실측, deploy 2회차 멱등. Seedance 비디오 노드의 실과금 검증은 사용자가 필요할 때 웹 UI 에서.

---

## Changelog

- **2026-08-18 (백업 3단계 가동 + 미디어 백업 교리 확정)** — §1-1 의 3단계(오프라인 사본)를 `gem12-offline-copy` 스크립트로 가동: 매시 스냅샷 최신본에서 핵심 데이터 tar(183MB) → 외장 SSD, **비암호화**(사용자 결정 — 계획의 "암호화 SSD" 문구 폐기), SMART 확인 내장(PASSED). 미디어 백업 교리 확정: Immich 사진 라이브러리·Jellyfin 미디어는 용량(55G+126G) 때문에 Drive 백업에서 제외(backup.sh exclude), 이중화는 외장 SSD 원본 + 서버 사본이 맡는다 — "여유가 되면 백업" 등급 폐지. Immich postgres 는 백업 유지. 외장 SSD 사진·영화 대량 반입 진행(폴더별 앨범, systemd 일회 유닛).
- **2026-08-18 (구축 5단계 완료 — media + ComfyUI, §12 7단계)** — Immich(ML 제외 Quadlet 구성)·Jellyfin(freeworld 26.1.6 리빌드 등장으로 보류 해소, VAAPI H264/HEVC 실측)·ComfyUI(python3.13 venv + CPU torch, OpenRouter 클라우드 전용) 가동. 사용자 정정으로 OpenRouter 전용 이미지/비디오 엔드포인트에서 ByteDance 2026-08 라인업(seedream-5.0, seedance-2.5)을 발견해 자작 노드 2개로 연결 — 기존 키 하나로 최신 모델 전부 커버. healthcheck·tailscale serve 에 3개 서비스 편입, 미디어 반입 튜토리얼 작성(외장 SSD exFAT 실측). 교훈: 유료 생성 API 검증을 승인 없이 반복해 비용을 태웠다 — 이후 유료 호출 검증은 비용 제시·승인 후 최저가 1회로 제한한다.
- **2026-08-18 (점검 범위 확장 — 컨테이너 전수 + 미러 push 감시)** — gem12-healthcheck 에 컨테이너 5개 RUNNING 전수, llm(glimmer/lightning 교대 — 둘 중 하나), n8n·NocoDB·forgejo-runner, GitHub 미러 push `last_error`(Forgejo API, 토큰은 deploy.sh 가 CLI 발급) 점검을 추가해 §1-3 의 "미러 push 실패 감시" 잔여 항목 해소. 첫 실행이 glimmer 정지를 잡았는데 lightning 교대 운용에 의한 정상 상태로 판명 — 단독 점검을 "둘 중 하나"로 정정(오탐 실측). 남은 것: Kuma 알림 채널 등록(DB 실측으로 미등록 확인).
- **2026-08-18 (모니터링 + 자동 보안 업데이트 가동)** — §1-3·§1-4 의 두 항목 수행(§12 6단계): Uptime Kuma(core Quadlet, :3001) + 호스트 점검 타이머(`gem12-healthcheck` 5분, §1-3 목록을 Kuma push 로 전달), `dnf5-plugin-automatic` 을 호스트+컨테이너 5개에 보안 업데이트 자동 적용으로 활성화. Prometheus 없이 push 모니터 방식으로 목록을 덮는 결정. 남은 것: Kuma UI 초기 설정(계정·알림 채널·push URL 기입), GitHub 미러 push 감시(Forgejo API 토큰 필요), LAN 고정 임대.
- **2026-08-18 (백업 파이프라인 가동)** — §1-1 의 1·2단계 완성(§12 5단계): 매시 btrfs 스냅샷 + restic→Drive, 복원 리허설 통과가 완료 판정. 계획 문구와 실측이 갈린 지점 반영 — rclone 은 apps 컨테이너가 아니라 **호스트에서** 돌린다(호스트에 이미 설치돼 있었고 스냅샷 권한·전 컨테이너 데이터 접근이 호스트에만 있음), 도구는 rclone crypt 대신 **restic(rclone 백엔드)** 채택, Forgejo 는 미러 유무 선별 없이 **디렉토리 전체 백업**(57MB, 용량 문제 시 선별 전환). §1-4 재현성 정비를 겸사 완료(사용자 요청): litestream·n8n·NocoDB·러너·tailscale serve 를 스크립트로 고정. 남은 것: 3단계 오프라인 SSD, rclone 개인 client_id(공용 client_id 2026년 중 퇴역 예고).
- **2026-08-18 (에이전트 루프 서버 이주)** — 그간 수동 flue 실행(구현 에이전트·수동 리뷰)이 맥북에서 돌고 서버는 추론만 맡던 구조를 발견·해체. 동기는 실측: 맥→서버 장시간 스트리밍(무선 2구간+Tailscale)이 하루 4회 "Connection error"로 죽는 동안 서버 안 CI 리뷰는 무사고였고, 도구 실행(git·npm·tsc)이 맥 CPU를 써서 서버 리소스가 놀았음(사용자 관찰). 원칙 확정: **경계는 단발 신호(투입·관찰)만 건너고, 개발 과정 전체는 서버 안에서**. ci 컨테이너에 `commands/incus/services/agent-loop/` 규약(setup.sh·agent-run.sh·env.example) 신설 — systemd 일회 유닛이 루프를 소유해 SSH 절단과 무관. 스모크 통과(45초 완주). Fedora 44의 기본 nodejs 22 함정(nodejs24-npm으로 지정) 기록.
- **2026-08-18 (백업 교리 개정)** — "Forgejo 저장소는 GitHub 미러가 사본이라 백업 제외" 규칙에 예외 편입: 미러 없는 Forgejo 태생 저장소(gem12-agents·model-arena)와 모든 위키 repo는 서버가 유일 사본이므로 "반드시 백업" 등급으로. polydeukes 계획 문서의 위키 이관 구상(gitignore 로컬 폴더 폐지 → 비공개 위키 + cognee 인덱스 + Drive 백업) 검토 중 발견.
- **2026-08-18 (케이스 최종 후보 확정)** — 케이스 요건에 NAS 외형(사용자 취향) 추가. 디자인 업체 조사(Lian Li·Fractal·be quiet!·InWin·HYTE·Streacom·SilverStone) 결과 요건 충족 모델은 소수 — **최종 후보를 Jonsbo N5와 Lian Li V3000 Plus 2개로 좁히고 시스템 구축 시 재검토**하기로 결정. N5 커뮤니티 후기(소음이 실질 리스크, GPU 배기는 실측 안정)와 빌드 체크리스트 수록. Enthoo Pro 2·Meshify 2 XL은 PC 타워 외형으로 취향 탈락, Jonsbo N6는 mATX 전용으로 불가. 미니 서버 랙(10인치)은 본체 수용 불가 — 주변장치용 하이브리드 구성만 가능함을 확인.
- **2026-08-18 (차기 장비 보드 재선정)** — 기존 GPU(Phantom Gaming OC, 3슬롯)가 ProArt X870E의 3슬롯 간격에서 아래 슬롯을 막는 실사용 보고를 확인, 보드 요건을 재정의(3슬롯 카드 2장 + GPU당 OCuLink 이상 + NAS 적합)하고 5개 경로 비교 후 **ASRock X870E Taichi Lite(4슬롯 간격, M.2 비공유)를 우선, X870 Steel Legend WiFi를 절약 대안**으로 확정. 주거 제약으로 Wi-Fi 운영이 차기 장비에서도 유지됨을 명시(유선 전환 서술 제거). 중고 카드 두께 제약 소멸.
- **2026-08-18 (차기 장비)** — §1-6 신설: OCuLink 대신 데스크톱 직결 + NAS 케이스 방향 확정 (7900 + ProArt X870E-Creator + 7900 XTX ×2 + 64GB + WD 4TB). ASUS 공식 스펙으로 M.2_2 ↔ PCIEX16_2 대역폭 공유 확인, 기존 Phantom Gaming OC 실측 치수(330mm·3슬롯)로 슬롯 배치 결정, 다나와 시세(합계 약 390~410만 원) 기록. 케이스 우선 후보 Enthoo Pro 2 Server V2.
- **2026-08-18 (문서 재구성)** — 남은 작업을 §1 상단으로, 완료된 구축 단계를 §12로 이동. 서버 접속 실측을 반영: 컨테이너 5개·전 서비스 가동 확인, Tailscale 키 만료 해제 확인(미결에서 제거), 로컬 스냅샷 자동화·rclone·dnf-automatic 미비 확인(남은 작업에 추가). 디스크 사용량 621G(데스크톱 시절) → 29G(서버 전환 후), VRAM 21734 → 19171 MiB, 생성 속도 29~68 → 29.0~43.2 tok/s로 실측 갱신. "데스크톱 완전 이관 가능 여부" 미결은 포맷 완료로 해소되어 제거. 웹 콘솔 포트 노출 규약(tailscale serve)과 NocoDB를 본문에 추가.
- **2026-08-18** — Fedora Server 44 재설치(btrfs 997GB), 부트스트랩 01~04, Tailscale, Forgejo + polydeukes 마이그레이션, Glimmer, Forgejo Runner, n8n, NocoDB, Litestream 가동 (§12).
- **2026-08-17** — 초안 작성. 장비 실측, 디스크 예산, 서비스 구성, 백업 설계.
