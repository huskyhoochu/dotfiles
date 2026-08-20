# GEM12 구축 이력

> 완료된 구축 단계와 그때의 검증 결과다. 현재 구성은 [operations.md](operations.md),
> 남은 작업은 [README.md](README.md) 에 있다.
>
> 절 안의 `§N` 참조는 **작성 시점의 계획 문서 번호**다. 지금 구조로는
> operations.md 의 해당 주제를 보면 된다.

## 12. 구축 이력 — 완료 단계와 검증 결과

구축 순서의 완료분이다. 각 단계는 검증 조건을 통과한 시점에 닫혔다.

### 0단계 — 포맷 전 준비 (2026-08-17)

- 모든 코드 저장소의 원격 push 상태 확인, 로컬 전용 데이터 대피
- 모델 파일 manifest 저장 (`models-manifest.txt`) — 재다운로드 스크립트의 근거
- dotfiles 커밋·push
- 자격증명 선발급: `claude setup-token` 장기 토큰, 맥북 SSH 공개키 (1Password 보관)

**검증 통과**: 장비를 잃어도 잃는 것이 없는 상태.

### 1단계 — Fedora Server 설치 (2026-08-18)

첫 설치(08-17)는 Anaconda 자동 파티셔닝이 LVM+xfs(루트 16GB)로 잡혀 재설치했고, 두 번째는 수동 파티셔닝으로 **btrfs 단일 파티션 997GB**를 지정해 정상. Wi-Fi는 Anaconda 네트워크 화면에서 연결해 첫 부팅부터 인터넷이 붙었다. 콘솔 절차는 [first-boot-wifi.md](first-boot-wifi.md) 참조. 블루투스 키보드는 설치에 쓸 수 없다(UEFI·Anaconda는 USB HID만 인식) — 유선 키보드로 진행했다.

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
- rclone → Drive는 5단계로 이어진다

**검증 통과**: 저장소 push 시 Actions 자동 실행, GitHub 미러 커밋 반영, Litestream 로컬 복제·복원.

### 5단계 — 백업 파이프라인 + 재현성 회수 (2026-08-18)

- 백업: `commands/incus/services/backup/` — 매시 `backup.timer` 가 btrfs 루트 스냅샷(24시간 유지) 후 스냅샷에서 restic 백업(rclone `gdrive` 백엔드, ai·ci 제외), 주 1회 `backup-prune.timer` 가 prune + `check --read-data-subset=5%`. Incus 컨테이너 스냅샷은 내장 스케줄(매일 04:00, 7d). 시크릿은 `op://Personal/GEM12_RCLONE_DRIVE_TOKEN` · `GEM12_RESTIC_PASSWORD` → 호스트 600 파일
- 구축 중 실측 함정 2건: **/root 아래 스크립트는 SELinux(admin_home_t)가 systemd 실행을 거부** → `/usr/local/sbin/gem12-backup` 으로 설치. **systemd 서비스에 HOME 이 없어** restic 캐시·rclone 설정 탐색 실패 → 유닛에 `Environment=HOME=/root`
- 재현성 회수(§10 원칙 2): litestream.yml, n8n·NocoDB `docker run` 인자(비밀번호는 `/etc/nocodb.env` 로 분리), 러너 유닛·등록 절차, tailscale serve 규약을 `commands/incus/services/{litestream,n8n,nocodb,forgejo-runner,tailscale-serve}/` 로 고정. 전부 멱등 재실행 검증

**검증 통과**: 맥에서 **Drive 사본과 1Password 시크릿만으로**(서버 무접촉) restic 복원 87.4 MiB — gitea.db `integrity_check` ok, 미러 없는 저장소(model-arena) clone 후 HEAD 일치, litestream 복제본에서 DB 재구성 ok.

### 6단계 — 모니터링 + 자동 보안 업데이트 (2026-08-18)

media(7단계)보다 먼저 올렸다 — 이미 돌고 있는 서비스와 백업의 감시가 우선이다. Prometheus 없이 **Uptime Kuma push 모니터(dead-man switch) 방식**으로 §1-3 알림 목록을 덮는 결정 — 점검 스크립트가 5분마다 결과를 신고하고, 신고가 끊기는 것 자체도 down 으로 잡힌다.

