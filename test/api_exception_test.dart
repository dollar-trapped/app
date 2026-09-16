import 'package:flutter_test/flutter_test.dart';

import 'package:dollar_trapped/core/network/api_exception.dart';

void main() {
  test('formats field-level API validation details for the user', () {
    final error = ApiException.fromResponse(
      statusCode: 400,
      data: {
        'error': {
          'code': 'BAD_REQUEST',
          'message': '입력값을 확인해 주세요.',
          'details': [
            {'field': 'verificationToken', 'reason': '인증 토큰이 만료되었습니다.'},
            {'field': 'password', 'reason': '8자 이상이어야 합니다.'},
          ],
        },
      },
    );

    expect(
      error.userMessage,
      'verificationToken: 인증 토큰이 만료되었습니다.\npassword: 8자 이상이어야 합니다.',
    );
  });
}
