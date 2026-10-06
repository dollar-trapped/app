# 시각 표현에 따른 희귀도 재분류 — 서버 적용 요청

## 결정

COMMON: 단순 정적 / RARE: 복합 정적 / SPECIAL: 동적 표현.
기존 희귀도 보존보다 이 기준을 우선한다. 특수 글꼴인 단정한 명조와 손글씨는 RARE,
기본형 둥근 고딕은 COMMON이다. 모바일 움직임 줄이기는 접근성 옵션이며 등급을 바꾸지 않는다.

## 현재 검증 범위

2026-10-06 공개 GET /api/v1/cosmetics 조회: catalogVersion=5, drawPolicy.version=4,
withinRaritySelection=UNIFORM, 등급 확률 bps 7000/2500/500, 중복 보상 1/3/5.
아직 주황/보라는 RARE, 손글씨는 SPECIAL이다. 이 문서는 서버 적용 완료 기록이 아니다.
이 저장소에는 Flutter 앱만 있어 DB 마이그레이션과 DrawExecutor 구현/실제 추첨 검증은
서버에서 수행해야 한다. 운영 뽑기권을 사용하는 POST 추첨 요청은 실행하지 않았다.

## 1. 기존 아이템 수정

| ID | 이름 | 변경 |
|---|---|---|
| cos_color_rare_01 | 선명한 주황 | RARE → COMMON |
| cos_color_rare_02 | 깊은 보라 | RARE → COMMON |
| cos_font_special_01 | 손글씨 | SPECIAL → RARE |

ID에 rare/special이 있어도 ID를 변경하지 않는다. 보유/장착 관계와 appearance,
isDrawable는 유지하고 rarity만 변경한다. 인벤토리는 변경된 현재 등급을 반환한다.
이후 중복 보상은 주황/보라 1칩, 손글씨 3칩이다. 이전에 지급한 칩은 회수하지 않는다.
과거 채팅과 단건/10회 뽑기 결과의 snapshot/rarity/보상 및 멱등 재응답은 그대로 유지한다.

황금빛(golden_shimmer), 진홍(crimson_pulse), 금박(gold_foil_shimmer)은 SPECIAL 유지.
앱에서 기존 토큰의 광택/맥동 대비와 금박 질감을 보강했다. 토큰/응답 계약 변경은 없다.

## 2. 신규 RARE 초기 활성화 제안

앱 지원을 배포한 후 아래 두 아이템만 우선 등록/활성화한다. ID는 서버에서 고정하여 공유한다.
기존 item ID를 재사용하지 않는다. 신규 효과에 nameColor HEX 컬럼을 사용하지 않는다.

| 이름 | type | rarity | appearance.styleToken | 표현 |
|---|---|---|---|---|
| 노을빛 | NAME_COLOR | RARE | sunset_gradient | 정적 노을 그라데이션 |
| 민트 격자 | NAME_BACKGROUND | RARE | mint_lattice | 정적 격자와 테두리 |

나머지 appearance의 nameColor/nameFont/nameBackground는 null.
현재 비활성인 버블 파티/춤추는 오로라/별빛 물결은 이번에 활성화하지 않는다.
신규 SPECIAL은 고유 움직임 검증을 마친 뒤 별도로 활성화한다.

## 3. 확률 (등급 내 UNIFORM 유지)

| 상태 | COMMON 수 / 개별 확률 | RARE 수 / 개별 확률 | SPECIAL 수 / 개별 확률 |
|---|---|---|---|
| 조회된 운영 v5 | 4 / 17.5000% | 4 / 6.2500% | 6 / 0.8333% |
| 기존 3종 재분류만 | 6 / 11.6667% | 3 / 8.3333% | 5 / 1.0000% |
| 위 신규 RARE 2종까지 활성화 | 6 / 11.6667% | 5 / 5.0000% | 5 / 1.0000% |

분모: isDrawable=true 이면서 현재 활성 슬롯(NAME_COLOR/NAME_FONT/NAME_BACKGROUND)에 속한
해당 등급 아이템 수. 비활성 아이템을 제외하며 앱 필터 적용 후 개수를 쓰지 않는다.
앱 표시는 소수점 넷째 자리까지 반올림하므로 표시값 합산에는 오차가 있을 수 있다.
실제 확률/추첨은 반올림된 표시값이 아니라 7000/2500/500 bps와 균등 선택을 사용한다.

## 4. 서버 필수 검증 및 배포 확인

- 카탈로그 버전을 증가시키고 캐시를 갱신한다. 정책 버전도 해당 배포의 정책과 정합성을 확인한다.
- 기존 ID/보유 수량/장착 ID/지급된 칩 잔액 불변을 마이그레이션 테스트로 검증한다.
- 과거 채팅 및 단건/배치 뽑기 snapshot 불변, 동일 drawRequestId 재조회 불변을 검증한다.
- 새 단건/10회 결과 및 신규 채팅은 새 rarity를 사용하고, 중복 지급은 새 등급을 사용한다.
- DrawExecutor의 등급 선택은 7000/2500/500, 등급 내 선택은 동일한 drawable 집합의 균등 추첨인지 검증한다.
  경계값을 주입하는 결정적 테스트를 우선 사용한다. 소수의 실뽑기 빈도만으로 확률 일치를 판정하지 않는다.
- 반환한 카탈로그의 각 등급 수와 위 표를 대조한다. 신규 활성화 구성이 달라지면 수와 확률을 다시 계산한다.
- 앱의 종류/등급 필터 전후 동일 아이템 확률이 같고 비활성 아이템이 노출되지 않는지 확인한다.
- 기존 등급/향후 중복 보상 변경을 이용자에게 안내한다. 이미 받은 칩 및 과거 기록은 유지된다고 설명한다.

서버 완료 후 변경된 catalogVersion/policyVersion, 3개 기존 ID의 rarity,
신규 아이템 ID 및 isDrawable, 등급별 추첨 대상 수와 개별 확률을 앱에 전달한다.