- Uptime Kuma 2.5: core 에 Quadlet(`commands/incus/services/uptime-kuma/`), `:3001` + tailscale serve 등록. 데이터는 `/mnt/data/uptime-kuma`(호스트 `/mnt/data/core/` 아래)라 매시 restic 백업에 자동 포함
- 호스트 점검 타이머: `commands/incus/services/healthcheck/` — 5분마다 `/usr/local/sbin/gem12-healthcheck` 실행. 점검 항목: 디스크 >85% · RAM >90% · `btrfs device stats --check`(고칠 사본이 없으므로 오류가 나오면 해당 파일을 백업에서 되살리고 디스크 교체를 검토한다) · `smartctl -H` · 온도(k10temp Tctl >95°C, amdgpu junction >105°C·mem >100°C, nvme Composite >70°C) · 기본 라우트(Wi-Fi 단절) · 컨테이너 5개 RUNNING 전수 · Forgejo healthz · llm 추론 계층(glimmer :8081 과 lightning :8082 는 GPU 를 두고 교대 운용되므로 **둘 중 하나** 응답이면 정상 — glimmer 단독 점검은 lightning 가동 중 오탐, 실측) · n8n · NocoDB health · forgejo-runner(ci) · litestream(apps) · `backup.service` Result 와 `backup.timer`(rclone→Drive 중단 감지) · GitHub 미러 push(전 저장소 push mirror 의 `last_error` 를 Forgejo API 로 조회). 실패 시 실패한 점검 이름 목록과 함께 down 을 push 한다
- **모니터 7개로 분리 (2026-08-20)**: 점검을 `host`(디스크·RAM·btrfs·SMART·온도·기본 라우트) · `backup`(backup.service Result·timer·미러 push) · `core` · `apps` · `ci` · `ai` · `media`(각 컨테이너 RUNNING + 그 안의 서비스) 로 나눠 그룹마다 `KUMA_PUSH_URL_<그룹>` 에 신고한다. 매 실행에서 **7개 전부** 보낸다 — 실패한 그룹만 보내면 나머지가 하트비트를 잃어 오탐이 되기 때문이다. URL 이 없는 그룹은 journal 기록만 하고 넘어가므로 모니터를 만들기 전에도 배포·검증이 된다
- 나눈 근거는 실측이다: 단일 모니터 + 집계 status 에서는 **이미 down 인 상태에 새 장애가 겹쳐도 status 가 그대로라 Kuma 가 상태 변화로 보지 않는다.** 08-19 17:13 의 restic 락으로 down 인 동안 dGPU 가 죽었는데 이력에 흔적이 없었다(12:12~12:35 공백). 가동률 12.81%. **먼저 난 장애가 뒤에 난 장애를 가린다**
- 실측 함정: 그룹 배열을 `GROUPS` 로 두면 안 된다 — bash 특수 변수(현재 사용자의 GID 배열)라 대입해도 셸이 덮어쓴다. 첫 배포에서 그룹 대신 root 의 GID 3개(1000 985 10)를 돌았다. `CHECK_GROUPS` 로 쓴다
- 시크릿: `/etc/gem12-healthcheck.env`(600) 에 `KUMA_PUSH_URL_<그룹>` 7개(분실 시 Kuma 모니터 화면에서 재확인)와 `FORGEJO_TOKEN`(read:repository — deploy.sh 가 Forgejo CLI 로 발급·기입, 분실 시 재발급). 둘 다 재발급 가능해 1Password 에 두지 않는다. deploy.sh 는 기존 env 를 덮지 않고 없는 변수만 빈 값으로 덧붙인다
- 온도 센서는 hwmon 인덱스가 아니라 **칩 이름 + 라벨로 매칭** — amdgpu 가 2개(XTX·780M)인데 junction/mem 라벨은 XTX 만 내주므로 라벨이 dGPU 를 고른다
- 자동 보안 업데이트: `commands/incus/services/dnf-automatic/` — 호스트 + 컨테이너 5개에 `dnf5-plugin-automatic` 설치, `/etc/dnf/automatic.conf` 에 `upgrade_type=security`·`apply_updates=yes`, `dnf5-automatic.timer`(매일 06:00 + 무작위 60분). Fedora 44 는 dnf5 라 패키지·타이머 이름이 dnf5-* 다
- 실측 함정: 루프 안 `incus exec` 가 stdin 을 삼켜 컨테이너 목록 순회가 첫 항목에서 끊긴다 — `</dev/null` 필수

