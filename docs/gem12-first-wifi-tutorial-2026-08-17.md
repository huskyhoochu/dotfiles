# 첫 Wi-Fi 연결 튜토리얼 — Fedora Server 설치 직후

> 날짜: 2026-08-17 (월)
> 대상: GEM12 (Intel AX200 무선랜, 인터페이스 `wlp6s0`)
> 상황: Fedora Server를 막 설치했고, 랜선이 없고, **저장소를 아직 받을 수 없다**

이 문서는 서버가 인터넷에 붙기 전에 필요하므로 서버에서 열 수 없다. **맥북이나 휴대폰 브라우저로 GitHub에서 열어** 옆에 두고 따라간다.

```text
https://github.com/huskyhoochu/dotfiles/blob/main/docs/gem12-first-wifi-tutorial-2026-08-17.md
```

모든 명령은 서버 앞에 앉아 모니터와 **유선 키보드**로 친다.

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

## 다음 단계

이제 저장소를 받을 수 있다. 공개 저장소이므로 HTTPS로 받으면 인증이 필요 없다.

```bash
git clone https://github.com/huskyhoochu/dotfiles.git ~/dotfiles
cd ~/dotfiles/commands/incus
SSH_PUBKEY="ssh-ed25519 AAAA..." ./02-host.sh
```

이후 절차는 `commands/incus/README.md`와 `gem12-private-cloud-plan-2026-08-17.md` §8을 따른다.
