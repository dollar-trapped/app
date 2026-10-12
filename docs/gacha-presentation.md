# 달러 가챠 연출

2026-10-12. 기본 연출을 **Blender 영상 + Flutter 보상 합성**으로 전환했다. 하늘·구름·카메라 하강·착지 지면·케이스 반동·먼지·뚜껑 개방은 Blender에서 제작한다. 실제 보상별 달러 유성, 등급 반전, 접점 빛, 림 색과 보상 카드는 Flutter가 그린다. 오디오는 기존 NoOp를 유지한다.

## Blender 영상 경로

10연차 도입부는 **상단 광원 하나의 섬광 → 폭죽처럼 사방으로 빛 10개 방출 → 흩어진 빛이 아래로 휘어짐 → 기존 가로 대형 → 가속 낙하** 순서다. `film/gacha_film_ignition.dart`에서 공통 출발점, 확산 곡선, 섬광 색상을 관리한다. 원본 시간 250ms에 중심 섬광을 뚫고 서로 다른 방향과 거리로 방출된다. 상하좌우로 빠르게 퍼진 뒤 저항에 의해 느려지면서 계속 아래로 휘어진다. 700ms부터 1.85초까지 나가는 속도를 유지하는 Hermite 곡선으로 가로 대형에 합류한다. 폭죽의 좌우 순서를 정렬 슬롯에도 유지해 빛끼리 가로지르거나 정렬 중 위로 되돌아가지 않게 한다. 방출 순간의 궤적·앞쪽 중심광·팽창 링과 64개(High)/28개(Low)의 작은 불티를 사용한다. 폭죽의 각도·거리는 재생마다 무작위로 정하되 한 재생 동안에는 고정하며, 마지막 정렬과 보상별 타격 지점에는 영향을 주지 않는다. 원형 확산 공간을 확보하기 위해 첫 광원은 화면 정규화 좌표 (0.62, 0.20)에 둔다. 빛은 같은 높이로 착지하며 접촉 순간 모두 함께 섬광과 불꽃이 발생한다. 단뽑은 같은 광원에서 빛 하나가 출발한다.

첫 섬광은 확정된 결과에 SPECIAL이 하나라도 있으면 무지개색, 없으면 흰색이다. 초반 섬광도 최고 등급을 암시하며, 이후 개별 SPECIAL 빛은 기존처럼 파랑에서 금색으로 반전한다. 섬광과 방출은 Flutter 합성 레이어에서 처리하며 Blender 배경·케이스와 충돌 시점은 공유한다.

SPECIAL은 2.85초의 금색 반전과 동시에 추가 가속한다. 2.85–3.09초에 속도를 부드럽게 올렸다 내리고 이후 기존 낙하 속도로 돌아온다. 이때 얻은 원본 시간 120ms의 선행량은 유지해 반전 직후 급제동이 생기지 않게 한다. 가속 중에도 10개 대형과 개별 타격 지점은 유지한다. 금색 빛만 200ms 동안 꼬리를 최대 1.9배 늘린다. `intro_timing.py`의 `specialBoost` 설정을 `track.json`에도 기록해 Blender 렌더와 Flutter 좌표 보간이 공유하므로 카메라·구름·빛이 함께 빨라진다. 접근 구간은 실제 재생 시각에서 직접 렌더링한다. 마지막 260ms는 70ms 제동, 110ms 억제, 80ms 4차 곡선 급가속으로 나눠 케이스에 빠르게 꽂히게 한다. 접촉 후 45ms 흰 코어와 180ms 불꽃을 동시 발생시킨다. 케이스는 최대 약 13.5% 눌림과 상하 반동을 갖고, 영상과 빛 레이어는 같은 행렬로 340ms 감쇠 카메라 반동·최대 7.5% 줌을 적용한다. UI는 흔들지 않는다. 260ms 바닥 충격파와 420ms 파편을 추가하며 High 42개/Low 18개로 제한한다. 카메라 반동 강도는 GradeConfig.shake에 비례한다. 의도한 짧은 억제 외에는 원본 프레임 반올림에 의한 멈춤을 사용하지 않는다. 금색 반전의 추가 가속은 SPECIAL에만 적용한다. 케이스 접근은 COMMON 650ms, RARE 800ms, SPECIAL 920ms로 늘려 읽을 시간을 확보한다.

