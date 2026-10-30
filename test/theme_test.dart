import 'package:dollar_trapped/app.dart';
import 'package:dollar_trapped/core/theme/app_colors.dart';
import 'package:dollar_trapped/core/theme/app_theme.dart';
import 'package:dollar_trapped/core/theme/theme_controller.dart';
import 'package:dollar_trapped/features/chat/widgets/chat_message_bubble.dart';
import 'package:dollar_trapped/features/cosmetics/models/cosmetic_models.dart';
import 'package:dollar_trapped/features/cosmetics/widgets/server_cosmetic_preview.dart';
import 'package:dollar_trapped/features/gacha/screens/live_gacha_page.dart';
import 'package:dollar_trapped/features/profile/screens/my_page.dart';
import 'package:dollar_trapped/features/profile/screens/settings_page.dart';
import 'package:dollar_trapped/features/shared/data/dollar_repository.dart';
import 'package:dollar_trapped/features/shared/data/mock_dollar_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

void main() {
  setUp(() => FlutterSecureStorage.setMockInitialValues({}));

  test(
    'theme choice is restored across controller instances in both directions',
    () async {
      final first = ThemeController();
      await first.load();
      expect(first.mode, ThemeMode.light);
      await first.setDarkMode(true);
      final restored = ThemeController();
      await restored.load();
      expect(restored.mode, ThemeMode.dark);
      await restored.setDarkMode(false);
      final restarted = ThemeController();
      await restarted.load();
      expect(restarted.mode, ThemeMode.light);
      first.dispose();
      restored.dispose();
      restarted.dispose();
    },
  );

  test(
    'unavailable storage keeps the app usable and failed writes roll back',
    () async {
      final controller = ThemeController(storage: _FailingStorage());
      await controller.load();
      expect(controller.mode, ThemeMode.light);
      await expectLater(controller.setDarkMode(true), throwsStateError);
      expect(controller.mode, ThemeMode.light);
      expect(controller.saving, isFalse);
      controller.dispose();
    },
  );

  testWidgets(
    'settings changes the current route and all main pages immediately',
    (tester) async {
      final controller = ThemeController();
      final repository = MockDollarRepository();
      await controller.load();
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        Provider<DollarRepository>.value(
          value: repository,
          child: DollarTrappedApp(themeController: controller),
        ),
      );
      await tester.tap(find.text('비회원으로 둘러보기'));
      await tester.pumpAndSettle();
      final pages = tester.widget<PageView>(find.byType(PageView));
      pages.controller!.jumpToPage(0);
      await tester.pumpAndSettle();
      await tester.tap(find.text('설정'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('다크모드'));
      await tester.pumpAndSettle();
      expect(controller.isDark, isTrue);
      expect(find.byType(SettingsPage), findsOneWidget);
      expect(
        Theme.of(tester.element(find.text('다크모드'))).brightness,
        Brightness.dark,
      );
      expect(
        tester
            .widget<SwitchListTile>(find.byKey(const Key('dark-mode-switch')))
            .value,
        isTrue,
      );
      expect(
        tester.widget<Scaffold>(find.byType(Scaffold).last).backgroundColor,
        AppColors.dark.background,
      );
      await tester.tap(find.text('‹').last);
      await tester.pumpAndSettle();
      expect(
        tester.widget<Text>(find.text('내 채팅 이름')).style!.color,
        AppColors.dark.muted,
      );
      pages.controller!.jumpToPage(1);
      await tester.pumpAndSettle();
      expect(
        tester.widget<Text>(find.text('최근 1개월')).style!.color,
        AppColors.dark.ink,
      );
      pages.controller!.jumpToPage(2);
      await tester.pumpAndSettle();
      expect(
        tester.widget<Text>(find.text('USD방')).style!.color,
        AppColors.dark.ink,
      );
      final bubble = find.byType(ChatMessageBubble).first;
      final message = tester.widget<ChatMessageBubble>(bubble).message;
      expect(
        tester
            .widget<Text>(
              find.descendant(of: bubble, matching: find.text(message)),
            )
            .style!
            .color,
        AppColors.dark.ink,
      );
      pages.controller!.jumpToPage(0);
      await tester.pumpAndSettle();
      await tester.tap(find.text('설정'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('다크모드'));
      await tester.pumpAndSettle();
      expect(controller.isDark, isFalse);
      expect(
        Theme.of(tester.element(find.text('다크모드'))).brightness,
        Brightness.light,
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets('restored dark mode is used on the first app frame', (
    tester,
  ) async {
    FlutterSecureStorage.setMockInitialValues({
      ThemeController.storageKey: 'dark',
    });
    final controller = ThemeController();
    await controller.load();
    addTearDown(controller.dispose);
    await tester.pumpWidget(DollarTrappedApp(themeController: controller));
    expect(
      Theme.of(tester.element(find.text('로그인'))).brightness,
      Brightness.dark,
    );
    expect(
      tester.widget<MaterialApp>(find.byType(MaterialApp)).themeMode,
      ThemeMode.dark,
    );
  });

  testWidgets(
    'dark profile, settings and gacha support narrow screens and large text',
    (tester) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final repository = MockDollarRepository();
      for (final page in <Widget>[
        MyPage(repository: repository, onBack: () {}),
        SettingsPage(repository: repository, email: 'dollar@example.com'),
        LiveGachaPage(repository: repository, nickname: '아주긴닉네임을사용해요'),
      ]) {
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.dark,
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: TextScaler.linear(1.5)),
              child: child!,
            ),
            home: page,
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        if (page is SettingsPage) {
          await tester.ensureVisible(find.text('회원 탈퇴'));
        } else if (page is LiveGachaPage) {
          await tester.ensureVisible(find.text('내 아이템 · 꾸미기'));
        } else {
          await tester.ensureVisible(find.text('내 달러 포지션'));
        }
        expect(tester.takeException(), isNull);
      }
    },
  );

  testWidgets(
    'default nickname follows dark theme while equipped colors stay intact',
    (tester) async {
      const custom = CosmeticItem(
        id: 'color',
        type: 'NAME_COLOR',
        name: '파랑',
        rarity: 'COMMON',
        appearance: {'nameColor': '#4477CC'},
      );
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark,
          home: const Scaffold(
            body: Column(
              children: [
                ServerCosmeticNickname(nickname: '기본 이름'),
                ServerCosmeticNickname(nickname: '장착 이름', color: custom),
              ],
            ),
          ),
        ),
      );
      expect(
        tester.widget<Text>(find.text('기본 이름')).style!.color,
        AppColors.dark.ink,
      );
      expect(
        tester.widget<Text>(find.text('장착 이름')).style!.color,
        const Color(0xFF4477CC),
      );
    },
  );
}

class _FailingStorage extends FlutterSecureStorage {
  @override
  Future<String?> read({
    required String key,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async => throw StateError('storage unavailable');
  @override
  Future<void> write({
    required String key,
    required String? value,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async => throw StateError('storage unavailable');
}
