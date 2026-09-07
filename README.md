**# dollar_trapped

# app

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
**# 달러물림

> 물려도, 혼자는 아니니까.

USD/KRW 환율을 보며 실시간으로 이야기를 나누는 환율 커뮤니티 앱입니다.

달러물림은 복잡한 자산관리 기능보다  
**“환율이 움직이는 순간 사람들이 모여 떠드는 공간”**에 집중합니다.

사용자는 자신의 달러 보유량과 평균 매수 환율을 선택적으로 등록하고,
자신의 포지션과 손익률을 표시한 채 다른 사용자와 실시간으로 대화할 수 있습니다.

---

## 주요 기능

### 실시간 USD/KRW 환율

현재 USD/KRW 환율과 변동률을 확인할 수 있습니다.

기간별 환율 차트를 통해 최근 환율 흐름도 확인할 수 있습니다.

### 실시간 채팅

USD/KRW를 주제로 하나의 실시간 채팅방에서 대화합니다.

채팅에는 사용자가 선택적으로 등록한 포지션이 함께 표시됩니다.

```text
김달러  $2,300 · +3.2%
1400 아래에서는 계속 산다
```
달러 포지션
사용자는 선택적으로 다음 정보를 등록할 수 있습니다.
- 달러 보유량
- 평균 매수 환율
현재 환율을 기준으로 계산된 손익률이 채팅 프로필에 표시됩니다.
등록된 자산 정보는 사용자가 직접 입력한 정보이며,
실제 금융자산 보유 여부를 인증하거나 보증하지 않습니다.
비회원 둘러보기
회원가입 없이도 다음 기능을 이용할 수 있습니다.
- 현재 환율 조회
- 환율 차트 조회
- 실시간 채팅 열람
채팅 참여와 포지션 등록은 로그인이 필요합니다.
Tech Stack
App
- Flutter
- Dart
- Dio
- WebSocket
Backend
- REST API
- WebSocket
- Database
- External FX Data API
MVP
달러물림 v0.1은 하나의 질문을 검증하기 위해 만들어집니다.
USD/KRW 환율이 크게 움직였을 때 사람들이 이곳에 모여 대화하는가?

따라서 초기 버전에서는 USD/KRW 하나에만 집중하며,
다중 채팅방이나 다른 통화 커뮤니티 등은 제공하지 않습니다.
Project Status
Currently in development.
v0.1 — MVP
