# 30종 장식 확장 — 앱 구현 및 서버 등록 명세

2026-10-09 사용자 승인 구성. 앱 효과/글꼴 구현과 서버 등록 계약을 기록한다.
같은 날 로컬 개발 API를 대조하여 카탈로그 v9 / 정책 v8, 추첨 가능 30종을 확인했다.
30종의 ID·이름·등급·appearance·isDrawable는 앱 fixture와 모두 일치하며 누락/추가/불일치가 없다.
핏빛 진홍은 기존 ID에 blood_crimson으로 반환된다. 이 확인은 운영 적용 완료 기록이 아니다.
운영은 사용자가 전달한 상태 기준 v7/v6, 추첨 가능 14종이며 운영 활성화는 별도 작업이다.

## 기존 진홍 변경

`cos_color_special_02`의 ID와 SPECIAL 등급을 유지하고 이름을 **핏빛 진홍**으로 변경한다.
현재 아이템의 appearance를 `styleToken=blood_crimson`으로 변경하며 나머지 세 필드는 null이다.
글자 안에서 둥근 액체 줄기가 점성 있게 아래로 흘러내리는 6초 주기 효과다.
과거 채팅/추첨 snapshot의 `crimson_pulse`는 기존 맥동 표현을 유지하므로 재작성하지 않는다.

## 신규 11종

아래 ID는 앱 측 제안이며 서버에서 충돌 여부를 확인하고 영구 ID로 확정한다.
NAME_FONT는 `appearance.nameFont`만, 나머지 신규 아이템은 `appearance.styleToken`만 설정한다.
다른 appearance 필드는 null이다. 단색 배경도 HEX를 nameBackground에 넣지 않고 토큰을 사용한다.

| 제안 ID | 이름 | type | rarity | appearance 값 |
|---|---|---|---|---|
| cos_bg_orange | 오렌지 | NAME_BACKGROUND | COMMON | styleToken=orange_solid |
| cos_bg_banana | 바나나 | NAME_BACKGROUND | COMMON | styleToken=banana_solid |
| cos_bg_grape | 청포도 | NAME_BACKGROUND | COMMON | styleToken=grape_solid |
| cos_bg_broken_glass | 깨진 유리 | NAME_BACKGROUND | RARE | styleToken=broken_glass |
| cos_font_heavy_gothic | 두꺼운 고딕 | NAME_FONT | RARE | nameFont=heavy_gothic |
| cos_font_future_square | 각진 미래체 | NAME_FONT | RARE | nameFont=future_square |
| cos_font_gentle_dodum | 고운 돋움 | NAME_FONT | RARE | nameFont=gentle_dodum |
| cos_font_playful_handwriting | 삐뚤 손글씨 | NAME_FONT | RARE | nameFont=playful_handwriting |
| cos_font_brush_script | 붓글씨 | NAME_FONT | RARE | nameFont=brush_script |
| cos_color_unstable_hologram | 불완전한 미래 | NAME_COLOR | SPECIAL | styleToken=unstable_hologram |
| cos_bg_desert_tumbleweed | 사막의 새 | NAME_BACKGROUND | SPECIAL | styleToken=desert_tumbleweed |

- 오렌지 `#FFE4CF`, 바나나 `#FFF2B8`, 청포도 `#E5F3CC`: 정적 단색 배경.
- 깨진 유리: 반투명 조각과 가지 모양 균열이 있는 정적 배경. 닉네임은 앞에 온다.
- 불완전한 미래: 초록 홀로그램/주사선 → 국소적인 가로 어긋남과 빨간색 → 초록 복구.
  전체 글자가 사라지지 않는다. 6초 주기 중 한 번 오류 상태를 거친다.
- 사막의 새: 고정 사구/모래 바닥 위로 회전초가 오른쪽으로 회전하며 구른다. 글자 뒤에 그린다.
- 새 글꼴: Black Han Sans / Gugi / Gowun Dodum / Gaegu Bold / Nanum Brush Script.
  Google Fonts 공식 저장소에서 받은 파일과 각 OFL 라이선스를 assets/fonts에 포함했다.
  실제 글꼴 굵기를 사용한다(대부분 400, Gaegu 700).

## 확률과 상태 보존

기존 등록 19종(기존 비활성 5종 포함)에 신규 11종을 등록·활성화하면 전체 30종이다.
현재 운영 14종에 새 11종만 추가하면 25종이므로, 기존 비활성 5종의 별도 활성화도 필요하다.

| 등급 | 최종 추첨 대상 | 등급 확률 | UNIFORM 개별 확률 |
|---|---:|---:|---:|
| COMMON | 9 | 70% | 7.7778% |
| RARE | 11 | 25% | 2.2727% |
| SPECIAL | 10 | 5% | 0.5000% |

중복 보상 1/3/5칩, 교환 비용 및 10회 RARE 이상 보장을 유지한다.
인벤토리는 현재 이름/외형을 반환한다. 기존 보유/장착 ID, 재화 잔액, 과거 채팅/추첨 결과와
멱등 재응답은 보존한다. 새 SPECIAL 2종의 선택권 목록/중복 선택 제한도 검증한다.

기존 V30/V32를 수정하지 않고 새 마이그레이션을 작성한다. 카탈로그/정책 버전을 새로 게시하며
개발 환경에서 먼저 확인한다. 이번 앱 코드 작업은 운영 DB나 서버 카탈로그를 변경하지 않는다.

## 앱 미리보기와 검증

[30종 응답 모양](../../../config/cosmetic_catalog_expansion.json)은 **설계 fixture**다.
게시 버전으로 오인하지 않도록 catalogVersion 및 정책 version을 넣지 않았다.
실제 추첨, 보유, 장착, 선택권 API는 계속 서버 응답만 사용한다.

검증용 debug APK는 아래 옵션으로 빌드한다.

```sh
COSMETIC_PREVIEW_BUILD=true flutter build apk --debug \
  --build-name=1.0.3 --build-number=10 \
  --dart-define=COSMETIC_PREVIEW_BUILD=true \
  --dart-define=API_BASE_URL=http://127.0.0.1:18080/api/v1 \
  '--dart-define=WS_URL=ws://127.0.0.1:18080/api/v1/ws?roomId=usd'
```

검증 앱은 별도 `.preview` 패키지로 설치된다. 로그인 첫 화면 또는 획득 목록·확률 안내의
**신규 30종 개발 미리보기**에서 시안을 확인하고 종류별 조합을 선택할 수 있다.
이 메뉴는 debug + 명시적 빌드 옵션에서만 보인다. release에선 노출되지 않는다.
새 시안의 서버 등록 전 획득/장착 상태를 임의로 만들지 않는다.

모든 동적 효과는 움직임 줄이기에서 정적 기본 프레임으로 돌아간다.
불완전한 미래는 초록으로 돌아오며 회전초는 정지한다. 비활성 화면의 ticker도 멈춘다.
자동 검증: 30종 ID/등급/appearance/확률, 글꼴 실제 로딩과 구분,
16px 동적 프레임 차이, 움직임 줄이기, 기존 효과/계약 호환.
실기기 가독성과 애니메이션 인상은 검증용 앱에서 추가 확인해야 한다.
