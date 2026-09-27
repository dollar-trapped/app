# 비밀번호 재설정·장식·뽑기·광고 보상 연동

2026-09-18 확인한 서버 명세: https://api.dkarjsk.store/v3/api-docs
공개 카탈로그: https://api.dkarjsk.store/api/v1/cosmetics

## 연결한 흐름

- 로그인 → 비밀번호 재설정: `/auth/password/verification`에 이메일 전송 → `/auth/password/verify`에 이메일·6자리 코드 → `passwordResetToken`으로 `/auth/password/reset`에 `newPassword` 전송. 자동 로그인하지 않고 로그인 화면으로 돌아온다. 코드 재전송 버튼은 60초 대기한다. 계정 존재 여부는 표시하지 않는다.
- 마이페이지 → 내 아이템: `/users/me/cosmetics`의 실제 보유 목록·장착 상태 사용. 선택 중에는 로컬 미리보기만 변경한다. 적용 버튼이 `PUT /users/me/cosmetic-equipment`를 호출한다. 해제 슬롯은 명시적 null, 나머지 선택 ID와 `expectedVersion`을 전송한다. 409에서는 최신 상태를 다시 읽고 재선택을 안내한다.
- 마이페이지 → 닉네임 뽑기: 보유 API의 `drawEntitlementCount`를 표시하며, 카탈로그 API의 희귀도 확률(bps / 100)과 중복 보상을 안내한다. `/gacha/draws` 응답만 결과로 표시한다. NEW_COSMETIC과 DUPLICATE를 구분한다.
- 뽑기 요청 UUID는 전송 전에 계정별 secure storage에 저장한다. 타임아웃·화면 재진입·앱 재시작 이후 같은 UUID로 결과를 재확인한다. 응답 확인 후 키를 삭제한다. 저장 실패 시 요청을 보내지 않는다. 서버의 drawRequestId 멱등성 처리를 전제로 한다.
- 실제 광고는 미리 로드한다. 시청 버튼에서 보상 세션을 생성하고 응답의 `customData`를 `ServerSideVerificationOptions`로 광고 표시 전에 설정한다. earned 이벤트는 로그만 남기고, 광고 종료 후 세션을 조회한다. GRANTED일 때만 보유 현황을 다시 조회한다. PENDING은 최대 10회(2초 간격) 확인한 뒤 수동 재확인 버튼을 제공한다. EXPIRED는 새 시도를 허용한다. 앱에서 `/admob/ssv`를 호출하지 않는다.
- 채팅 API/소켓이 보낸 장식 스냅샷은 닉네임에만 표시한다. 보유량·수익률·말풍선, 메시지 송수신 및 신고·차단 처리는 유지한다. 과거 메시지의 장식은 서버 스냅샷을 따른다.

## 표시 매핑

- nameColor: 6자리 HEX 색상만 수용. 그 외에는 기본색.
- rounded_gothic: Jua / serif_classic: Noto Serif KR / handwriting: Nanum Pen Script.
- soft_gray: 회색 / sky_gradient: 하늘색 그라데이션 / gold_foil: 금색 배경.
- 서버는 스타일 키만 정의하므로 위 시각 매핑은 앱 구현 값이다. 알 수 없는 키는 기본 표시를 사용한다. NAME_TAG는 현재 장착 UI의 대상이 아니다.

## 테스트 광고 제한

Android debug/profile은 Google 공식 테스트 ID를, release는 `config/admob_production.json`의 실제 앱·배너·보상형 ID를 사용한다. Google 데모 ID를 사용하는 debug/profile에서는 보상 없음 안내를 표시하고 광고만 재생한다. 실제 보상 세션 생성·조회·잔액 갱신은 실행하지 않는다. 테스트 완료 콜백은 시청 완료 안내만 표시한다. 실제 지급 검증은 서버와 연결된 AdMob SSV 설정 및 검증 가능한 테스트 환경이 필요하다. 앱에서 로컬로 뽑기권을 증가시키거나 보상 검증을 우회하지 않는다.

Google 참고: https://developers.google.com/admob/flutter/ssv

## 실기기 확인

