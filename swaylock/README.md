# swaylock-effects 설정

Sway용 향상된 화면 잠금 도구로, 블러 효과와 시계 표시 등 다양한 기능을 제공합니다.

## 설치 방법

### 1. COPR 활성화 및 패키지 설치 (자동)

```bash
cd commands
sudo ./setup_swaylock.sh
systemctl reboot
```

### 2. 수동 설치

```bash
# COPR 활성화
sudo dnf copr enable eddsalkield/swaylock-effects

# 패키지 설치
rpm-ostree install swaylock-effects
systemctl reboot
```

### 3. 설정 파일 배포

```bash
# Stow로 설정 배포
stow swaylock
```

## 기능

### 주요 기능
- **블러 효과**: 배경화면에 블러 적용
- **시계 표시**: 현재 시간과 날짜 표시
- **Catppuccin 테마**: Mocha flavor 색상 적용
- **Grace 기간**: 잠금 후 2초 이내 마우스/터치 없이 즉시 잠금 해제 가능
- **Caps Lock 표시**: Caps Lock 상태 시각적 표시

### 키보드 레이아웃 표시
현재 키보드 레이아웃(한/영)이 표시됩니다.

### 실패 횟수 표시
비밀번호 입력 실패 시 시도 횟수가 표시됩니다.

## 사용법

### 수동 잠금
```bash
swaylock -f
```

### 단축키로 잠금
Sway config에 다음 바인딩 추가:
```
bindsym $mod+l exec swaylock -f
```

### 자동 잠금 (swayidle)
5분 후 자동 잠금, 10분 후 화면 꺼짐:
```bash
exec swayidle -w \
    timeout 300 'swaylock -f' \
    timeout 600 'swaymsg "output * dpms off"' \
    resume 'swaymsg "output * dpms on"' \
    before-sleep 'swaylock -f'
```

## 커스터마이징

### 배경 이미지 변경
`~/.config/swaylock/config` 파일에서:
```
image=/path/to/your/image.png
```

### 블러 강도 조절
```
effect-blur=10x8  # 값이 클수록 더 흐릿함
```

### 시간 포맷 변경
```
timestr=%I:%M %p    # 12시간 형식 (AM/PM)
datestr=%A, %B %d   # 영문 날짜
```

### 색상 변경
Catppuccin 이외의 색상을 사용하려면 `config` 파일의 색상 코드를 수정하세요.

## 문제 해결

### swaylock-effects가 실행되지 않는 경우
```bash
# 패키지 설치 확인
rpm -q swaylock-effects

# 설정 파일 확인
cat ~/.config/swaylock/config

# 테스트 실행
swaylock -f -C ~/.config/swaylock/config
```

### 기본 swaylock으로 돌아가기
```bash
rpm-ostree uninstall swaylock-effects
rpm-ostree install swaylock
systemctl reboot
```

## swaylock vs swaylock-effects

| 기능 | swaylock | swaylock-effects |
|------|----------|------------------|
| 기본 잠금 | ✓ | ✓ |
| 블러 효과 | ✗ | ✓ |
| 시계 표시 | ✗ | ✓ |
| Grace 기간 | ✗ | ✓ |
| 효과 커스터마이징 | ✗ | ✓ |

swaylock-effects는 swaylock의 포크로, 모든 기본 기능을 포함하면서 추가 기능을 제공합니다.