- `tool/gacha_art/render_intro.py`: 기존 케이스 모델을 재사용해 원본 3D 장면을 생성한다. EEVEE로 720×1600·30fps 프레임을 실제 등급별 재생 시각에서 직접 렌더링한다. 빛·케이스 투영 좌표는 등급별 재생 시각에서 240Hz로 별도 계산한다. 원본 프레임은 시간이 정확히 일치할 때만 재사용하며, 근처 프레임으로 반올림해 늘이지 않는다. 원본은 `build/gacha-art/intro/intro.blend`에 저장한다. 외부 이미지·음원은 사용하지 않는다.
- `tool/gacha_art/intro_timing.py`: 등급별 시각과 금색 추가 가속, 원본 장면 평가 시각을 렌더·패키징에서 공유한다.
- `tool/gacha_art/package_intro.py`: 실제 재생 시각으로 렌더한 COMMON/RARE/SPECIAL 프레임을 H.264 MP4 3개로 인코딩하고 시작·개방 정지 화면과 `track.json`을 패키징한다. 생성물은 `assets/gacha/film/`이다.
- `presentation/film/gacha_film_track.dart`: Blender에서 등급별 재생 시각으로 계산한 보상별 1개/10개 빛 좌표와 케이스 좌표를 240Hz 표본 사이에서 보간한다. 성긴 원본 좌표에 역시간 곡선을 적용하는 방식은 착지 구간에서 속도를 불규칙하게 만들므로 사용하지 않는다. 영상과 합성 레이어는 동일한 contain 영역을 사용해 접힌 폰·펼친 폰·가로 화면에서도 좌표가 일치한다.
- `presentation/film/gacha_film_driver.dart`: 로컬 영상 초기화, 재생 시계 동기화, 버퍼링·앱 중단·복귀, 시간 제한, 실패 복구와 자원 해제를 담당한다. 네이티브 재생 위치 사이를 Flutter vsync로 보간하고 75ms를 넘는 편차를 보정한다. 영상 종료 후 기존 카드 타임라인으로 넘긴다.
- `presentation/film/gacha_film_impact.dart`: 영상·빛에 공유하는 충격 카메라 행렬과 바닥 충격파·고정 개수 파편을 관리한다. 시연 영상에도 동일한 변환을 적용한다.
- `presentation/film/gacha_film_layer.dart`: 영상과 확정 보상별 빛·입자·접점·개방 광선을 합성한다. 10개 빛의 등급을 하나의 색으로 합치지 않는다.

