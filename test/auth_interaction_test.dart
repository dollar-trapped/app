import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dollar_trapped/features/auth/screens/sign_up_page.dart';
import 'package:dollar_trapped/features/auth/screens/login_page.dart';
import 'package:dollar_trapped/features/auth/widgets/agreement_row.dart';
import 'package:dollar_trapped/features/shared/data/mock_dollar_repository.dart';

void main() {
  testWidgets('agreement label and checkbox toggle once; view never toggles', (
    tester,
  ) async {
    var checked = false;
    var changes = 0;
    var views = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) => AgreementRow(
              label: '동의 문구',
              value: checked,
              onChanged: (value) => setState(() {
                checked = value;
                changes++;
              }),
              onView: () => views++,
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('동의 문구'));
    await tester.pump();
    expect(checked, isTrue);
    expect(changes, 1);
    await tester.tapAt(tester.getCenter(find.byType(Checkbox)));
    await tester.pump();
    expect(checked, isFalse);
    expect(changes, 2);
    await tester.tap(find.text('보기'));
    expect(views, 1);
    expect(changes, 2);
  });

  testWidgets('verification back preserves fields and explicit agreements', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(home: SignUpPage(repository: MockDollarRepository())),
    );
    for (final value in ['user@example.com', 'password123', '달러']) {
      expect(find.byType(TextField), findsOneWidget);
      await tester.enterText(find.byType(TextField), value);
      await tester.testTextInput.receiveAction(TextInputAction.next);
      await tester.pumpAndSettle();
    }
    await tester.tap(find.text('동의하고 이메일 인증'));
    await tester.pump();
    expect(find.text('필수 약관에 모두 동의해 주세요.'), findsOneWidget);
    for (final label in ['[필수] 이용약관 동의', '[필수] 개인정보 수집·이용 동의']) {
      await tester.ensureVisible(find.text(label));
      await tester.tap(find.text(label));
      await tester.pump();
    }
    await tester.ensureVisible(find.text('동의하고 이메일 인증'));
    await tester.tap(find.text('동의하고 이메일 인증'));
    await tester.pumpAndSettle();
    expect(find.text('메일함을 확인해주세요.'), findsOneWidget);
    await tester.tap(find.text('‹'));
    await tester.pumpAndSettle();
    expect(tester.widget<Checkbox>(find.byType(Checkbox).first).value, isTrue);
    for (final value in ['달러', 'password123', 'user@example.com']) {
      await tester.tap(find.text('‹'));
      await tester.pumpAndSettle();
      expect(find.byType(TextField), findsOneWidget);
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        value,
      );
    }
  });

  testWidgets(
    'invalid email and password stay on their step with an explanation',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(home: SignUpPage(repository: MockDollarRepository())),
      );
      await tester.enterText(find.byType(TextField), 'invalid');
      await tester.tap(find.text('다음'));
      await tester.pumpAndSettle();
      expect(find.text('올바른 이메일 주소를 입력해 주세요.'), findsOneWidget);
      expect(find.text('1 / 5 · 이메일'), findsOneWidget);
      await tester.enterText(find.byType(TextField), 'user@example.com');
      await tester.tap(find.text('다음'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), '12345678');
      await tester.testTextInput.receiveAction(TextInputAction.next);
      await tester.pumpAndSettle();
      expect(find.text('비밀번호는 10자 이상 입력해 주세요. (현재 8자)'), findsOneWidget);
      expect(find.text('2 / 5 · 비밀번호'), findsOneWidget);
      await tester.enterText(find.byType(TextField), 'password123');
      await tester.tap(find.text('다음'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('다음'));
      await tester.pumpAndSettle();
      expect(find.text('닉네임을 입력해 주세요.'), findsOneWidget);
      expect(find.text('3 / 5 · 닉네임'), findsOneWidget);
    },
  );

  for (final login in [false, true]) {
    testWidgets(
      '${login ? "login" : "signup"} fits narrow screen and keyboard',
      (tester) async {
        tester.view.physicalSize = const Size(320, 600);
        tester.view.devicePixelRatio = 1;
        tester.view.viewInsets = const FakeViewPadding(bottom: 260);
        addTearDown(tester.view.reset);
        await tester.pumpWidget(
          MaterialApp(
            home: login
                ? LoginPage(repository: MockDollarRepository())
                : SignUpPage(repository: MockDollarRepository()),
          ),
        );
        await tester.pumpAndSettle();
        await tester.ensureVisible(
          find.widgetWithText(ElevatedButton, login ? '로그인' : '다음'),
        );
        expect(tester.takeException(), isNull);
        if (!login) {
          for (final value in ['user@example.com', 'password123', '달러']) {
            await tester.enterText(find.byType(TextField), value);
            await tester.testTextInput.receiveAction(TextInputAction.next);
            await tester.pumpAndSettle();
            expect(tester.takeException(), isNull);
          }
          for (final label in ['[필수] 이용약관 동의', '[필수] 개인정보 수집·이용 동의']) {
            await tester.ensureVisible(find.text(label));
            await tester.tap(find.text(label));
            await tester.pump();
          }
          await tester.ensureVisible(find.text('동의하고 이메일 인증'));
          await tester.tap(find.text('동의하고 이메일 인증'));
          await tester.pumpAndSettle();
          await tester.ensureVisible(find.text('인증하고 가입 완료'));
          expect(tester.takeException(), isNull);
        }
      },
    );
  }
}