**검증 통과**: 6곳 모두 `dnf5-automatic.timer` enabled·active + 설정 md5 일치. 첫 healthcheck 전 항목 통과. Kuma `:3001` HTTP 응답. UI 초기 설정(내장 SQLite 선택 — Litestream 은 물리지 않는다: 모니터링 이력은 시간 단위 손실 허용이고 매시 restic 백업에 이미 포함) 후 push 도달 실측 통과.

**분리 검증 통과 (2026-08-20)**: 7개 push URL 모두 HTTP 200. 격리 실측 — `ai` 그룹에 실패를 주입하니 `ai=down (comfyui)` 이고 나머지 6개는 `up` 을 유지했다. 기존 구조에서는 불가능했던 동작이다.

### 7단계 — media 컨테이너 + ComfyUI (2026-08-18)

**Immich** (media, Quadlet 4개 — `commands/incus/services/immich/`): server v3 + PostgreSQL(VectorChord, 공식 조합 태그) + Valkey 9, 사용자 정의 네트워크로 이름 DNS. ML 컨테이너는 미배포(최소 구성, 사용자 결정) — 웹 초기 설정에서 ML 비활성화까지 완료. DB 비밀번호 `op://Personal/GEM12_IMMICH_DB` → `/etc/immich.env`.

**Jellyfin** (media, Quadlet — `services/jellyfin/`): 보류됐던 mesa-va-drivers-freeworld 가 26.1.6 리빌드 등장으로 해소 — deploy.sh 의 멱등 전제 단계가 설치하고 `vainfo` 의 H264/HEVC 프로파일 등장을 게이트로 삼는다(통과 실측). 실측 함정: Quadlet `AddDevice` 는 디렉토리(/dev/dri)로 주면 "no devices found" — **개별 노드**(card0·renderD129)로 적어야 한다.

**ComfyUI** (ai, native systemd — `services/comfyui/`): v0.33.2 고정, python3.13 venv(ai 기본 3.14 는 torch 생태계 cp314 휠 공백), CPU torch, `--cpu` 로 VRAM 경합 봉쇄(배포 전후 VRAM 불변 실측). 클라우드는 OpenRouter 단일 키(`LLM_KEY`) —

- **ByteDance 최신 라인업은 전용 엔드포인트에 있다** (챗 완성 `/models` 목록에는 없음, 사용자 정정으로 발견): 이미지 `POST /api/v1/images` 에 seedream-5-0-pro/lite(2026-08 출시), 비디오 `POST /api/v1/videos`(잡 제출→폴링→다운로드) 에 seedance-2.5/2.0 계열
- 자작 노드 2개(`services/comfyui/openrouter-media/` → custom_nodes)로 연결 — Seedream Image·Seedance Video. 실측 반영: seedream 5.0 은 해상도 2K/4K 만 수용, `unsigned_urls` 는 이름과 달리 Bearer 인증 필요
- 커뮤니티 챗 노드(gabe-init/ComfyUI-Openrouter_node, 커밋 고정)는 gemini/gpt 이미지 계열용으로 병행
- **비용 실측**: seedream-5.0-lite 2K 이미지 $0.035, seedance-2.5 4초 720p **$0.92** — 비디오는 초 단위 과금이 크므로 시험은 seedance-2.0-mini 로

**AI 캐릭터 파이프라인 (2026-08-19)**: 캐릭터 시트(t2i) → 영상(t2v) 경로 확립. ByteDance API 는 실사 인물 이미지 입력을 딥페이크 방지 필터로 차단한다(reference·first_frame 공통 실측, AI 생성 얼굴도 "실사성 기준" 오탐) — 해소는 **Seedance 2.5 의 URL 전용 참조**: Cloudflare R2 공개 버킷 `gem12-refs`(시크릿 `op://Personal/CLOUDFLARE_*`)에 `R2ImageURL` 노드가 참조를 올려 URL 로 전달, **실사 시트 반영 영상 생성 실증**. 워크플로 4종: t2i-character-sheet / t2v-character(반실사, 앵커 키프레임) / t2v-seedance / t2v-photoreal(실사, R2 참조). 비디오 노드 콤보에 Kling 3.0(초당 $0.084~)·Wan 2.7 병행 — 같은 OpenRouter `/videos` 엔드포인트라 모델 전환은 드롭다운이다. 실측 함정: 손으로 쓴 워크플로 JSON 의 링크 슬롯이 프런트엔드 직렬화 순서(IMAGE 옵션 입력 우선)와 어긋나면 로드 시 링크가 소리 없이 버려진다.

