# 현재 상태

- 현재 Phase: Phase 3 — 전용 아트와 연출 확장
- 최신 완료: 심법 비급 표지, 강호록 기록 도장, 8개 장비 슬롯 전용 아트
- 현재 작업: Phase 3 등급 프레임 및 화면별 시각 QA
- 바로 다음 작업: 장비 등급 프레임 세트 점검 및 주요 화면 시각 회귀 확인
- 알려진 문제: 일부 화면은 공통 아이콘 fallback과 단일 파일 구조를 사용한다.
- 기술 부채/임시 구현: 단일 `lib/main.dart` 중심 구조, 장비·지역 일부 아이콘 fallback, 실제 이미지 기반 시각 회귀 자동화 미구축.
- 마지막 테스트: `flutter test` 9개 통과 (2026-08-29)
- 마지막 analyze: 기존 deprecated/preference info 106건, 오류 없음 (2026-08-29)
- 마지막 빌드: `flutter build web --release --base-href /gangho-ilji/` 성공 (2026-08-29)
- 마지막 배포: GitHub Pages `https://roycekim84.github.io/gangho-ilji/`
- 마지막 commit: 목걸이·옥패 전용 아트 작업 진행 중
