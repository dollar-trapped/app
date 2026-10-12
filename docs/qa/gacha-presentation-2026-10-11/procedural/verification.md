# 절차적 가챠 검증 기록

2026-10-11. Android SM_F966N, 펼친 화면 1968×2184, Impeller/Vulkan, profile, `com.dollarmullim.app.preview`에서 측정했다. 기존 운영 패키지를 교체하지 않았다. 오프라인 확정 fixture와 실제 production 연출 위젯을 사용한다. 최종 서비스의 모든 닉네임 장식 조합이나 iOS까지 성능을 보장하는 결과는 아니다.

## 실제 프레임 시간

각 조합의 전체 연출·카드 공개를 `fullyLive`와 `FrameTiming`으로 측정했다. 12개 조합 모두 build/raster p99가 목표 16.7ms 이내였다. 아래와 같이 일부 개별 프레임 초과는 남아 있으므로 모든 프레임이 60fps를 유지한다고 주장하지 않는다.

| 시나리오 | 프레임 수 | build p99 ms | raster p99 ms | raster 최대 ms | 16.67ms 초과 raster |
|---|---:|---:|---:|---:|---:|
| common_1_high | 608 | 1.344 | 2.716 | 5.127 | 0 |
| common_10_high | 1281 | 1.910 | 6.015 | 20.163 | 6 |
| rare_1_high | 832 | 1.405 | 1.644 | 7.936 | 0 |
| rare_10_high | 1566 | 1.593 | 5.812 | 17.135 | 2 |
| special_1_high | 1193 | 1.624 | 1.829 | 4.629 | 0 |
| special_10_high | 1995 | 1.600 | 5.801 | 33.875 | 3 |
| common_1_low | 585 | 1.313 | 1.397 | 7.488 | 0 |
| common_10_low | 1298 | 1.600 | 5.396 | 14.842 | 0 |
| rare_1_low | 832 | 1.270 | 1.363 | 2.313 | 0 |
| rare_10_low | 1555 | 1.556 | 5.288 | 17.994 | 2 |
| special_1_low | 1196 | 1.248 | 1.316 | 4.734 | 0 |
| special_10_low | 1988 | 1.678 | 4.962 | 19.211 | 2 |

[원본 측정값](profile-smoke-cached.json)

첫 측정에서 충돌 시점의 실시간 Gaussian blur가 큰 지연을 만들었다. 예를 들어 SPECIAL 단뽑 High의 raster 최댓값은 998.676ms였다. 연기 텍스처를 코드로 한 번 생성해 재사용한 뒤 같은 조합에서 4.629ms로 줄었다. [최적화 전 원본](profile-before-smoke-cache.json)도 보존했다. 기기의 캐시·온도 등 조건은 완전히 통제하지 않았으며, 개별 수치 차이를 모든 기기에 일반화하지 않는다.

## 자동 검증

- 전체 Flutter 테스트 271개 통과.
- 확정 응답 전 연출 미시작, 1/10연차 순서·최고 등급 유지, 모든 Phase에서 스킵 결과 동일성을 검증했다.
- 동일 seed의 Rare/Special은 반전 전 4개 시점에서 실제 Canvas 픽셀이 일치하고, 반전 후 달라지는 것을 검사했다.
- 자동 카드 공개·Special 시간·여운 동안 마지막 카드 유지·최종 확인 버튼을 검사했다.
- 백그라운드 정지·재개, 이벤트 중복 방지, 피드백 실패, 화면 종료·리소스 해제, 움직임 줄이기와 작은 화면/큰 글자를 검사했다.
- 기존 추첨 요청·재시도·보장 카운터 조회·장착 상태 보존 테스트도 포함한다.

## 영상 검토

12개 조합의 실제 Flutter 위젯을 420×900·15fps로 출력한다. 검토용 영상이며 15fps는 녹화 샘플링 간격이지 실기기 렌더링 속도가 아니다. 오디오는 기본 NoOp이며 영상에도 소리가 없다.

ffmpeg-analyse-video 스킬로 추출한 프레임에서 이전 하늘/금고의 분리된 전환이 해소된 것을 확인했다. 첫 검토에서 지적된 딱딱한 그림자, 과한 내부 광량, 마지막 카드의 여운 중 소실을 수정했다. 벡터 기반 2.5D 미술이며 사진처럼 사실적인 재질을 구현했다고 표현하지 않는다.

[커먼](../../../../local-archive/gacha-videos/qa/gacha-presentation-2026-10-11/procedural/common_1_high.mp4) · [레어](../../../../local-archive/gacha-videos/qa/gacha-presentation-2026-10-11/procedural/rare_1_high.mp4) · [스페셜](../../../../local-archive/gacha-videos/qa/gacha-presentation-2026-10-11/procedural/special_1_high.mp4) · [스페셜 10연차](../../../../local-archive/gacha-videos/qa/gacha-presentation-2026-10-11/procedural/special_10_high.mp4)

## 빌드·설치 상태

- 최종 `flutter analyze` 통과, 전체 테스트 271개 및 마지막 상태바 보완 후 관련 테스트 13개 통과.
- 실제 앱 진입점 `1.0.4+12` 릴리즈 APK 빌드 성공(80.8MB).
- 선택형 데모 profile APK: `build/gacha-preview/gacha-preview-1.0.4-12.apk`.
- 최종 데모 APK의 패키지 ID는 `com.dollarmullim.app.preview`로 확인했다. 설치 시점에 USB 연결이 끊겨 최종 데모 설치는 완료하지 못했다. 실기기 성능 측정은 연결이 유지되던 앞선 단계에서 완료했다.

[커먼 최종 프레임 검토](common-review.md) · [스페셜 최종 프레임 검토](special-review.md)