**검증 통과**: Immich ping·3컨테이너 가동 + 웹 초기 설정(관리자·ML off) 후 **외장 SSD 사진 274개(1.9GB)를 immich-cli 로 앨범 업로드, 사용자 확인** — 이후 나머지 사진도 전량 반입 완료(2026-08-20) — 반입 규약은 폴더당 앨범 1개, `._*`(exFAT 의 macOS AppleDouble) 제외, API 키 최소 권한은 asset 업로드·읽기 + album 전부 + **user.read**(CLI 접속 확인용, 실측). Jellyfin /health·VAAPI 프로파일 + 웹 마법사 완료(VAAPI `renderD129`, Nfo·아트워크 파일 저장 켬 — 재구축 원칙, 트릭플레이·챕터 추출 끔 — 파생물 생성 배제). ComfyUI 클라우드 이미지 생성 성공(gemini 1장 + seedream 2K 1장 실측). healthcheck 3항목 추가 후 OK·`DOWN: jellyfin` 회귀 실측, deploy 2회차 멱등. Seedance 비디오 노드의 실과금 검증은 사용자가 필요할 때 웹 UI 에서.

### vault·블로그 저장소 이관 (2026-08-19)

cyprien_vault 와 funes_days_alter 를 Forgejo 원본 + GitHub push mirror 체제로 옮기고,
vault 에서 활성 작업을 별도 vault 로 분리했다.

**실행 결과 (2026-08-19)**: 세 저장소가 Forgejo 원본이 됐다 — `b95labs/cyprien_vault`
(327M), `b95labs/funes_days_alter`, `b95labs/b95labs_vault`(신규). 로컬 origin 은 전부
Forgejo 이고 기존 GitHub 은 `github` 리모트다(polydeukes 전례). push mirror 3건 등록
완료. 남은 것은 **GITHUB_MIRROR_PAT 의 저장소 범위 확장**(fine-grained PAT 이라
polydeukes 에만 허용돼 미러 push 가 403) — 웹 UI 작업이라 사람 몫이다. 절차와 이후
순서는 [vault-migration-2026-08-19.md](vault-migration-2026-08-19.md) 에 있다.

**분리 방향이 뒤집혔다.** 애초 계획은 문학 원고를 새 vault 로 빼는 것이었으나,
원고·메모·첨부가 vault 의 대부분(Atlas 39M + `_attachments` 181M)이고 15년 이력의
주인공이다. 그것을 옮기면 활성 blog vault 가 죽은 이력 384M 를 끌고 다니게 된다.
**이력은 내용과 함께 있어야 한다** — 그래서 cyprien_vault 를 아카이브로 제자리에 두고,
활성 작업(Efforts 의 사업·개발 항목 + 블로그 원고)만 `b95labs_vault`(29M)로 스냅샷
분리했다. 이름은 개인사업자 상호를 따랐다 — 블로그는 프로젝트 중의 하나일 뿐이다.

**새 vault 는 ACE 를 버렸다.** `projects/` + `journal/` 둘로 시작하고 필요해질 때 늘린다.
루트 `CLAUDE.md` 를 사람·AI 계약으로 두어 AI 쓰기 화이트리스트, provenance
frontmatter(`author`/`model`/`reviewed`), 최소 스키마(`type`/`status`/`date`)를 고정했다.
근거는 2026년 AI 협업 PKM 관행 조사 — Karpathy LLM Wiki 패턴, Google OKF(2026-06),
Reitz 의 CLAUDE.md 계약. 소형 vault 에 임베딩·벡터 DB 를 두지 않는 것도 같은 조사의
결론이다("인프라 구축 = 미루기" 안티패턴).

