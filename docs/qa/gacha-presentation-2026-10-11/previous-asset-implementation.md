# 금고 케이스 뽑기 연출

2026-10-11. 서버 결과, 확률, 재화, 보장 카운터 및 요청 ID 계약은 그대로 사용한다.

## 공개 흐름

- 전체 화면 하늘 전경 → 빛의 출발 → 구름 시차와 속도선을 이용한 낙하 추적 → 지상 케이스 전환. 도입부는 2초다. HUD와 연결 대기 안내는 도입부 종료 후 표시한다.
- 케이스 도착 뒤 사용자 터치 → 잠금 해제 0.25초 → 개방 0.55초 → 획득 공개 1.2초.
- SPECIAL은 금빛 틈 0.25초, 0.2초 정지, 본 개방 0.75초로 개방 총 1.2초. 획득 공개는 2.55초다.
- 일반 총 4초, SPECIAL 총 6초. 네트워크 대기와 터치 대기는 별도다.
- 단뽑은 별 1개, 10회는 별 10개가 내려온다. 도입부의 별은 중립색으로 등급을 예고하지 않는다.
- 서버 응답 이전에는 결과를 생성하거나 등급을 노출하지 않는다. 개방 전 조명은 중립색이다.
- 10회는 한 번 개방하고 서버 결과 순서대로 공개한다. 두 번째 결과부터 COMMON 0.35초, RARE 0.6초, SPECIAL 1.8초. 마지막에는 실제 결과 10개 그리드를 표시한다.
- 결과 타일을 누르면 상세/장착 화면을 연다. 슬롯 보존과 버전 충돌 처리는 기존 계약을 따른다.
- 건너뛰기는 추가 요청 없이 단뽑 상세 또는 배치 요약으로 이동한다. 공개 중 확인/다음과 카드 동작은 비활성화한다.
- 닉네임 실제 효과를 크게 보여주고 등급, 이름, 신규/중복 안내를 순서대로 표시한다.

## 원본 아트와 오디오

외부 게임의 아트/음원은 사용하지 않았다. Blender로 직접 만든 알루미늄 케이스, 고무 모서리, 힌지, 잠금장치, 손잡이와 시리얼 플레이트를 하나의 카메라/조명에서 렌더링한다.

```sh
blender --background --python tool/gacha_art/render_case.py
python3 tool/gacha_art/synthesize_audio.py
```

- `assets/gacha/case`: 투명 PNG 24장, 768×768.
- `assets/gacha/audio`: 결정적인 난수로 생성한 PCM WAV. 착지·잠금·힌지·등급 효과음은 라우트별 AudioPool로 준비한다.
- 네이티브 3D 런타임이 필요하지 않다. 원본 `.blend`는 `build/gacha-art/case.blend`에 저장한다. 원본 생성 스크립트를 버전 관리한다.
- 전체 아트/음원은 디스크 약 11MiB. 케이스 PNG의 RGBA 픽셀 합계는 54MiB, 추가 구름 레이어는 8MiB. 동시에 하나씩 디코딩하고 라우트 종료 시 이미지를 해제한다. Flutter ImageCache에 중복으로 등록하지 않는다. 이 수치는 앱 전체 RSS나 GPU 메모리를 의미하지 않는다.
- 이미지 또는 오디오 로딩 실패가 이미 결제된 결과의 표시를 차단하지 않는다.
- 효과음/진동 설정은 기존 보안 저장소에 각각 보존한다. 다른 앱 음악을 중단하지 않으며 iOS 무음 모드를 따른다.
- 배경 전환 시 애니메이션과 음성을 멈추고 복귀하면 같은 위치에서 재개한다. 같은 큐는 다시 재생하지 않는다. 건너뛰거나 빠르게 완료할 때 큐를 몰아서 재생하지 않는다.
- 움직임 줄이기는 도착/개방/문구 애니메이션과 진동을 생략한다. 결과 공개를 위한 터치는 유지한다.

## 실제 재화를 쓰지 않는 미리보기

로그인 화면의 개발 미리보기 버튼 또는 독립 진입점을 사용한다. COMMON/RARE/SPECIAL/10회/응답 대기 시나리오가 있다. 고정 카탈로그 fixture를 사용하며 네트워크 요청과 장착, 재화 변경을 하지 않는다.

```sh
COSMETIC_PREVIEW_BUILD=true flutter run --profile \
  -t lib/main_gacha_preview.dart \
  --dart-define=COSMETIC_PREVIEW_BUILD=true
```

Android debug와 profile은 위 환경 변수 사용 시 모두 `com.dollarmullim.app.preview`다. 기본 운영 앱과 설치/로그인을 분리한다. 설치 전에 다음으로 확인할 수 있다.

```sh
$ANDROID_SDK_ROOT/build-tools/36.0.0/aapt dump badging build/app/outputs/flutter-apk/app-profile.apk
```

## 검증

```sh
flutter test
flutter analyze lib/features/gacha lib/features/auth/screens/auth_page.dart lib/main_gacha_preview.dart integration_test test_driver
COSMETIC_PREVIEW_BUILD=true flutter drive --profile --no-dds \
  --driver=test_driver/gacha_presentation.dart \
  --target=integration_test/gacha_presentation_test.dart \
  --dart-define=COSMETIC_PREVIEW_BUILD=true
flutter build apk --release --build-name=1.0.4 --build-number=12
```

