# GEM12 — 1인용 Private Cloud

> Tianbei GEM12 (Ryzen 7 8845HS / 60GB RAM / NVMe 1TB / RX 7900 XTX via OCuLink)
> Fedora Server 44 베어메탈 + Incus 시스템 컨테이너로 가동 중이다.

혼자 쓰는 개인 서버다. Git 저장소와 CI/CD, 업무 기록과 지식저장소, 로컬 LLM 추론,
이미지·영상 작업 환경, 사진과 미디어 보관을 한 장비에서 돌린다. 디스크가 1개뿐이라
이중화가 없으므로 **백업이 유일한 방어선**이고, 모든 설정을 Git 에 남겨 **다른
장비에서 그대로 재구축할 수 있는 상태**를 유지한다. 2027년 초 새 장비로 옮길 때
이 설정을 재적용해 서비스가 살아나는지가 최종 검증이다.

## 문서 지도

| 문서 | 성격 | 내용 |
|---|---|---|
| [operations.md](operations.md) | 살아있는 참조 | 현재 구성 — 가동 상태, 컨테이너, 네트워크, 백업, Git 전략, 설계 원칙 |
| [build-history.md](build-history.md) | 아카이브 | 구축 8단계와 검증 결과, 전체 Changelog |
| [ai-pipeline.md](ai-pipeline.md) | 설계 | 맥북=결정 / 서버=구현 분리, Forgejo Actions + Glimmer 파이프라인 |
| [next-hardware.md](next-hardware.md) | 계획 | 2027년 차기 장비 사양·시세 |
| [media-import.md](media-import.md) | 절차 | 외장 SSD 사진·영화 반입 |
| [first-boot-wifi.md](first-boot-wifi.md) | 절차 | 초기 부팅과 Wi-Fi·1Password 설정 |
| [preformat-checklist-2026-08-17.md](preformat-checklist-2026-08-17.md) | 사건 기록 | 포맷 전 백업 체크리스트 (재설치 시 재사용) |
| [vault-migration-2026-08-19.md](vault-migration-2026-08-19.md) | 사건 기록 | vault 이관 실행 기록과 실측 함정 |

## 남은 작업

- [ ] **분기 1회 외장 SSD 연결 시 `gem12-offline-copy` 실행** — 스크립트가 SMART 확인을 내장한다. 마지막 사본 2026-08-18(183MB, 검증 통과)

## 미결 판단

| 항목 | 결정 시점 |
|---|---|
| 블루레이 리핑 규모 → 미디어 스토리지 계획 | 리핑 시작 시 |
| ComfyUI 로컬 모델 도입 여부 — 2026-08-18 클라우드 전용(OpenRouter)으로 가동, 로컬 모델(백업 목록 65GB)은 보류 | 로컬 생성 필요가 생길 때 |
| 도메인 확보 여부 (서비스 주소용) | 외부 공개 시 |
| 차기 장비 보드 확정 — Taichi Lite(우선) vs Steel Legend(절약, [next-hardware.md](next-hardware.md)) | 구매 시 |
| 차기 장비 케이스 — 최종 후보 Jonsbo N5 vs Lian Li V3000 Plus ([next-hardware.md](next-hardware.md)) | 시스템 구축 시 재검토 |

## 성공 기준

2027년 초 차기 장비로 옮길 때, 이 저장소의 스크립트를 재적용해 서비스가 그대로
살아나면 성공이다. 그때까지는 **백업이 실재하는지**(복원 리허설)와 **설정이
Git 에 남아 있는지**(재현성)를 계속 확인한다.
