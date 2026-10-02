import 'package:flutter/foundation.dart';

import '../network/api_client.dart';

/// 서버가 이벤트 기간·대상·중복 수령을 판정하므로 앱에서 지급량을 정하지 않습니다.
Future<void> claimRewardEvents(ApiClient client) async {
  try {
    // 본문과 요청 키가 없는 멱등 API입니다. 저장된 인증 토큰을 사용합니다.
    await client.post<Map<String, dynamic>>('/reward-events/claims');
  } catch (_) {
    // 보상 서버 장애 때문에 완료된 가입·로그인을 실패로 표시하지 않습니다.
    // 다음 로그인 또는 앱 실행 시 같은 API로 안전하게 다시 확인합니다.
    debugPrint('이벤트 보상 확인 실패: 다음 인증 시 재시도합니다.');
  }
}