1. 테스트 계정 이메일로 코드 발송·잘못된 코드·정상 코드·비밀번호 불일치·정상 변경을 확인한다. 정상 변경 후 새 비밀번호로 직접 로그인한다. 메일 미도착/만료는 재전송·처음부터 다시 진행으로 복구한다.
2. 보유 아이템 선택 후 취소 시 장착이 유지되는지, 적용 후 재진입 시 서버 장착이 표시되는지 확인한다. 두 기기에서 동시에 변경해 버전 충돌 안내를 확인한다.
3. 서버가 지급한 뽑기권으로 NEW_COSMETIC/DUPLICATE 결과와 잔액을 확인한다. 네트워크를 끊었다 복구하거나 앱을 재시작한 후 같은 요청 결과 확인에서 중복 소비가 없는지 확인한다.
4. 광고 중도 종료·로드 실패·표시 실패 시 보상이 증가하지 않아야 한다. 완료 후 PENDING/GRANTED/EXPIRED를 확인하고, GRANTED일 때만 보유 수가 서버 값으로 갱신돼야 한다.
5. 장착 후 새 메시지의 닉네임만 꾸며지는지, 작은 화면·큰 글꼴에서도 주요 버튼에 접근 가능한지 확인한다.

실제 인증된 쓰기 요청/메일 전송/보상 지급은 자동 검증에서 수행하지 않았다. 공개 명세·카탈로그 GET 조회 및 모의 API/플랫폼 기반 테스트로 검증했다.

## 제재 안내·달러칩 교환 (2026-09-27)

- `User.moderation`의 `warnings`는 사유를 모달로 보여주되 입력을 막지 않는다. 채팅방 진입·앱 복귀·활성 상태 30초 간격으로 상태를 확인한다. 동일 화면에서 이미 안내한 경고는 반복하지 않는다.
- `chatBanExpiresAt`이 미래이면 채팅 입력·전송을 막고 해제 시각을 안내한다. 해제 시각 도달 또는 서버에서 해제를 확인하면 상태를 다시 반영한다. 재조회가 실패하면 알고 있는 제한을 유지한다.
- WebSocket `CHAT_BANNED`는 `details.userMessage`, `details.expiresAt`을 안내하고 대기 중 메시지 재전송을 중단한다. `USER_SUSPENDED`/`ACCOUNT_DISABLED`, 정지 종료 코드 4003은 연결·인증 상태를 정리하고 안내 후 인증 화면으로 보낸다.
- 로그인 `ACCOUNT_DISABLED`는 별도 모달로 안내한다. 현재 서버는 정지를 무기한으로 처리하며 시작·해제 시각을 로그인 응답에 제공하지 않는다. 앱은 날짜가 없으면 미제공이라고 표시한다. 상세 기간을 표시하려면 로그인 오류 details에 `userMessage`, `startsAt`, `expiresAt`이 필요하다. 계정 상태 조회에는 선택 필드 `suspensionStartsAt`, `suspensionExpiresAt`, `chatBanStartsAt`, `chatBanUserMessage`를 추가할 수 있도록 파서를 준비했다. 이 선택 필드들은 현재 서버 계약에 보장되지 않는다.
- `POST /gacha/chip-exchanges`에 UUID v4 `operationId`를 전송한다. 한 요청에 1장 교환하며 비용은 `drawPolicy.chipExchangeCost`를 사용한다(구버전 응답에는 10). 성공 응답 `dollarChipBalanceAfter`, `drawEntitlementBalance`를 표시하고 보유 현황을 재조회한다.
- 교환 ID는 사용자별 `pending_chip_exchange_` 키로 요청 전에 영구 저장한다. 타임아웃·앱 재실행 시 같은 ID를 재사용하고, 성공 확인 또는 `INSUFFICIENT_DOLLAR_CHIP`에서만 정리한다. 뽑기 ID와 저장 키를 분리한다. 클라이언트가 임의로 칩을 차감하거나 뽑기권을 지급하지 않는다.
- 과거 자동 전환 문구는 제거했다. 보유 칩이 충분해도 사용자가 교환 버튼을 누르기 전에는 교환하지 않는다.