**발행 파이프라인에 미러 가드를 넣었다.** vault 의 origin 이 Forgejo 가 되면서 GitHub 은
비동기 미러가 됐고, Vercel 빌드는 GitHub 미러를 clone 한다. 미러 반영 전에 배포가
시작되면 옛 원고가 나가는데 **빌드는 성공한다** — 실패가 아니라 오배포라 더 위험하다.
`publish_post.sh` 3/5 단계가 미러 HEAD 일치를 최대 10분 기다린다. 이관 중 실제로 이
지연을 관측했다(미러 등록이 push 이후라 첫 동기화가 밀렸다).

검증: `sync_local` 80편 + `astro build` 통과(80 페이지·이미지 123개),
`publish_post --dry-run` 5단계 통과. 실발행 1회는 사람이 아침에 한다.

실행 이력과 실측 함정은 [vault-migration-2026-08-19.md](vault-migration-2026-08-19.md) 에 있다.

**완료 후 상태**: cyprien_vault 는 아카이브(Atlas 39M·첨부 181M·Calendar·창작 Efforts +
15년 이력), b95labs_vault 는 일(노트 127개). 이관본은 339개 파일을 전수 대조해 검증한
뒤 원본에서 지웠고, 지운 이력은 git 에 그대로 남는다.

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

**작업 순서 (2026-08-19 실행)**:

1. ✅ restic 전송 상한 선행 반영 (업로드 1 MiB/s) — 대량 유입 전에 걸어야 의미가 있다
2. ✅ 활성 작업을 `b95labs_vault` 로 분리 → Forgejo 신규 저장소
3. ✅ cyprien_vault: Forgejo 이관 → origin 재지정 (기존 GitHub 은 `github` 리모트)
4. ✅ funes_days_alter: 같은 방식 이관
5. ✅ 스크립트 정비: 네 파일의 vault 경로 정정, 미러 반영 대기 단계 추가,
   `sed -i` BSD/GNU 분기 (맥에서 로컬 발행이 실패하던 원인)
6. ✅ 발행 리허설: sync 80편 + astro build + publish_post dry-run 통과
7. ✅ PAT 범위 확장·미러 동기화(사용자, 웹 UI) → **실발행 1회 통과**(og 75편 확인,
   미러 가드 통과, Vercel success) → cyprien 에서 이동 항목 삭제(339개 파일 전수
   대조 후). alter 의 GitHub push 는 미러가 대신해 별도 작업이 필요 없었다.
   최종 확인: 세 저장소 모두 local=forgejo=github 3중 일치

**확정 (사용자 결정 2026-08-18 → 2026-08-19 개정)**: 새 vault 이름 **b95labs_vault**
(개인사업자 상호) / 분리는 **스냅샷 새출발** / **GitHub 미러도 건다** (Forgejo + restic +
GitHub 3겹) — 단 **GitHub 쪽은 반드시 private** (`gh repo create --private` 로 생성 후
미러 연결, push mirror 는 대상 저장소를 만들어 주지 않는다).

분리 방향은 실행 직전에 역전됐다. 08-18 안은 원고를 새 vault 로 빼는 것이었으나, 사용자가
"ACE 에서 Effort 와 데일리만 쓴다 — 역방향으로 생각해야 한다"고 정정하면서 대상이
"원고 31M"에서 "Atlas 전체 + 첨부 220M"로 커졌고, 그러면 15년 이력이 내용과 분리된다.
결론: 아카이브를 제자리에 두고 활성 작업만 뺀다. 데일리 노트도 가져오지 않고 새로
시작한다 — ACE 자체를 AI 협업형 구조로 대체했다.

**조사로 확인한 것 (2026-08-18~19)**: Atlas/Works 는 예상보다 독립적이었다 — 첨부
임베드 0건, 외부 유입 링크 실질 2건, 유출은 `_indexes/year/*` 한 유형뿐. obsidian-git 은
`data.json` 이 없어 전 기능 기본 비활성(자동 push 타이머 없음)이라 origin 교체가 조용히
깨질 경로가 없었다. 로컬 클론은 origin 보다 19 커밋 뒤처져 있었다(다른 노트북에서 push).

---

### 8단계 — 감시 분리 + 백업 근본 해결 (2026-08-20)

dGPU 하드 행 사고(§Changelog)를 계기로 감시와 백업의 구조적 결함을 함께 해소했다.

