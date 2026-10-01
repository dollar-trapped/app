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
    await tester.enterText(find.byType(TextField).at(0), 'user@example.com');
    await tester.enterText(find.byType(TextField).at(1), 'password123');
    await tester.enterText(find.byType(TextField).at(2), '달러');
    for (final label in ['[필수] 이용약관 동의', '[필수] 개인정보 수집·이용 동의']) {
      await tester.ensureVisible(find.text(label));
      await tester.tap(find.text(label));
      await tester.pump();
    }
    await tester.ensureVisible(find.text('가입하고 이메일 인증'));
    await tester.tap(find.text('가입하고 이메일 인증'));
    await tester.pumpAndSettle();
    expect(find.text('메일함을 확인해주세요.'), findsOneWidget);
    await tester.tap(find.text('‹'));
    await tester.pumpAndSettle();
    expect(find.byType(TextField), findsNWidgets(3));
    expect(
      tester.widget<TextField>(find.byType(TextField).first).controller!.text,
      'user@example.com',
    );
    expect(tester.widget<Checkbox>(find.byType(Checkbox).first).value, isTrue);
  });

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
          find.widgetWithText(ElevatedButton, login ? '로그인' : '가입하고 이메일 인증'),
        );
        expect(tester.takeException(), isNull);
      },
    );
  }
}
