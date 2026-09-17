# AdMob Android 테스트 광고

## 변경 파일

| 파일 | 변경 내용 |
| --- | --- |
| `pubspec.yaml`, `pubspec.lock` | 공식 패키지 9.1.0 및 광고 설정 asset 등록 |
| `config/admob_test.json` | Google Android 테스트 앱/배너/보상형 ID 통합 관리 |
| `android/app/build.gradle.kts` | 설정 파일 읽기, Manifest placeholder 주입, release 빌드 차단 |
| `android/app/src/main/AndroidManifest.xml` | SDK 앱 ID metadata |
| `lib/main.dart` | 앱 시작 시 비동기 SDK 초기화 |
| `lib/core/ads/ad_config.dart` | 설정 읽기·검증 및 플랫폼/build mode 제한 |
| `lib/core/ads/mobile_ads_service.dart` | 공통 초기화와 안전한 dispose |
| `lib/core/ads/adaptive_banner_service.dart` | Adaptive 배너 로드·실패·폐기 처리 |
| `lib/core/ads/rewarded_ad_service.dart` | preload·표시·보상 로그·폐기·재로드 |
| `lib/features/ads/widgets/adaptive_banner.dart`, `lib/features/ads/widgets/rewarded_test_button.dart` | 배너와 임시 테스트 광고 버튼 |
| `lib/features/chat/screens/usd_room_page.dart` | 광고 UI 제거 (채팅 로직 유지) |
| `test/ad_services_test.dart` | 광고 설정, 중복 호출, 보상 로그, 실패 복구, 늦은 콜백 검증 |
| `test/widget_test.dart`, `test/dollar_socket_test.dart` | USD방 광고 제거에 따라 원래 테스트 화면 높이로 복원 |
| `analysis_options.yaml` | 생성된 `build/**` 의존성 소스를 분석에서 제외 |
| `macos/Flutter/GeneratedPluginRegistrant.swift` | 광고 패키지의 WebView 의존성에 따른 자동 생성 변경 |
| `docs/admob-testing.md` | 구성·검증 결과·실기기 테스트 절차 |

## 실행한 검증

UI 재배치 후 analyze/test를 재실행했습니다. 아래 APK 빌드·release 차단 검증은 최초 광고 연동 시 실행한 결과입니다.

- `flutter analyze`: No issues found.
- `flutter test`: 51개 모두 통과 (광고 위치 및 페이지 이동 테스트 포함).
- `flutter build apk --debug`: 성공.
- 병합된 Android Manifest에서 Google 테스트 앱 ID 주입 확인.
- `flutter build apk --release`: `verifyAdmobReleaseConfiguration`에서 의도대로 차단됨.
- `git diff --check`: 통과.
- 실제 기기에서의 광고 수신·시청은 아직 실행하지 않았습니다. 아래 절차로 확인합니다.

## 현재 UI 배치

- USD방: 광고 UI 없음.
- 환율 상세/차트: 스크롤 콘텐츠 아래, 화면 하단 SafeArea 안에 Adaptive Banner 고정 배치.
- 마이페이지: 뽑기 카드의 `닉네임 뽑기 →` 버튼으로 `lib/features/gacha/screens/cosmetic_gacha_page.dart` 이동.
- 뽑기 페이지: 기존 RewardedAdService를 이용하는 테스트 광고 버튼 표시.
- 배치 및 내비게이션 검증: `test/ad_placement_test.dart`.

## 구성

- 공식 `google_mobile_ads` 패키지를 사용합니다.
- 모든 앱/광고 단위 ID는 `config/admob_test.json`에서 관리합니다. Google이 제공한 데모 ID만 포함하며 실제 ID는 없습니다.
- Gradle은 같은 JSON에서 앱 ID를 읽어 Manifest placeholder에 주입합니다. Flutter는 asset으로 배너/보상형 ID를 읽습니다.
- Android debug/profile에서만 광고를 사용합니다. Dart에서 release/다른 플랫폼을 비활성화하고, Android `preReleaseBuild`에서도 release 빌드를 차단합니다. 따라서 현재 `flutter run --release`도 허용하지 않습니다. production 전환은 별도 구현과 검토가 필요합니다.
- 앱 시작 시 SDK 초기화를 시작하되 앱 시작을 기다리게 하지 않습니다. 각 광고 서비스는 동일한 초기화 Future를 기다린 후 요청합니다.
- 마이페이지 → CosmeticGachaPage 진입 시 보상형 광고를 미리 로드합니다. 로드 실패 시 버튼으로 재시도하며, 재시도만으로 광고를 자동 표시하지 않습니다.
- 보상형 광고를 닫거나 표시 실패 시 dispose 후 다음 광고를 preload합니다. 준비 중/표시 중 중복 탭은 차단합니다.
- `onUserEarnedReward`에서는 `debugPrint('[AdMob] reward earned')`만 호출합니다. 조기 종료나 단순 닫기 이벤트로는 보상 로그를 출력하지 않습니다.
- 배너는 사용 가능한 가로폭으로 Adaptive 크기를 요청하며 폭/방향 변경 시 새 서비스로 다시 로드합니다. 실패한 배너는 표시하지 않습니다. 화면 재진입 시 다시 요청할 수 있습니다.
- SSV, 뽑기 API, 인벤토리 및 실제 보상 지급은 구현하지 않았습니다.

