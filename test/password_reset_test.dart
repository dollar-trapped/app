import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dollar_trapped/features/auth/screens/login_page.dart';
import 'package:dollar_trapped/features/shared/data/mock_dollar_repository.dart';
import 'package:dollar_trapped/core/network/api_exception.dart';

void main() {
  testWidgets(
    'reset flow validates code, passes token and returns to login without auto-login',
    (tester) async {
      final repo = _Repo();
      await tester.pumpWidget(MaterialApp(home: LoginPage(repository: repo)));
      await tester.tap(find.text('비밀번호 재설정'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).first, 'user@example.com');
      await tester.tap(find.text('인증 코드 발송'));
      await tester.pumpAndSettle();
      expect(repo.sentEmail, 'user@example.com');
      expect(find.text('재전송 (60초)'), findsOneWidget);
      expect(find.textContaining('발송 후 5분'), findsOneWidget);
      await tester.enterText(find.byType(TextField).last, '000000');
      await tester.tap(find.text('인증 코드 확인'));
      await tester.pumpAndSettle();
      expect(find.text('잘못된 코드'), findsOneWidget);
      expect(repo.newPassword, isNull);
      await tester.enterText(find.byType(TextField).last, '123456');
      await tester.tap(find.text('인증 코드 확인'));
      await tester.pumpAndSettle();
      expect(find.textContaining('코드 확인 후 10분'), findsOneWidget);
      await tester.enterText(find.byType(TextField).at(1), 'new-password');
      await tester.enterText(find.byType(TextField).at(2), 'different');
      await tester.tap(find.text('비밀번호 변경'));
      await tester.pumpAndSettle();
      expect(repo.newPassword, isNull);
      await tester.enterText(find.byType(TextField).at(2), 'new-password');
      repo.rejectPassword = true;
      await tester.tap(find.text('비밀번호 변경'));
      await tester.pumpAndSettle();
      expect(find.text('비밀번호 규칙을 확인해 주세요.'), findsOneWidget);
      expect(repo.token, 'verified-reset-token');
      expect(repo.newPassword, isNull);
      repo.rejectPassword = false;
      await tester.tap(find.text('비밀번호 변경'));
      await tester.pumpAndSettle();
      expect(repo.token, 'verified-reset-token');
      expect(repo.newPassword, 'new-password');
      expect(find.byType(LoginPage), findsOneWidget);
      expect(find.textContaining('새 비밀번호로 로그인'), findsOneWidget);
    },
  );
}

class _Repo extends MockDollarRepository {
  String? sentEmail, token, newPassword;
  bool rejectPassword = false;
  @override
  Future<void> requestPasswordReset(String email) async {
    sentEmail = email;
  }

  @override
  Future<String> verifyPasswordReset(String email, String code) async {
    if (code != '123456') {
      throw const ApiException(
        statusCode: 400,
        code: 'INVALID',
        message: '잘못된 코드',
      );
    }
    return 'verified-reset-token';
  }

  @override
  Future<void> resetPassword(String resetToken, String password) async {
    token = resetToken;
    if (rejectPassword) {
      throw const ApiException(
        statusCode: 400,
        code: 'VALIDATION_ERROR',
        message: '비밀번호 규칙을 확인해 주세요.',
      );
    }
    newPassword = password;
  }
}
