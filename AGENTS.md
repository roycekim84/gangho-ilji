# 강호일지 장기 개발 규칙

- 작업 전 `docs/CURRENT_STATUS.md`와 `docs/ROADMAP.md`를 읽고 현재 Phase의 다음 미완료 항목을 선택한다.
- 작은 단위는 사용자 승인을 기다리지 않고 연속 진행한다. 핵심 기획 변경, 저장 호환성 파괴, 외부 권한/유료 서비스, 해결 불가 blocker만 질문한다.
- 기능·아트 작업 후 주변 흐름을 함께 점검하고 `flutter test`, `flutter analyze`, 웹 release build를 실행한다.
- 작업 종료 전 `docs/CURRENT_STATUS.md`와 `docs/DEVELOPMENT_LOG.md`를 갱신하고 의미 있는 단위로 commit/push한다.
- 상세 품질·아트 기준은 `docs/GAME_QUALITY_GUIDE.md`, `docs/ART_GUIDE.md`를 따른다.