## Android 실기기 확인

1. USB 디버깅을 켠 Android 기기를 연결하고 `flutter devices`로 확인합니다.
2. `flutter run --debug -d <device-id>`로 앱을 실행합니다. 네이티브 패키지가 추가되었으므로 기존 앱의 hot reload만으로 확인하지 않습니다.
3. USD방에 광고 UI가 없는지 확인합니다. 환율 상세/차트 페이지에 진입하여 차트 콘텐츠 아래 화면 하단에 Google 테스트 배너가 표시되는지 확인합니다.
4. 화면 회전/분할 화면으로 폭을 변경합니다. 배너가 가용 폭에 맞게 다시 로드되고 잘리거나 중복되지 않는지 확인합니다.
5. 마이페이지 뽑기 카드의 `닉네임 뽑기 →` 버튼으로 별도 페이지에 진입합니다. 광고 준비 후 `▷ 광고 보고 뽑기권 받기`를 누릅니다. Google Rewarded 테스트 광고가 한 번만 열리는지 확인합니다.
6. 끝까지 시청하여 보상 조건을 충족합니다. Flutter 콘솔에 `[AdMob] reward earned`가 출력되고, 실제 자산·아이템·보상이 변경되지 않는지 확인합니다.
7. 광고를 닫고 다음 광고 준비가 완료된 뒤 다시 표시합니다. 빠르게 연속 탭해도 중복 표시되지 않아야 합니다.
8. 새 광고를 보상 조건 충족 전에 닫습니다. 해당 시청으로는 reward 로그가 없어야 합니다.
9. 비행기 모드에서 앱을 새로 시작하거나 미리 로드한 광고를 소진합니다. 로드 실패에도 앱이 유지되고 재시도 버튼이 표시되는지 확인합니다. 네트워크 복구 후 재시도 → 준비 완료 → 다시 탭하여 표시합니다. 이미 캐시된 광고는 오프라인에서도 표시될 수 있습니다.
10. 로드 중 환율 상세/뽑기 화면을 닫았다가 재진입하여 dispose 이후 예외나 중복 광고가 없는지 확인합니다. 광고 표시 실패는 `test/ad_services_test.dart`에서 콜백/플랫폼 예외를 주입하여 별도로 검증합니다.
11. `flutter build apk --release`가 `AdMob is TEST ONLY` 메시지로 실패하는지 확인합니다.

## 공식 문서

- https://developers.google.com/admob/flutter/quick-start
- https://developers.google.com/admob/flutter/banner
- https://developers.google.com/admob/flutter/rewarded
- https://developers.google.com/admob/flutter/test-ads

## Figma 빈 상태 UI

- `CosmeticGachaPage`: 뽑기권 0장 화면. 뽑기 버튼은 비활성화하고 Rewarded 테스트 광고만 연결합니다. 시청 후에도 뽑기권은 증가하지 않습니다.
- `CosmeticItemsPage`: 마이페이지의 `내 아이템 · 꾸미기`로 진입합니다. 글자색/글꼴/배경별 빈 화면과 뽑기 페이지 이동을 제공합니다. 저장소나 인벤토리 API는 구현하지 않았습니다.
- `기본 모습으로 적용`은 미리보기 안내만 표시하며 채팅 데이터는 변경하지 않습니다.
- `MyPage(appearance: NicknameAppearance.vintageGold, ...)`로 Figma 골드 예시를 렌더링할 수 있습니다. 화면 표시용 입력이며 아이템 획득·장착·저장과 연결되지 않습니다.
- 현재 미리보기는 실제 닉네임/보유량을 표시하며, Figma 예시의 수익률 +5.2%를 고정값으로 표시하지 않습니다.
- 획득 확률·지급 정책은 미확정 안내만 표시합니다. 실제 보상·SSV·뽑기 API는 추가하지 않았습니다.

### 아이템 조합·결과 디자인 미리보기 (2475:127)
- 마이페이지 → 닉네임 뽑기 → 획득 목록 · 확률 안내에서 `아이템 조합 미리보기` 또는 `뽑기 결과 미리보기`로 진입합니다.
- 조합 화면에서 글자색/글꼴/배경을 각각 선택하고 탭 이동 후에도 선택이 유지되는지 확인합니다. `사용 안 함`은 해당 종류만, `모두 해제`는 모든 종류를 초기화합니다.
- 효과는 닉네임에만 표시됩니다. 실제 채팅, 보유 달러, 수익률에는 적용하지 않습니다.
- 샘플 결과의 지금 적용/보관만 하기는 안내 후 닫힙니다. 실제 지급·저장·적용, 뽑기권 증가, API 호출은 없습니다.
- 좁은 화면과 큰 시스템 글꼴에서 카드와 하단 버튼을 스크롤하여 이용할 수 있는지 확인합니다.
