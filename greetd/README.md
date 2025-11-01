# greetd + tuigreet 설정

경량 Wayland 네이티브 디스플레이 매니저인 greetd와 tuigreet을 사용합니다.

## 설치 방법

### 1. 패키지 설치 (rpm-ostree)

```bash
cd commands
./install_deps_fedora_sway_atomic.sh
# 또는 수동으로:
rpm-ostree install greetd greetd-tuigreet
systemctl reboot
```

### 2. 설정 파일 배포

```bash
# 이 디렉토리는 /etc로 배포되므로 sudo 권한이 필요합니다
sudo cp -r greetd/etc/greetd/* /etc/greetd/
```

### 3. SDDM 비활성화 및 greetd 활성화

```bash
sudo systemctl disable sddm
sudo systemctl enable greetd
```

### 4. 재부팅

```bash
systemctl reboot
```

## 커스터마이징

### 환영 메시지 변경

`/etc/greetd/config.toml`에서 `--greeting` 옵션 수정:

```toml
command = "tuigreet --time --remember --remember-user-session --asterisks --greeting 'Your Custom Message' --cmd sway"
```

### 자동 로그인 활성화 (선택사항)

`/etc/greetd/config.toml`에 다음 섹션 추가:

```toml
[initial_session]
command = "sway"
user = "your-username"  # 실제 사용자 이름으로 변경
```

### tuigreet 옵션

- `--time`: 현재 시간 표시
- `--remember`: 마지막 세션 기억
- `--remember-user-session`: 사용자별 세션 기억
- `--asterisks`: 비밀번호 입력 시 별표 표시
- `--greeting`: 커스텀 환영 메시지
- `--cmd`: 기본 세션 명령어

전체 옵션: `tuigreet --help`

## 문제 해결

### greetd가 시작하지 않는 경우

```bash
sudo systemctl status greetd
sudo journalctl -u greetd
```

### TTY로 돌아가기

greetd에 문제가 있으면 `Ctrl+Alt+F2`로 다른 TTY로 전환할 수 있습니다.

### SDDM으로 롤백

```bash
sudo systemctl disable greetd
sudo systemctl enable sddm
systemctl reboot
```