**Kuma 모니터 7개 분리**: 단일 push 모니터 + 집계 status 구조에서는 **먼저 난 장애가 뒤에 난 장애를 가린다** — 이미 down 인 상태에 새 장애가 겹쳐도 status 가 그대로라 Kuma 가 상태 변화로 보지 않는다. 08-19 17:13 의 restic 락으로 down 인 동안 dGPU 가 죽었는데 이력에 흔적이 없었다(12:12~12:35 공백, 가동률 12.81%). 점검을 `host`·`backup`·`core`·`apps`·`ci`·`ai`·`media` 로 나눠 그룹마다 `KUMA_PUSH_URL_<그룹>` 에 신고한다. 매 실행에서 7개 전부 보낸다 — 실패한 그룹만 보내면 나머지가 하트비트를 잃어 오탐이 된다. URL 이 없는 그룹은 journal 기록만 하고 넘어가므로 모니터 생성 전에도 배포·검증이 된다. 실측 함정: 그룹 배열을 `GROUPS` 로 두면 안 된다 — bash 특수 변수(현재 사용자의 GID 배열)라 대입해도 셸이 덮어쓴다. 첫 배포에서 root 의 GID 3개(1000 985 10)를 돌았다. `CHECK_GROUPS` 로 쓴다.

**restic 스테일 락 자동 해제**: 저장소 락은 Drive 위의 파일이라 프로세스가 죽으면 남는다(로컬 `flock` 은 커널이 회수하므로 층이 다르다). `backup` 은 shared lock 이라 통과하지만 `forget` 은 exclusive 라 막혀, **백업은 "성공"으로 보이는데 보존 정리만 조용히 실패**한다. `backup.sh` 의 forget 앞에 `restic unlock` 을 뒀다 — 기본적으로 30분 넘게 갱신되지 않은 락만 지우므로 살아 있는 백업을 방해하지 않는다.

**개인 client_id 전환**: 구성과 재인증 절차는 §8 2단계. 전환만으로 `rateLimitExceeded`·500·재시도가 0건이 되고 매시 백업이 88초→34초로 줄어, `tpslimit` 을 4→10(burst 5)으로 완화했다.

**llm 유닛 재시작 상한**: GPU 가 죽으면 llama-server 는 영원히 못 뜨는데 `Restart=on-failure` 만 있어 72회를 돌았고, 유닛은 내내 `activating` 이라 로딩 중과 구분되지 않았다. 재시작이 회복이 아니라 은폐가 되는 경우다. glimmer·lightning 의 `[Unit]` 에 `StartLimitIntervalSec=600`·`StartLimitBurst=5` 를 걸어 5회 실패 후 `failed` 로 확정시킨다.

**Glimmer 컨텍스트 128K→96K**: VRAM 여유가 5321MiB 뿐이라 프롬프트 캐시 축출이 잦았고 사고도 그 순간에 났다. 슬롯 수(`-np`)를 줄이는 안은 시험 후 되돌렸다 — 근거는 §6.

**검증 통과**: 7개 push URL 모두 HTTP 200. 격리 실측 — `ai` 그룹에 실패를 주입하니 `ai=down (comfyui)` 이고 나머지 6개는 `up` 을 유지했다(기존 구조에서는 불가능했던 동작). 락 해제 후 백업이 처음으로 `Done.` 완주, 이후 자동 회차도 34초 완주. **남은 것: Kuma 알림 채널 등록** — 채널이 없는 동안 down 은 대시보드에서만 보인다. 기존 `gem12-health` 모니터는 새 7개가 안정된 뒤 정리한다.

---

## Changelog

