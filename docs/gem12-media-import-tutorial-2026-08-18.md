# 외장 SSD → GEM12 미디어 반입 튜토리얼

> 작성: 2026-08-18 · 대상 SSD: SanDisk Extreme SSD 1TB (exFAT, 실측 2026-08-18)
> 사진은 Immich(:2283)로, 영화는 Jellyfin(:8096)으로 넣는다. 두 서비스의 구축 기록은
> gem12-private-cloud-plan §12 7단계 참조.

## 전제

- SSD 최상위 구조 (실측): `사진/`, `영화/`, `음악/`
- 계획 §4 의 원칙: **원본은 이 SSD 다.** 서버에 넣는 것은 사본이므로, 서버 용량이
  모자라면 자유롭게 골라 넣으면 된다.
- SSD 는 exFAT 라 커널이 바로 마운트한다 (Fedora 는 커널 exfat 드라이버 내장, 추가 패키지 불필요).
- 아래 명령은 전부 **gem12 호스트에서 root** 로 실행한다: `ssh root@gem12`

## 1. SSD 연결과 마운트

SSD 를 gem12 의 USB 포트에 꽂고 장치 이름을 확인한다.

```bash
lsblk -f
# NAME        FSTYPE LABEL       ...
# sda
# └─sda1      exfat  Extreme SSD      ← 이 이름(sda1)을 아래에서 쓴다
```

`exfat` 파티션이 보이면 마운트한다. (장치 이름이 sdb1 등으로 다르면 그대로 바꾼다.)

```bash
mkdir -p /mnt/ssd
mount -o ro /dev/sda1 /mnt/ssd        # 원본 보호를 위해 읽기 전용으로 건다
ls /mnt/ssd                            # 사진, 영화, 음악 폴더가 보여야 한다
```

만약 `lsblk -f` 에 FSTYPE 이 다르게 나오면 (다른 디스크를 꽂은 경우):

- `ntfs` → `mount -t ntfs3 -o ro /dev/sdX1 /mnt/ssd` (커널 ntfs3 드라이버)
- `apfs` (맥 전용) → 리눅스 직결이 안 된다. SSD 를 맥에 꽂고 맥에서 서버로 전송한다:
  `rsync -avh --progress "/Volumes/<볼륨명>/영화/" root@gem12:/mnt/data/media/jellyfin/media/영화/`

## 2. 사진 → Immich

Immich 는 파일을 라이브러리 디렉토리에 직접 복사해 넣으면 **인식하지 못한다** —
DB 에 등록되는 경로는 업로드 API 를 거쳐야 한다. 대량 반입은 immich-cli 로 한다.

### 2-1. API 키 발급 (1회)

브라우저에서 `https://gem12.tail4555a7.ts.net:2283` → 우상단 프로필 → 계정 설정 →
**API 키** → 새 키 발급. 발급된 키를 복사해 둔다 (다시 볼 수 없으니 1Password 에
`GEM12_IMMICH_API_KEY` 로 보관 권장).

### 2-2. SSD 를 media 컨테이너에 임시로 붙이기

immich-cli 는 media 컨테이너 안에서 podman 으로 돌리므로, 호스트에 마운트한 SSD 를
컨테이너에 임시 disk 장치로 넘긴다.

```bash
incus config device add media ssd disk source=/mnt/ssd path=/mnt/ssd readonly=true
```

### 2-3. 업로드

```bash
incus exec media -- podman run --rm \
  -v /mnt/ssd/사진:/import:ro \
  -e IMMICH_INSTANCE_URL=http://10.10.10.15:2283/api \
  -e IMMICH_API_KEY=<발급한 키> \
  ghcr.io/immich-app/immich-cli:latest \
  upload --recursive /import
```

- 중복은 immich-cli 가 해시로 걸러 다시 올리지 않는다 — 중단됐다 재실행해도 안전하다.
- 진행량이 많으면 SSH 가 끊겨도 이어지도록 `incus exec media -- bash` 로 들어가
  `tmux` 안에서 돌리는 편이 낫다 (tmux 는 media 에 기본 설치돼 있지 않으면 `dnf install -y tmux`).
- 끝나면 웹 UI 타임라인에 사진이 보인다.

### 2-4. 장치 해제

```bash
incus config device remove media ssd
```

## 3. 영화 → Jellyfin

Jellyfin 은 Immich 와 달리 **파일 복사만으로 된다** — 라이브러리 폴더를 스캔하는
방식이라 API 를 거칠 필요가 없다. 호스트에서 바로 복사한다.

```bash
rsync -avh --progress /mnt/ssd/영화/ /mnt/data/media/jellyfin/media/영화/
# 음악도 넣으려면:
rsync -avh --progress /mnt/ssd/음악/ /mnt/data/media/jellyfin/media/음악/
```

복사 후 웹 UI 에서 라이브러리를 등록한다 (최초 1회):

1. `https://gem12.tail4555a7.ts.net:8096` → 대시보드 → 라이브러리 → 추가
2. 콘텐츠 유형 "영화", 폴더는 **`/media/영화`** (컨테이너 안 경로 — `/mnt/data/...` 가 아니다)
3. 음악을 넣었다면 유형 "음악", 폴더 `/media/음악` 으로 하나 더

이후 추가 반입은 같은 rsync 뒤에 대시보드 → 라이브러리 스캔이면 된다.

## 4. 반입 김에 SSD 건강 확인 (§8 의무)

이 SSD 는 사진·영화의 **원본**이므로 계획 §8 이 정기 SMART 확인을 요구한다.
연결한 김에 확인한다.

```bash
smartctl -H /dev/sda
# USB 브리지가 명령을 막으면:
smartctl -H -d sat /dev/sda
```

`PASSED` 가 아니면 SSD 교체를 검토하고, 교체 전까지 서버 사본이 유일본이 되지
않도록 새 SSD 로 원본부터 복사한다.

## 5. 안전 분리

```bash
incus config device remove media ssd   # 2-4 를 건너뛰었다면
umount /mnt/ssd
udisksctl power-off -b /dev/sda 2>/dev/null || true   # 안 되면 그냥 뽑아도 된다 (ro 마운트였으므로)
```

## 참고

- **서버 사본은 매시 restic→Drive 백업에 포함된다** (/mnt/data/media 는 제외 목록에
  없다). 수십 GB 를 반입하면 Drive 용량과 업로드 시간이 함께 늘어난다 — 원본이 이
  SSD 에 있으므로 대량 반입 전에 백업 제외 전환을 검토한다 (계획 §1-5 미결 항목).
- SSD 최상위의 `SanDiskSecureAccess*` 는 제조사 윈도우용 번들이고,
  `i03409af08ev.exe` 같은 무작위 이름 실행 파일은 출처 불명이다 — 서버에서 실행할
  일은 없지만, 맥에서도 실행하지 말고 정체를 모르면 지우는 편이 안전하다.
