import 'dart:async';

import 'package:dollar_trapped/core/moderation/moderation_status.dart';
import 'package:dollar_trapped/core/theme/app_theme.dart';
import 'package:dollar_trapped/features/chat/screens/usd_room_page.dart';
import 'package:dollar_trapped/features/chat/widgets/chat_guidelines.dart';
import 'package:dollar_trapped/features/chat/widgets/chat_guidelines_listener.dart';
import 'package:dollar_trapped/features/shared/data/api_models.dart';
import 'package:dollar_trapped/features/shared/data/mock_dollar_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _room(
  MockDollarRepository repo, {
  bool active = true,
  bool dark = false,
  double scale = 1,
}) => MaterialApp(
  theme: dark ? AppTheme.dark : AppTheme.light,
  builder: (context, child) => MediaQuery(
    data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(scale)),
    child: child!,
  ),
  home: UsdRoomPage(repository: repo, isActive: active, onRateBarTap: () {}),
);

void main() {
  setUp(() => FlutterSecureStorage.setMockInitialValues({}));

  testWidgets(
    'first actual room entry shows supplied copy and confirmation survives remount',
    (tester) async {
      final repo = MockDollarRepository();
      await tester.pumpWidget(_room(repo, active: false));
      await tester.pumpAndSettle();
      expect(find.byType(ChatGuidelinesDialog), findsNothing);
      await tester.pumpWidget(_room(repo));
      await tester.pumpAndSettle();
      expect(find.byType(ChatGuidelinesDialog), findsOneWidget);
      for (final paragraph in const [
        '달러물림은 자유로운 의견 교환을 존중합니다.',
        '다만 타인에 대한 반복적인 괴롭힘, 협박, 개인정보 유포, 도배 및 불법 콘텐츠 게시 등의 행위는 금지됩니다.',
        '위반 시 운영 정책에 따라 메시지 삭제, 채팅 이용 제한 또는 계정 정지 등의 조치가 이루어질 수 있습니다.',
        '이용 중 부적절한 메시지는 신고 기능을 통해 알려주세요.',
      ]) {
        expect(find.text(paragraph), findsOneWidget);
      }
      await tester.tap(find.text('확인'));
      await tester.pumpAndSettle();
      expect(await const ChatGuidelinesStore().hasSeen(), isTrue);
      await tester.pumpWidget(_room(repo, active: false));
      await tester.pumpAndSettle();
      await tester.pumpWidget(_room(repo));
      await tester.pumpAndSettle();
      expect(find.byType(ChatGuidelinesDialog), findsNothing);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpWidget(_room(repo));
      await tester.pumpAndSettle();
      expect(find.byType(ChatGuidelinesDialog), findsNothing);
    },
  );

  testWidgets('returning users can reopen the same guide from the room menu', (
    tester,
  ) async {
    await const ChatGuidelinesStore().acknowledge();
    await tester.pumpWidget(_room(MockDollarRepository()));
    await tester.pumpAndSettle();
    expect(find.byType(ChatGuidelinesDialog), findsNothing);
    await tester.tap(find.byTooltip('채팅방 메뉴'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('채팅 이용 안내'));
    await tester.pumpAndSettle();
    expect(find.byType(ChatGuidelinesDialog), findsOneWidget);
    await tester.tap(find.text('확인'));
    await tester.pumpAndSettle();
    expect(find.byType(ChatGuidelinesDialog), findsNothing);
    expect(find.text('USD방'), findsOneWidget);
  });

  testWidgets(
    'dismissing without confirmation does not persist an acknowledgement',
    (tester) async {
      await tester.pumpWidget(_room(MockDollarRepository()));
      await tester.pumpAndSettle();
      await tester.tapAt(const Offset(4, 4));
      await tester.pumpAndSettle();
      expect(find.byType(ChatGuidelinesDialog), findsNothing);
      expect(await const ChatGuidelinesStore().hasSeen(), isFalse);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpWidget(_room(MockDollarRepository()));
      await tester.pumpAndSettle();
      expect(find.byType(ChatGuidelinesDialog), findsOneWidget);
    },
  );

  testWidgets(
    'dark and light guide remain scrollable with enlarged text on small screens',
    (tester) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      for (final dark in [false, true]) {
        FlutterSecureStorage.setMockInitialValues({});
        await tester.pumpWidget(
          _room(MockDollarRepository(), dark: dark, scale: 1.5),
        );
        await tester.pumpAndSettle();
        expect(find.byType(ChatGuidelinesDialog), findsOneWidget);
        await tester.ensureVisible(find.text(chatGuidelinesParagraphs.last));
        expect(tester.takeException(), isNull);
        await tester.tap(find.text('확인'));
        await tester.pumpAndSettle();
        expect(find.byTooltip('채팅방 메뉴').hitTestable(), findsOneWidget);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
      }
    },
  );

  testWidgets('guide waits for an existing route instead of stacking over it', (
    tester,
  ) async {
    final enabled = ValueNotifier(false);
    addTearDown(enabled.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: ValueListenableBuilder<bool>(
          valueListenable: enabled,
          builder: (context, active, _) => ChatGuidelinesListener(
            enabled: active,
            child: Scaffold(
              body: TextButton(
                onPressed: () => showDialog<void>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('다른 안내'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('닫기'),
                      ),
                    ],
                  ),
                ),
                child: const Text('다른 안내 열기'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('다른 안내 열기'));
    await tester.pumpAndSettle();
    enabled.value = true;
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));
    expect(find.byType(ChatGuidelinesDialog), findsNothing);
    expect(find.text('다른 안내'), findsOneWidget);
    await tester.tap(find.text('닫기'));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pumpAndSettle();
    expect(find.byType(ChatGuidelinesDialog), findsOneWidget);
  });

  testWidgets(
    'leaving while the stored preference is pending cannot show a late guide',
    (tester) async {
      final store = _PendingStore();
      await tester.pumpWidget(
        MaterialApp(
          home: ChatGuidelinesListener(
            enabled: true,
            store: store,
            child: const Scaffold(body: Text('채팅방')),
          ),
        ),
      );
      await tester.pump();
      await tester.pumpWidget(const SizedBox.shrink());
      store.result.complete(false);
      await tester.pumpAndSettle();
      expect(find.byType(ChatGuidelinesDialog), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('first-entry guide waits until the app resumes', (tester) async {
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pumpWidget(
      const MaterialApp(
        home: ChatGuidelinesListener(
          enabled: true,
          child: Scaffold(body: Text('채팅방')),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(ChatGuidelinesDialog), findsNothing);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();
    expect(find.byType(ChatGuidelinesDialog), findsOneWidget);
  });

  testWidgets('removing the room also dismisses its introduction dialog', (
    tester,
  ) async {
    final present = ValueNotifier(true);
    addTearDown(present.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: ValueListenableBuilder<bool>(
          valueListenable: present,
          builder: (_, active, _) => active
              ? const ChatGuidelinesListener(
                  enabled: true,
                  child: Scaffold(body: Text('채팅방')),
                )
              : const Scaffold(body: Text('다음 화면')),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(ChatGuidelinesDialog), findsOneWidget);
    present.value = false;
    await tester.pumpAndSettle();
    expect(find.byType(ChatGuidelinesDialog), findsNothing);
    expect(find.text('다음 화면'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'preference read failures still show an introduction once in the current room',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ChatGuidelinesListener(
            enabled: true,
            store: _ReadFailureStore(),
            child: Scaffold(body: Text('채팅방')),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(ChatGuidelinesDialog), findsOneWidget);
      await tester.tap(find.text('확인'));
      await tester.pumpAndSettle();
      await tester.pump(const Duration(seconds: 1));
      expect(find.byType(ChatGuidelinesDialog), findsNothing);
    },
  );

  testWidgets(
    'server warnings are confirmed before the first-entry guide appears',
    (tester) async {
      await tester.pumpWidget(_room(_WarningRepository()));
      await tester.pumpAndSettle();
      expect(find.text('도배를 중단해 주세요.'), findsOneWidget);
      expect(find.byType(ChatGuidelinesDialog), findsNothing);
      expect(find.byType(AlertDialog), findsOneWidget);
      await tester.tap(find.text('확인'));
      await tester.pumpAndSettle();
      expect(find.byType(ChatGuidelinesDialog), findsOneWidget);
      expect(find.byType(AlertDialog), findsOneWidget);
    },
  );
}

class _PendingStore extends ChatGuidelinesStore {
  final result = Completer<bool>();
  @override
  Future<bool> hasSeen() => result.future;
}

class _ReadFailureStore extends ChatGuidelinesStore {
  const _ReadFailureStore();
  @override
  Future<bool> hasSeen() async => throw StateError('storage unavailable');
}

class _WarningRepository extends MockDollarRepository {
  @override
  Future<User> getMe() async {
    final user = await super.getMe();
    return User(
      id: user.id,
      email: user.email,
      nickname: user.nickname,
      usdAmount: user.usdAmount,
      averageExchangeRate: user.averageExchangeRate,
      profitRate: user.profitRate,
      profitRateAsOf: user.profitRateAsOf,
      createdAt: user.createdAt,
      moderation: ModerationStatus.fromJson({
        'version': 1,
        'warnings': [
          {
            'id': 'warning-guide-test',
            'userMessage': '도배를 중단해 주세요.',
            'createdAt': '2026-10-01T00:00:00Z',
          },
        ],
      }),
    );
  }
}
