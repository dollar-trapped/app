import 'package:dollar_trapped/features/attendance/preview/attendance_preview_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

// Render review images only; run explicitly with --update-goldens.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    await (FontLoader(
      'Noto Sans KR',
    )..addFont(rootBundle.load('assets/fonts/NotoSansKR.ttf'))).load();
    await (FontLoader(
      'MaterialIcons',
    )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
  });
  for (final round in [1, 7]) {
    testWidgets('capture attendance round $round', (tester) async {
      tester.view.physicalSize = const Size(390, 920);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            fontFamily: 'Noto Sans KR',
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF008A29),
            ),
            useMaterial3: true,
          ),
          home: AttendancePreviewPage(initialRound: round),
        ),
      );
      await tester.pump(const Duration(milliseconds: 800));
      await tester.pumpAndSettle();
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('../local-archive/attendance-board-$round.png'),
      );
      await tester.ensureVisible(find.text('보상 확인'));
      await tester.tap(find.text('보상 확인'));
      await tester.pumpAndSettle();
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('../local-archive/attendance-reward-$round.png'),
      );
    });
  }
}
