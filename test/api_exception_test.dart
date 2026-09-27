import 'package:flutter_test/flutter_test.dart';

import 'package:dollar_trapped/core/network/api_exception.dart';

void main() {
  test('suppresses generic prompts while preserving auth messages', () {
    for (final message in ['입력값을 확인해주세요', '입력값을 확인해 주세요.']) {
      final error = ApiException(
        statusCode: 400,
        code: 'VALIDATION_ERROR',
        message: message,
      );
      expect(error.actionableUserMessage, isEmpty);
      expect(error.userMessage, message);
    }
  });

  test('keeps specific reasons and filters generic details', () {
    const error = ApiException(
      statusCode: 400,
      code: 'VALIDATION_ERROR',
      message: '입력값을 확인해주세요',
      details: [
        ApiErrorDetail(field: '', reason: '입력값을 확인해 주세요.'),
        ApiErrorDetail(field: 'amount', reason: '잔액이 부족합니다.'),
      ],
    );
    expect(error.actionableUserMessage, 'amount: 잔액이 부족합니다.');
    const specific = ApiException(
      statusCode: 400,
      code: 'BAD_REQUEST',
      message: '잔액이 부족합니다.',
    );
    expect(specific.actionableUserMessage, '잔액이 부족합니다.');
  });

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
