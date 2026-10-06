# 염원의 선택권 — 앱 구현 및 서버 제안 계약

서버 미구현 상태에서 앱을 먼저 구현했다. 아래 경로/필드는 **제안 계약**이며 운영 API가 아니다.
접두사는 기존 /api/v1. 앱 진입점은 닉네임 뽑기 → 염원의 선택권 · SPECIAL 선택.
서버 GET이 404/501이거나 enabled=false이면 준비 중으로 표시하고 새 교환/사용을 막는다.
서버가 이 계약을 구현하고 enabled=true로 응답하면 기능을 사용할 수 있다.

## 규칙

- 달러칩 100개 → 선택권 1장. 기존 10칩 → 랜덤 뽑기권 교환과 별도 기능.
- 선택권 1장 → 현재 drawable인 미보유 SPECIAL 1개 확정 지급.
- 현재 활성 슬롯 NAME_COLOR/NAME_FONT/NAME_BACKGROUND만 대상. 보유 아이템은 목록에서 확인 가능하지만 선택 불가.
- 화면 열기/미리보기/선택/취소로는 차감하지 않는다. 최종 확인 요청 성공 시만 차감한다.
- 전부 보유하면 선택권을 보관하고 신규 SPECIAL 추가 후 사용할 수 있다. 칩 교환 자체는 가능하다.
- 재분류로 RARE가 된 손글씨 등은 서버 현재 등급 기준으로 대상에서 제외한다.
- 서버 권위 검증이며 앱 필터에 의존하지 않는다. 선택권 유효기간은 이번 계약에서 두지 않는다.

## GET /gacha/wish-tickets (인증 필수)

```json
{
  "enabled": true,
  "exchangeCost": 100,
  "dollarChipBalance": 120,
  "wishTicketCount": 1,
  "items": [
    {
      "cosmetic": {
        "id": "cos_color_special_01",
        "type": "NAME_COLOR",
        "rarity": "SPECIAL",
        "displayName": "황금빛",
        "appearance": {"nameColor": null, "nameFont": null, "nameBackground": null, "styleToken": "golden_shimmer"},
        "isDrawable": true
      },
      "isOwned": false
    }
  ]
}
```

잔액과 가격은 음이 아닌 정수. 앱은 exchangeCost=100만 지원하며 다른 가격에는 새 작업을 막는다.
items는 현재 선택 대상 카탈로그와 보유 여부를 서버에서 합성한다. 보유한 대상도 isOwned=true로 포함한다.
클라이언트가 지원하지 않는 신규 효과의 활성화는 앱 배포와 조율한다.

## POST /gacha/wish-ticket-exchanges

요청: `{"operationId":"UUID"}`

응답:
```json
{"operationId":"UUID", "dollarChipBalanceAfter":20, "wishTicketCountAfter":2}
```

100칩 차감과 선택권 1장 증가는 하나의 트랜잭션. 잔액/기능 활성화는 서버에서 검증한다.

## POST /gacha/wish-ticket-redemptions

요청: `{"operationId":"UUID", "cosmeticId":"cos_color_special_01"}`

응답: operationId, dollarChipBalanceAfter, wishTicketCountAfter 및 cosmetic(위와 같은 전체 아이템 snapshot).
선택권 1장 차감과 장식 지급은 하나의 트랜잭션. 현재 등급/SPECIAL·drawable·슬롯·미보유·잔여 선택권 검증.
동시에 일반 뽑기로 같은 아이템을 얻은 경우에도 중복 소모가 없도록 계정 단위 잠금/일관된 트랜잭션을 사용한다.
확정 선택은 랜덤 뽑기가 아니며 70/25/5 확률이나 랜덤 추첨 대상 수를 변경하지 않는다.

## 멱등성과 오류 (중요)

- 교환/사용 모두 (인증 계정, operationId)를 기준으로 멱등 처리한다.
- operationId를 다른 작업 종류 또는 다른 cosmeticId로 재사용하면 충돌로 거부한다.
- 성공 기록은 최초 결과를 저장하여 그대로 재응답한다. 재시도에는 현재 보유/활성화 검증보다 성공 기록 조회가 우선이다.
- 앱은 계정별로 미확인 요청 하나를 저장한다. 사용 요청에는 cosmeticId도 저장하며 재시도 시 변경하지 않는다.
- 타임아웃/5xx/알 수 없는 오류/응답 불일치/로컬 정리 실패는 요청을 유지한다. 새 작업보다 미확인 결과 확인이 먼저다.
- 아래 오류 코드는 **이번 operationId로 어떤 변경도 커밋되지 않았음**을 보장해야 한다.
  앱은 이 오류에 한해 보관 요청을 해제하고 잔액/목록을 다시 조회한다.
  - INSUFFICIENT_DOLLAR_CHIP
  - INSUFFICIENT_WISH_TICKET
  - COSMETIC_ALREADY_OWNED
  - COSMETIC_NOT_SELECTABLE
  - WISH_TICKETS_DISABLED
- 기존 ApiException 형태(status + code + message)를 사용한다. 404로 비즈니스 오류를 대신하지 않는다.
- 성공 재응답을 보유 중 오류로 바꾸면 안 된다. 요청 성공/실패 기록과 보유 변경을 원자적으로 저장한다.
- 인증·다른 계정 접근 차단, 차감 후 응답 유실, 동시 요청, 재시작, 토큰 만료 후 재시도를 검증한다.
- DB에 선택권 잔액 및 교환/사용 내역을 저장하고 탈퇴/보관 정책에 반영한다. 개인정보처리방침의 보상 기록 범위도 확인한다.

## 서버 완료 시 전달할 것

실제 API 경로/요청/응답/오류 코드, enabled 활성화 여부와 배포 버전.
계약이 다르면 앱 어댑터를 맞춘 후 사용자 배포한다. 운영 확인 전에는 기능 완료/배포로 안내하지 않는다.