네이티브 영상 디코딩에는 Flutter 공식 [`video_player`](https://pub.dev/packages/video_player)를 추가했다. 영상은 앱 번들에서 읽으므로 로그인·네트워크가 필요 없다. `video_player_platform_interface`는 모의 플랫폼 테스트용 개발 의존성이다. 영상 초기화가 8초를 넘거나 재생 진행이 6초 이상 멈추면 기존 Canvas 연출로 이어간다. 재생 실패·스킵은 이미 확정된 보상에 영향을 주지 않는다. 움직임 줄이기에서는 디코더를 초기화하지 않는다. 영상 사용 중에는 대체 케이스 24장을 디코딩하지 않는다.

영상은 30fps이며 Flutter UI·빛은 기기 vsync로 갱신한다. High/Low는 합성 입자 수를 바꾸며 영상 파일은 공유한다. Flutter build/raster 성능과 네이티브 영상 디코더 성능은 별개이므로 UI 프레임 측정만으로 영상의 모든 프레임이 표시됐다고 판단하지 않는다.

```sh
blender --background --python tool/gacha_art/render_intro.py -- --preview
blender --background --python tool/gacha_art/render_intro.py
python3 tool/gacha_art/package_intro.py
```

장면·모델·카메라·조명·반동을 변경하면 위 전체 렌더를 수행한다. 장면이 같고 타이밍만 바꾼 경우 `-- --production-only --reuse-production`으로 정확히 같은 원본 시각의 프레임을 재사용할 수 있다. `--save-scene-only`는 장면과 원본 좌표만 저장하며 배포용 영상을 갱신하지 않는다. 일회성 구간 재렌더 옵션은 지원하지 않는다.

이하 Canvas 장면과 Blender 케이스 24장에 대한 설명은 영상 재생 실패 시의 대체 경로에도 적용한다. 테스트·과거 시연은 `useBlenderFilm: false`로 이 경로를 명시적으로 선택할 수 있다.

시연 영상·성능 측정 원본·검토 기록은 로컬 `docs/qa/`에 보관하며 새 QA 자료는 Git에서 제외한다. 앱에 필요한 배포용 영상은 `assets/gacha/film/`에서 계속 추적한다.

## 데이터와 화면 흐름

`DrawSession`에서 서버 성공 응답을 받은 뒤 불변 `GachaResult`를 만든다. 응답 대기 중에는 연출을 시작하지 않는다. 연출 컨트롤러는 확률·재화·인벤토리·네트워크 API에 접근하지 않는다. 단뽑은 빛 1개, 10연차는 각각 꼬리가 있는 빛 10개가 내려온다. Low에서도 개수는 유지한다. 각 빛의 머리·꼬리·지폐 파티클은 해당 보상 등급을 따른다. COMMON은 초록, RARE는 파랑, SPECIAL만 2.85초에 파랑에서 금색으로 반전한다. 전체 연출 길이와 케이스 충돌 강도는 최고 등급을 따른다. 빛은 한 점으로 합쳐지지 않는다. 케이스 하나가 처음부터 지면에 놓여 있고, 카메라 하강으로 먼저 화면에 들어온다. 각 빛은 뚜껑 위의 서로 다른 지점에 같은 대형으로 동시에 닿고 접촉 섬광·불꽃도 함께 발생한다. 개방 광선도 보상 수와 일치하며 실제 보상 등급의 색을 사용한다.

화면 터치 또는 건너뛰기로 실제 단뽑 상세/10연차 전체 결과를 즉시 표시한다. 완료 후 장착과 다시 뽑기는 기존 화면·서버 계약을 사용한다. 움직임 줄이기는 효과 없이 결과로 이동한다. 앱이 비활성화되면 시계와 오디오를 멈추고 같은 진행 위치부터 재개한다.

## 파일 역할

`lib/features/gacha/presentation/`:

- `gacha_result.dart`: 확정 보상 스냅샷, 서버 모델 어댑터, 등급.
- `grade_config.dart`: 등급 표시명·색·효과량·햅틱·카드 시간, High/Low 설정.
- `gacha_timeline.dart`: Phase 경계, 반전 시점, hit-stop과 전체 길이.
- `gacha_flight.dart`: 화면 3.1배 높이의 낙하 경로와 가속, 카메라 하강·착지 구도, 충돌 직전 350ms의 재가속.
- `gacha_controller.dart`: 단일 시계, 이벤트, 스킵·수명주기.
- `particle_pool.dart`: 고정 용량 파티클. 난수는 시각적 계수 생성에만 사용한다.
- `reward_light.dart`: 확정 보상별 빛의 간격·낙하 대형·뚜껑 위 개별 타격 지점과 시차.
- `painters/gacha_scene_painter.dart`: 하늘·달러 유성·충돌·연기·광선. 하늘은 Picture로 캐시한다.
- `painters/blender_case_frames.dart`: 기존 Blender 케이스 24장 사전 디코딩·개방 프레임·해제. High 640px, Low 384px로 메모리 사용을 제한한다.
- `painters/hard_case_painter.dart`: 달러 글리프 및 에셋 로딩 실패 시 결과 접근을 유지하는 대체 케이스.
- `gacha_presentation.dart`: Canvas 레이어, 카드 뒤집기, UI·최종 결과.
- `gacha_feedback.dart`: 오디오·햅틱 인터페이스. 주입한 인스턴스는 해당 화면이 소유하고 dispose한다.

`widgets/dollar_case_reveal.dart`는 기존 호출부 호환 어댑터다. 실제 앱은 `DrawSession`에서 `GachaResult.fromDraws()`로 연결한다. 결과가 달라지는 새 연출에는 새 widget key/route를 사용한다.

케이스 이미지: `assets/gacha/case/case_00.png`–`case_23.png`. 기존 모델의 손잡이가 화면 중앙을 향하는 정면 구도로 24장을 렌더링한다. 카메라는 `(0, -10, 6.3)`에서 `(0, 0, 1)`을 향하며, 뚜껑과 내부가 보이도록 약 28도 내려다본다. 닫힘부터 완전 개방까지 카메라는 고정한다. `GradeConfig` 파일의 케이스 투영 상수와 개별 빛의 타격 지점은 이 카메라의 투영 좌표를 따른다.

재생성: `blender --background --python tool/gacha_art/render_case.py`. 끝에 `-- --preview`를 붙이면 닫힘·완전 개방 2장만 `build/gacha-art/front-preview/`에 출력한다. 스크립트가 출력하는 `CASE_PROJECTION` 좌표를 `GachaStyle`에 반영한다. 원본 `.blend`도 `build/gacha-art/case.blend`에 저장한다. 원본 배경·음원은 복원하지 않았으며 기존 Canvas 연출을 유지한다.

## 타임라인

첫 보상 공개 완료까지 COMMON 5.00초, RARE 6.82초, SPECIAL 7.75초다. 가속 낙하 구간은 COMMON 1.8초, RARE/SPECIAL 3.1초다. 네트워크 대기는 제외한다. 모든 카드 이후 여운 0.45초가 추가된다.

| Phase | COMMON | RARE | SPECIAL |
|---|---|---|---|
| 단일 섬광·빛 방출 시작 | 0–0.55 | 0–0.55 | 0–0.55 |
| 가속 낙하·카메라 추적 | 0.55–2.35 | 0.55–3.65 | 0.55–3.65 |
| 정적·착지 접근 | 2.35–3.00 | 3.65–4.45 | 3.65–4.57 |
| 충돌 | 3.00–3.18 | 4.45–4.63 | 4.57–4.76 |
| 연기·케이스 | 3.18–3.55 | 4.63–5.00 | 4.76–5.29 |
| 개방 | 3.55–4.10 | 5.00–5.72 | 5.29–6.25 |
| 첫 카드 | 4.10–5.00 | 5.72–6.82 | 6.25–7.75 |

처음에는 지면이 화면 밖에 있다. 별이 가속하면 카메라가 아래로 따라가고, 구름과 별은 서로 다른 속도로 위로 흐른다. 착지 직전에 지면이 들어오고 카메라는 케이스를 담는 구도로 멈춘다. Blender 케이스는 지면에 고정되어 있고 빛이 도착하기 전에 보인다. 기본 Blender 경로의 빛은 뚜껑을 향해 마지막 80ms에 재가속하며, 닿기 전에는 사라지거나 케이스로 변하지 않는다. 충돌 섬광·잔상은 보상별 타격 지점에만 생긴다. 연기와 먼지는 케이스 뒤로 펼쳐 접점을 가리지 않는다.

개별 SPECIAL 빛은 2.85초까지 파랑이며, 이후 노랑으로 바뀌면서 70ms 국소 섬광과 꼬리 확장을 적용한다. 첫 광원의 무지개/흰색 차이는 이 개별 색 반전과 별개다. 기본 Blender 경로는 충돌 순간 케이스 압축과 감쇠 반동을 시작한다. Canvas 대체 경로의 hit-stop은 COMMON/RARE/SPECIAL 각각 60/80/100ms다. 이후 추가 카드 길이는 COMMON 0.65초, RARE 0.9초, SPECIAL 1.5초다. 보상명·등급·신규/중복 안내는 카드에 순서대로 나타난다. 마지막 카드는 여운 중에도 유지된다.

Canvas 대체 경로의 High 풀은 최대 240개·연기 48개, Low는 96개·연기 16개다. 파티클 계수는 생성 때 한 번 할당하고 매 프레임 재사용한다. 연기 radial gradient와 블러도 코드로 128×128(High) / 64×64(Low) 투명 텍스처를 한 번 생성해 재사용한다. 외부 이미지가 아니며 해당 자원은 화면 종료 시 해제한다. 생성이 실패하면 부드러운 radial gradient로 대체한다. 화면 정적 배경과 동적 장면 및 UI를 분리한다. 목표는 build/raster 각각 p99 16.7ms 이내이며 실제 측정 결과와 한계는 QA 기록에 남긴다.

## 사용 예와 데모

```dart
GachaPresentation(
  result: GachaResult.fromDraws(confirmedDraws),
  quality: GachaQuality.high,
  configs: GradeConfig.defaults,
  // audio: 구현한 GachaAudio, 기본은 NoOpGachaAudio
  // haptics: 기본은 FlutterGachaHaptics
  onFinish: () => Navigator.of(context).pop(),
)
```

오디오 이벤트는 별빛·낙하·등급 암시·반전·정적·충돌·개방·각 카드·종료다. `play(event, soundKey)`와 `stop()/dispose()`로 연결하며 외부 음원 없이 기본 구현은 무음이다. 햅틱은 light/medium/heavy이며 기기의 지원 수준에 따른다.

```sh
COSMETIC_PREVIEW_BUILD=true flutter run --profile \
  -t lib/main_gacha_preview.dart \
  --dart-define=COSMETIC_PREVIEW_BUILD=true
```

데모는 등급·1/10연차·High/Low를 선택한다. 10연차는 전부 커먼·레어 최고·스페셜 포함 구성을 제공한다. 카탈로그 fixture만 읽으며 로그인·개발 서버·실제 재화가 필요하지 않다. 위 환경 변수를 지정한 Android debug/profile 패키지는 `com.dollarmullim.app.preview`다.

## 검증과 재현

일반 테스트와 정적 분석:

```sh
flutter test
flutter analyze lib/features/gacha integration_test test_driver
```

기본 Blender 경로의 시연 영상은 다음 한 명령으로 생성한다. FFmpeg와 Flutter가 PATH에 있어야 한다.

```sh
python3 tool/gacha_art/export_preview.py
```

`build/gacha-art/previews/special-10.mp4`와 `rare-10.mp4`를 생성한다. 720×1600, 30fps, 6.5초, 무음이며 번들 영상과 실제 Flutter 빛·충격 카메라 코드를 합성한다. 고정 seed를 사용하므로 정리 전후 픽셀 비교에 사용할 수 있다. 결과 UI·카드는 생략하며 실기기 성능 측정 영상은 아니다. 중간 PNG는 `build/gacha-art/source-movie/`에 둔다.

`test/gacha_film_export_test.dart`는 내보내기 전용이며 일반 테스트 실행에서는 건너뛴다. 위 도구가 필요한 플래그를 지정해 실행한다. `test/gacha_film_test.dart`는 영상 수명주기·스킵·실패 복구·좌표·정렬·충격 카메라 회귀 검증을 담당한다.

실기기에서 3등급 × 1/10연차 × High/Low를 측정하려면:

```sh
COSMETIC_PREVIEW_BUILD=true flutter drive --profile --no-dds \
  --driver=test_driver/gacha_presentation.dart \
  --target=integration_test/gacha_presentation_test.dart \
  --dart-define=COSMETIC_PREVIEW_BUILD=true
```

Canvas 대체 경로의 기존 영상 도구는 별도로 유지한다:

```sh
flutter test test/gacha_sky_scene_test.dart --dart-define=EXPORT_GACHA_MOVIE=true
python3 tool/export_gacha_videos.py
```

승인한 기본 연출 영상 2개는 로컬 `docs/qa/gacha-presentation-2026-10-11/film/source-burst/heavy-slam-*.mp4`에 유지한다. 이전 시안 영상 34개는 `local-archive/gacha-videos/`로 옮겼으며 Git에서 제외한다. 이 보관 폴더는 `flutter clean`으로 삭제되지 않으며, `manifest.json`에 원래 경로와 SHA-256을 기록한다. 승인본과 보관 영상은 로컬 자료이므로 새 체크아웃에는 포함되지 않는다.

과거 측정·검토 문서는 `docs/qa/gacha-presentation-2026-10-11/`에 남긴다. 해당 문서의 이전 영상 링크는 로컬 보관 폴더를 가리킨다. Canvas 영상 도구의 기본 출력도 `build/gacha-art/procedural-previews/`로 분리해 docs에 새 시안이 쌓이지 않도록 한다. 이전 Canvas 구현의 측정값을 현재 Blender 경로의 성능 근거로 사용하지 않는다.

USB 재연결 후 준비된 데모 APK만 설치하려면:

```sh
adb install -r build/gacha-preview/gacha-preview-1.0.4-12.apk
adb shell am start -n com.dollarmullim.app.preview/com.dollarmullim.app.MainActivity
```
