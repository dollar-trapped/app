import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dollar_trapped/core/moderation/moderation_dialog.dart';
import 'package:dollar_trapped/core/moderation/moderation_status.dart';

void main() {
  testWidgets(
    'confirmed warning survives remount and is scoped by user and warning',
    (tester) async {
      FlutterSecureStorage.setMockInitialValues({});
      Future<void> open(String user, String id) async {
        await tester.pumpWidget(const SizedBox());
        await tester.pumpWidget(
          MaterialApp(
            home: Builder(
              builder: (context) {
                return TextButton(
                  onPressed: () => showModerationDialog(
                    context,
                    ModerationNotice(
                      id: id,
                      type: 'WARNING',
                      message: '테스트 경고',
                    ),
                    userId: user,
                  ),
                  child: const Text('열기'),
                );
              },
            ),
          ),
        );
        await tester.tap(find.text('열기'));
        await tester.pumpAndSettle();
      }

      await open('user-a', 'warning-1');
      expect(find.text('운영 경고'), findsOneWidget);
      await tester.tap(find.text('확인'));
      await tester.pumpAndSettle();
      await open('user-a', 'warning-1');
      expect(find.text('운영 경고'), findsNothing);
      await open('user-a', 'warning-2');
      expect(find.text('운영 경고'), findsOneWidget);
      await tester.tap(find.text('확인'));
      await tester.pumpAndSettle();
      await open('user-b', 'warning-1');
      expect(find.text('운영 경고'), findsOneWidget);
    },
  );
}
