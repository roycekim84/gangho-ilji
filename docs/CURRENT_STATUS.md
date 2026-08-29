# 현재 상태

- 현재 Phase: Phase 4 — 텍스트·밸런스·접근성
- 최신 완료: Phase 3 전용 아트·등급 프레임·320×700/390×844 핵심 화면 시각 QA, 주요 액션 버튼 44px 터치 영역, 숫자 그룹 표기, 피해 로그 강조, 경맥 노드·상태 게이지 접근성 의미, 전투 로그 용어집, 숫자·탭·게이지 회귀 테스트, 하단 탭 포커스 순서, 강호 메인 액션 문맥형 라벨, 자동 전투 표기 통일, 전투 로그 문장 다듬기, 지역 이동·보스 보상 문장 정리, 기연·오프라인 보상 숫자 표기 통일
- 현재 작업: Phase 5 릴리스 후보 — 저장 복구·회귀 점검
- 바로 다음 작업: 데스크톱 웹 레이아웃과 Pages 최종 smoke test
- 알려진 문제: 일부 화면은 공통 아이콘 fallback과 단일 파일 구조를 사용한다.
- 기술 부채/임시 구현: 단일 `lib/main.dart` 중심 구조, 장비·지역 일부 아이콘 fallback, 실제 이미지 기반 시각 회귀 자동화 미구축.
- 마지막 테스트: `flutter test` 15개 통과 (2026-08-29)
- 마지막 analyze: 기존 deprecated/preference info 103건, 오류 없음 (2026-08-29)
- 마지막 빌드: `flutter build web --release --base-href /gangho-ilji/` 성공 (2026-08-29)
- 마지막 배포: GitHub Pages `https://roycekim84.github.io/gangho-ilji/`
- 마지막 commit: 저장 복구 회귀 테스트 작업 진행 중