- **2026-08-20 (Litestream 호스트 이전 — 복제 대상 2→8)** — apps 컨테이너 안의 Litestream 은 다른 컨테이너의 DB 에 **구조적으로** 닿을 수 없었다(컨테이너는 `source: /mnt/data/<자기이름>` 만 마운트받는다). 그 결과 SQLite 9개 중 2개만 복제되고 있었고 **Forgejo 전체가 담긴 `gitea.db` 가 빠져 있었다** — 매시 restic 만으로는 최대 1시간 손실이고, git 저장소는 미러에서 되찾아도 이슈·PR 은 못 되찾는다. 원인은 나쁜 설계가 아니라 도입 시점의 관성이다: 컨테이너 데이터 분리가 먼저 있었고(옳다), Litestream 이 나중에 apps 의 DB 문제를 풀며 그 안에 설치됐다.

  복제는 컨테이너의 부속물이 아니라 인프라 층이므로 호스트로 옮겼다. 대상 8개(gitea · uptime-kuma · flue-agents · arxiv-candidates · polydeukes-cognee · cache · n8n · jellyfin), 복제본도 apps 종속 경로에서 `/mnt/data/backup/litestream/` 으로 중립화했다. **복원 리허설 통과** — `gitea.db` 를 복제본에서 되살려 integrity ok, 이슈 94건·저장소 7개 확인. 새로 편입된 `flue-agents.db` 는 restic 이 `/mnt/data/ci` 를 통째로 제외하므로(CI 캐시 전제) 이 복제본이 유일한 백업 경로가 된다.

  `nocodb/noco.db` 는 `journal_mode=delete` 라 제외했다 — WAL 이 없으면 Litestream 이 읽을 것이 없다. 전환은 서비스 정지가 필요해 매시 restic 에 맡긴다. 헬스체크의 litestream 점검도 apps 그룹에서 host 로 옮기고, **sync 로그 점검을 하나 더 걸었다** — 서비스가 active 여도 복제가 멈출 수 있고, 그 구분은 같은 날 백업에서 실측했다(restic backup 성공 뒤 forget 이 18시간 죽어 있었는데 "백업은 성공"으로 보였다).

- **2026-08-20 (rclone 개인 client_id 전환 — §1-1 완료)** — Google Cloud Console 에서 데스크톱 앱 클라이언트 ID 를 발급해 전환했다. 맥에서 `rclone authorize "drive" "<id>" "<secret>"` 로 재인증하고, 호스트 `[gdrive]` 에 client_id·client_secret·token 세 값을 함께 넣었다(token 만 갈면 refresh 가 공용 client 로 나가 실패한다). **전환 직후 실측: 매시 백업 88초 → 34초, `rateLimitExceeded`·500·재시도 전부 0건.** 이전에는 재시도 대기가 실제 시간을 잡아먹고 있었다 — 08-19 진단("500 은 파생이고 근본은 분당 요청 수")이 맞았다는 증거다. 이에 따라 `tpslimit` 을 4 → 10(burst 5)으로 완화했고 이 값에서도 오류 0건. 남은 것: 대량 유입 시 재확인(요청이 가장 몰리는 `backup-prune` 이 첫 신호가 될 것).

- **2026-08-20 (dGPU 하드 행 사고 — 감시가 사고를 못 잡은 이유까지)** — Glimmer 가 프롬프트 캐시 축출(350MiB 해제) 중 `radv/amdgpu: CS rejected (-13)` 로 dGPU 가 하드 행에 빠졌다. `leaking bo va` 수십 건 → KFD 경로 커널 oops 2건 → 재바인딩이 `vram size read: 0` / `discovery failed: -2` 로 실패. 드라이버 재로드로는 안 풀려 **호스트 재부팅**으로 회복했다(SMU 초기화 성공, Vulkan0 정상 인식, 맥→Glimmer 33.9 tok/s 확인). 사용자는 자동 재부팅을 거부했으므로 사람이 판단해 재부팅한다.

  조치 셋. ① `backup.sh` 의 forget 앞에 `restic unlock` — 저장소 락은 Drive 위의 **파일**이라 프로세스가 죽으면 남고, backup 은 shared lock 이라 통과하지만 forget 은 exclusive 라 막힌다. 08-19 17:13 의 락이 18시간 방치돼 매시 forget 이 죽었고 **백업은 "성공"으로 보이는데 보존 정리만 조용히 실패**했다. 락 해제 후 처음으로 `Done.` 완주. ② glimmer·lightning 에 `StartLimitBurst=5` — GPU 가 죽으면 llama-server 는 영원히 못 뜨는데 `Restart=on-failure` 만 있어 **72회를 돌았고 유닛은 내내 `activating` 이라 로딩 중과 구분되지 않았다.** 재시작이 회복이 아니라 은폐가 되는 경우다. ③ glimmer 컨텍스트 128K→96K — VRAM 여유가 5321 MiB 뿐이라 축출이 잦았다. 다만 `kv_unified=true`+`--no-warmup` 이라 유휴 VRAM 은 320 MiB 만 줄었다(효과는 부하 시 상한이 25% 낮아지는 것으로 나타난다). `-np 2` 로 슬롯을 줄이는 안도 시험했으나 되돌렸다 — 명시하는 순간 `kv_unified=false` 로 전환해 `-c` 를 슬롯 수로 나누는 탓에 `n_ctx_slot` 이 반토막(98304→49152) 나는데 VRAM 이득은 197MiB 뿐이었다(§6).

  그리고 감시 자체의 결함이 드러났다. Kuma 이력에 12:12~12:35 구간이 **통째로 비어 있었다** — 단일 push 모니터 + 집계 status 구조에서는 이미 down 인 상태(`backup-result`)에 새 장애가 겹쳐도 status 가 그대로라 Kuma 가 상태 변화로 보지 않는다. **먼저 난 장애가 뒤에 난 장애를 가린다.** 가동률 12.81% 로 상시 빨간불이라 알림 채널을 붙여도 무의미했을 상태였다. 점검을 7개 그룹(host·backup·core·apps·ci·ai·media)으로 나눠 그룹마다 `KUMA_PUSH_URL_<그룹>` 에 신고하도록 고쳤다. 매 실행에서 7개 전부 보낸다 — 실패한 그룹만 보내면 나머지가 하트비트를 잃어 오탐이 된다. 격리 검증 통과(ai 에 실패 주입 → ai 만 down, 나머지 6개 up 유지), 7개 URL 모두 HTTP 200. 실측 함정: 그룹 배열 이름을 `GROUPS` 로 두면 bash 특수 변수(GID 배열)와 충돌해 첫 배포가 root 의 GID 3개를 돌았다 — `CHECK_GROUPS` 로 바꿨다. 남은 것: 알림 채널 등록, 기존 `gem12-health` 모니터 정리.

