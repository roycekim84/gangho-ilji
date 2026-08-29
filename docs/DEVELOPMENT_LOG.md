# 장기 개발 로그

상세 기존 기록은 [`dev_log.md`](dev_log.md)에 보존한다. 앞으로는 아래 형식으로 누적한다.

## 기록 형식
- 날짜 / Phase
- 작업 내용
- 주요 변경 파일
- 테스트 결과
- build 결과
- commit hash / push 여부
- 배포 상태

## 2026-08-29 — 장기 자율 진행 문서 체계
- AGENTS 및 통합 로드맵·상태·품질·아트 가이드를 추가했다.
- 기존 계획과 개발 기록은 유지하고, 다음 자동 작업을 손 슬롯 전용 아트로 지정했다.

## 2026-08-29 — Phase 3 손 장비 전용 아트
- ImageGen으로 무협 완갑 아이콘을 생성해 `assets/images/item_bracers.png`로 추가했다.
- 손 슬롯이 전용 아트를 사용하도록 `gearArtwork` 매핑을 확장했다.

## 2026-08-29 — Phase 3 허리띠 장비 전용 아트
- ImageGen으로 무협 허리띠 아이콘을 생성해 `assets/images/item_sash.png`로 추가했다.
- 허리띠 슬롯이 전용 아트를 사용하도록 `gearArtwork` 매핑을 확장했다.

## 2026-08-29 — 자율 진행 문서·장비 아트 묶음 검증
- 주요 변경 파일: `AGENTS.md`, `docs/roadmap.md`, `docs/CURRENT_STATUS.md`, `docs/GAME_QUALITY_GUIDE.md`, `docs/ART_GUIDE.md`, `docs/DEVELOPMENT_LOG.md`, `lib/main.dart`, `assets/images/item_bracers.png`, `assets/images/item_sash.png`.
- `flutter test` 9개 통과, `flutter analyze` 오류 없음(정보성 lint 106건), 웹 release build 성공.
- commit `18753ba`, origin/main push 완료, GitHub Pages 배포 대상 반영.
## 2026-08-29 — 목걸이·옥패 장비 전용 아트
- ImageGen으로 목걸이와 옥패를 서로 다른 실루엣의 전용 아이콘으로 생성했다.
- `gearArtwork` 매핑을 슬롯별 파일로 분리하고 장비 계산·저장 구조는 유지했다.
- 주요 변경 파일: `assets/images/item_necklace.png`, `assets/images/item_jade_tablet.png`, `lib/main.dart`, `docs/roadmap.md`, `docs/CURRENT_STATUS.md`
- `flutter test` 9개 통과, `flutter build web --release --base-href /gangho-ilji/` 성공, `flutter analyze`는 기존 info 106건(오류 없음).
- commit `462a555`, `git push origin main` 완료. GitHub Pages 배포 파이프라인 반영 대기.

## 2026-08-29 — Phase 3 등급 프레임 시각 보강
- `ArtworkFrame`에 등급 색상 기반 1.2px 프레임과 약한 광택을 적용해 장비 희귀도 대비를 강화했다.
- `flutter test` 9개 통과, 웹 release build 성공. `flutter analyze`는 기존 info 106건(오류 없음).
- commit `65ef5a5`, `git push origin main` 완료. Pages 대상 반영.

## 2026-08-29 — 모바일 세로 viewport 시각 회귀 점검
- GitHub Pages에서 390×844와 320×700 viewport로 강호 메인 자동 전투 화면을 확인했다.
- 캐릭터 상태·지역·전투 상황·로그·자동전투·하단 탭이 첫 화면에 유지되며, 320px에서 지역명만 자연스럽게 줄바꿈된다.
- 브라우저 콘솔 오류/경고 없음. viewport override는 점검 후 초기화했다.
- 다음 점검 대상은 지역 선택과 장비 상세 화면이다.

## 2026-08-29 — 지역 선택·장비 상세 viewport QA
- GitHub Pages에서 지역 선택 바텀시트와 행낭·장비 상세 바텀시트를 320×700 및 390×844 기준으로 확인했다.
- 지역 목록 스크롤, 장비 옵션/버튼, 하단 탭이 작은 화면에서 잘리지 않으며 콘솔 오류가 없었다.
- 다음 점검 대상은 보스 전투와 기연 이벤트 화면이다.

## 2026-08-29 — 보스 전투·기연 이벤트 viewport QA
- 320×700에서 오프라인 보상 모달, 기연 선택·결말, 지역 상세·보스 도전·보스 전투 흐름을 확인했다.
- 기연 선택 결과가 모달로 명확히 표시되고, 보스 전투 로그·보상·하단 탭이 작은 화면에서 잘리지 않았다.
- 브라우저 콘솔 오류·경고 없음. 다음 점검 대상은 무인과 무도 화면이다.

## 2026-08-29 — 무인·무도(경맥/무공) viewport QA
- 320×700에서 무인 능력치·장비 요약, 무공 세팅, 보유 무공 목록, 경맥도 노드/연결 구조를 확인했다.
- 경맥 노드가 중앙 및 분기 노드와 연결되고, 스크롤 가능한 화면 영역에서 잘리지 않았다.
- 브라우저 콘솔 오류·경고 없음. 다음은 390×844 전체 핵심 화면 회귀 점검이다.

## 2026-08-29 — 390px 핵심 탭 회귀 점검
- 390×844에서 강호 메인, 무인 기록, 무도·무공 세팅, 지역 지도 흐름을 교차 확인했다.
- 정보 패널·장비 슬롯·무공 목록·지역 카드가 화면 폭에 맞게 유지되며, 브라우저 콘솔 오류·경고가 없었다.
- 보스·기연 화면의 390px 최종 확인 후 Phase 3 시각 QA를 마감한다.
- `ArtworkFrame`에 등급 색상 기반 1.2px 프레임과 약한 광택을 추가해 장비 희귀도 대비를 강화했다.
