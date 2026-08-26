# ImageGen 자산 목록

## 적용 원칙

- 모든 이미지는 강호일지 전용 무협 분위기의 보조 비주얼로 사용한다.
- 텍스트·수치·전투 상태는 Flutter 위젯이 담당하며, 이미지에는 UI 문구를 넣지 않는다.
- 지역·보스·일반 적 자산은 ID 매핑으로 선택해 콘텐츠 확장을 쉽게 한다.

## 주인공 / 시작

| 파일 | 용도 |
|---|---|
| `assets/images/title_cover.png` | 시작·엔딩 표지 배경 |
| `assets/images/hero_wanderer.png` | 상단 상태·무인·전투 주인공 초상 |

## 지역 배경

| 파일 | 지역 |
|---|---|
| `area_luoyang.png` | 낙양 외곽 |
| `area_bamboo.png` | 청죽림 |
| `area_blackwind.png` | 흑풍채 |
| `area_shanxi.png` | 산서대로 |
| `area_yunnan.png` | 운남 독림 |
| `area_blood.png` | 혈음곡 |
| `area_demon.png` | 천마봉 |

## 보스 / 일반 적

- `boss_*.png`: 7개 지역 보스전 및 지역 상세 보스 배지
- `enemy_luoyang.png`, `enemy_bamboo.png`, `enemy_blackwind.png`, `enemy_raider.png`, `enemy_poisoner.png`, `enemy_bloodcult.png`, `enemy_shadow.png`: 지역별 일반 전투 배지

## 아이템 / 시스템

- `item_sword.png`: 무기 장비 카드
- `item_armor.png`: 방어구 장비 카드
- `item_jade_talisman.png`: 기연 장비 보상 힌트
- `item_treasure_chest.png`: 기연 장비 발견 보상 힌트 (Phase B 확장)
- `item_helmet.png`: 머리 장비 슬롯 전용 아이콘 (Phase B 확장)
- `item_jade_pendant.png`: 목걸이·옥패 장신구 슬롯 전용 아이콘 (Phase B 확장)
- `skill_manual.png`: 무공 목록
- `meridian_texture.png`: 경맥도 배경 질감
- `chronicle_paper.png`: 강호록 기록 패널
- `event_mountain_letter.png`: 기연 이벤트 삽화

## 생성 방식

모든 자산은 ImageGen built-in 모드로 생성했으며, 공통 프롬프트 방향은 `stylized-concept` / `illustration-story` 계열의 먹색·갈색·한지·금색 무협 콘셉트다.