- **2026-08-19 (§1-7 vault 이관 — 분리 방향 역전)** — cyprien_vault·funes_days_alter 를 Forgejo 원본으로 옮기고 활성 작업을 `b95labs_vault`(신규 29M)로 분리. **계획과 반대로 갔다**: 원고를 빼는 대신 아카이브를 제자리에 두고 일 노트를 뺐다 — 원고·메모·첨부가 vault 의 대부분이고 15년 이력의 주인공이라, 옮기면 활성 vault 가 죽은 이력 384M 를 끌고 다니게 된다. 새 vault 는 ACE 를 버리고 `projects/` + `journal/` 로 시작하며 루트 CLAUDE.md 를 사람·AI 계약으로 둔다(AI 쓰기 화이트리스트, provenance frontmatter). 2026년 AI 협업 PKM 관행 조사(Karpathy LLM Wiki, Google OKF, Reitz CLAUDE.md 계약)에 근거. 발행 파이프라인에 **미러 반영 가드**를 넣었다 — GitHub 이 비동기 미러가 되면서 반영 전 배포가 옛 원고로 "성공"하는 오배포 경로가 생겼고, 이관 중 실제로 지연을 관측했다. 부수 발견: `sync_local.sh` 의 `sed -i` 가 BSD(macOS)에서 실패해 로컬 발행이 애초에 동작하지 않았다. 실측 함정: GITHUB_MIRROR_PAT 은 fine-grained 라 저장소별 허용이 필요하고 웹 UI 로만 바꿀 수 있다. 검증: sync 80편 + astro build + dry-run 5단계 통과. 남은 것: PAT 범위 확장 → 미러 동기화 → alter GitHub push → 실발행 1회 → cyprien 정리(순서 의존, 핸드오버 문서). **부수 사고**: 402MB 유입으로 백업이 세 번 죽었다. 동시성 축소·대역 완화로 두 번 헛짚은 뒤 오류를 유형별로 집계해 원인을 잡았다 — `rateLimitExceeded` 22 대 500 이 11, 즉 **500 은 파생이고 근본은 분당 요청 수**다. rclone `--tpslimit 4` 로 요청 빈도를 묶자 968MiB 를 11분 20초에 rateLimit 0건으로 통과했고, vault 저장소 3개의 백업 편입을 `restic ls` 로 확인했다. 교훈: 로그가 시끄러울 때는 마지막 오류가 아니라 오류의 분포를 세라. §1-1 의 개인 client_id 전환이 근본 해결이며 우선순위를 올렸다.
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
