# AdMob 구성과 검증

## 빌드별 광고 ID

광고 ID는 `config/` JSON에서 관리합니다. Gradle은 앱 ID를 Manifest에 주입하고 Dart는 동일 환경의 배너·보상형 ID를 읽습니다.

| 빌드 | 설정 | 광고 |
| --- | --- | --- |
| Android debug/profile | `config/admob_test.json` | Google 공식 테스트 광고 |
| Android release | `config/admob_production.json` | 실제 광고 |
| 기타 플랫폼 | 비활성화 | 없음 |

사용자가 최종 확인한 실제 ID:

- 앱: `ca-app-pub-8613152611947698~7427088470`
- 배너: `ca-app-pub-8613152611947698/5428058208`
- 보상형: `ca-app-pub-8613152611947698/2766235844`

Dart는 환경·ID 형식을 검증하며, Gradle의 `verifyAdmobReleaseConfiguration`은 release에 Google 데모 ID가 들어가면 실패합니다. 기존 release 전체 차단은 실제 설정 검증으로 대체했습니다. Android release 서명은 저장소의 기존 debug 서명 설정 그대로이며 스토어 배포용 키 설정은 별도입니다.

## 동작

- 앱 시작 시 SDK 비동기 초기화. 각 광고 서비스는 초기화 Future를 공유합니다.
- USD방 광고 없음. 환율 상세 페이지 하단 SafeArea에 Adaptive Banner를 표시합니다.
- 뽑기 화면 진입 시 보상형 광고 preload. 개발 빌드의 Google 데모 광고는 보상 없음 안내 후 재생만 하며 보상 세션을 만들지 않습니다. release 실제 광고는 세션 생성과 `customData` 설정 후 광고를 표시합니다.
- 광고 사용·표시 실패 후 dispose 및 다음 광고 preload. 로드·표시 중 중복 요청을 차단합니다.
- earned 콜백은 로그를 남깁니다. 실제 뽑기권은 서버 세션이 GRANTED인 경우에만 보유 API를 재조회해 갱신합니다.
- 배너 실패 시 숨기고, 보상형 실패·검증 지연 시 재시도 안내를 표시합니다.

API 계약·멱등성·SSV 처리 세부 내용은 [API 연동 문서](api-integration.md)를 참고하세요.

## 실기기 확인

1. `flutter run --debug -d <device-id>`로 실행하고 배너·보상형이 Google 테스트 광고인지 확인합니다.
2. USD방에는 광고가 없고 환율 상세 하단에 배너가 있는지 확인합니다. 회전·분할 화면에서도 배너 크기와 위치를 확인합니다.
3. 뽑기 화면에서 광고 중도 종료·로드 실패·표시 실패 후 재시도와 preload를 확인합니다.
4. 개발 빌드에서는 시청 전후 보상 없음 안내가 표시되고 세션 API가 호출되지 않는지 확인합니다. 실제 광고 완료 후 서버 상태가 PENDING이면 잔액이 증가하지 않아야 합니다. GRANTED에서 서버 잔액을 다시 조회하고 EXPIRED에서는 재시도를 허용해야 합니다.
5. 실제 보상형 단위의 AdMob SSV 콜백 URL을 서버 `/api/v1/admob/ssv`에 연결해야 실제 지급 검증이 가능합니다. 단위 ID 등록만으로 SSV 설정까지 완료되는 것은 아닙니다. Google 공식 테스트 단위로 이 서버의 실제 지급을 보장하지 않습니다.

자동 테스트는 광고 SDK 채널과 API를 모킹합니다. 실제 광고 수신·서버 SSV 지급 검증은 실기기에서 별도로 확인해야 합니다.
