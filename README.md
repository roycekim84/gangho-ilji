# 강호일지

로컬 저장 기반의 세로형 무협 방치형 RPG 알파입니다.

## 웹 플레이

GitHub Pages에서 배포되는 웹 버전은 모바일 세로 레이아웃을 기준으로 제작되었습니다.

▶ [웹에서 바로 플레이하기](https://roycekim84.github.io/gangho-ilji/)

현재 버전: `v0.1.0-alpha`  
서버·로그인·결제 없이 브라우저 로컬 저장만 사용하는 완결형 알파입니다.

주요 루프: 자동 전투 → 장비 드랍/장착 → 능력·무공·경맥 성장 → 지역 보스 → 엔딩

세부 기획과 완료 기준은 [`docs/`](docs/) 폴더를 참고하세요.

## 로컬 실행

flutter pub get

flutter run -d chrome

## 릴리스 웹 빌드

flutter build web --release