위젯 테스트는 요청 중복/재시도/보장 카운터 조회/슬롯 보존에 더해 공개 순서·건너뛰기·동작 제한·효과음 1회·백그라운드 중지/재개·움직임 줄이기·작은 화면/큰 글자를 검증한다.

실기기 테스트는 오프라인 fixture를 사용한다. `fullyLive` 프레임 정책과 실제 `FrameTiming`을 사용하며 각 시나리오의 프레임이 100개 이상 기록돼야 성공한다. 결과는 `build/integration_response_data.json`이다. 테스트 프레임만 그리는 기본 정책으로 얻은 1프레임 결과는 성능 근거로 사용하지 않는다. Android 폴더블 외부 화면에서 확인했으며 펼친 화면과 iOS 실기기 검증은 별도다.

[실기기 케이스 화면](qa/gacha-presentation-2026-10-11/case-closed.png)

### 2026-10-11 실기기 측정

SM_F966N, Vulkan/Impeller, profile, 폴더블 외부 화면. 설치 작업과 겹친 실행에서 얻은 수치다. 마지막 문구 순차 등장 변경 전의 측정이며, 최종 버전의 고정 60fps를 보장하는 자료로 해석하지 않는다.

| 시나리오 | 프레임 수 | build p99 ms | raster p99 ms | build/raster 16.67ms 초과 |
|---|---:|---:|---:|---:|
| COMMON | 551 | 2.030 | 14.580 | 1 / 3 |
| RARE | 586 | 2.530 | 12.216 | 0 / 2 |
| SPECIAL | 545 | 2.629 | 15.376 | 0 / 5 |
| 10회 | 2580 | 2.723 | 13.208 | 1 / 3 |

최초 COMMON 공개 build 최댓값은 95.438ms였다. 10회 build 최댓값은 24.571ms였다. 초기 공개 지연과 일부 프레임 초과가 남아 있으며, 모든 프레임이 목표를 만족한다고 주장하지 않는다. 추가 측정 시 설치/다른 작업을 병행하지 않고 냉간·반복 실행을 구분한다.

[원본 측정 결과](qa/gacha-presentation-2026-10-11/profile-before-text-staging.json)

최종 전체 위젯 테스트 268개와 변경 파일 정적 검사가 통과했다. 1.0.4(12) 릴리즈 APK 빌드도 성공했다. Flutter 테스트와 Android 빌드를 동시에 실행하면 자동 생성 플러그인 등록 파일이 충돌할 수 있으므로 단독 실행한다. 마지막 문구 순차 등장/상태바 대비/버튼 제한은 위젯 및 릴리즈 빌드로 검증했다. USB 연결 해제 뒤 추가 실기기 확인은 사용자에게 인계했다.

초기 profile 실행에서 개발 패키지 접미사가 debug에만 적용돼 기존 운영 패키지가 제거·교체되는 문제가 있었다. profile 접미사를 추가하고, 잘못 설치된 임시 운영 패키지를 제거한 뒤 정상 1.0.4(12) 릴리즈 앱을 다시 설치했다. 서버 데이터는 변경하지 않았지만 기기의 이전 로컬 세션/설정은 복원하지 못했다. 마지막 UI 다듬기 버전의 APK는 로컬 빌드 결과이며 폰에는 추가 설치하지 않았다.

## 도입부 재구성

같은 지상 배경 위의 짧은 별 낙하를 폐기하고 독립된 하늘 장면과 카메라 추적을 추가했다. `SkyArrivalScene`이 하늘/구름 시차/빛 추적/지상 전환을, `CaseTiming`이 공개 시간을 담당한다. 원본 구름 레이어는 `tool/gacha_art/render_sky.py`로 재현한다. 기존 실기기 성능 수치는 이 새 도입부에 대한 수치가 아니다. 추가 실기기 검증은 사용자에게 맡겼다.

참고 영상 목록: [원신 Wish 비교](https://www.youtube.com/watch?v=xoeIWihGNW0), [스타레일 워프](https://www.youtube.com/watch?v=0n-GaC1f5Ts), [젠레스 존 제로 신호 검색](https://www.youtube.com/watch?v=zlGrykO64zk). 비교 영상의 3성 원신 장면은 영상 설명상 시뮬레이터를 사용했다. 게임의 에셋이나 음원은 사용하지 않았다.

Flutter 렌더 장면 검증: [하늘](qa/gacha-presentation-2026-10-11/cinematic/sky.png) · [낙하 추적](qa/gacha-presentation-2026-10-11/cinematic/flight.png) · [지상](qa/gacha-presentation-2026-10-11/cinematic/ground.png). 테스트 렌더의 글자는 Ahem 테스트 폰트이므로 실제 앱의 글꼴과 다르다.

재구성된 도입부 기준 전체 테스트 269개와 연출 코드 정적 검사가 통과했다. 구름 레이어를 포함한 1.0.4(12) 릴리즈 APK 빌드도 성공했다(92.1MB). 새 도입부 실기기 성능 측정은 하지 않았다.

[2초 도입부 영상](qa/gacha-presentation-2026-10-11/cinematic/intro.mp4)은 실제 Flutter painter를 30fps로 렌더링한 장면 검토 자료다. HUD/효과음이 없는 10회 도입부이며, 실기기 촬영이나 성능 측정 자료가 아니다. `flutter test test/gacha_sky_scene_test.dart --dart-define=EXPORT_GACHA_MOVIE=true`로 원본 프레임을 `/private/tmp/gacha-intro-frames`에 재생성할 수 있다.
