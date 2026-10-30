import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'core/theme/theme_controller.dart';
import 'features/attendance/data/launch_attendance.dart';
import 'features/rewards/data/reward_grant_notices.dart';
import 'core/ads/mobile_ads_service.dart';
import 'core/auth/session_restorer.dart';
import 'core/auth/reward_event_notifications.dart';
import 'core/auth/token_store.dart';
import 'core/network/api_client.dart';
import 'features/shared/data/dollar_api.dart';
import 'features/shared/data/dollar_repository.dart';
import 'features/shared/data/mock_dollar_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized(); //runApp 전에 Flutter 서비스 사용을 위해 바인딩 초기화
  unawaited(MobileAdsService.instance.initialize());
  try {
    await dotenv.load(fileName: '.env');
  } catch (_) {
    // CI and production builds may use --dart-define instead of a local .env.
  }
  final themeController = ThemeController();
  await themeController.load();
  final tokenStore = RememberingTokenStore(SecureTokenStore());
  final apiClient = ApiClient(tokenStore);
  final grantNotices = RewardGrantNotices(apiClient);
  final attendance = LaunchAttendance(apiClient);
  final rewardNotifications = RewardEventNotifications();
  final repository = const bool.fromEnvironment('USE_MOCK_REPOSITORY')
      ? MockDollarRepository()
      : DollarApi.withDependencies(
          apiClient,
          tokenStore,
          rewardNotifications: rewardNotifications,
          grantNotices: grantNotices,
          attendance: attendance,
        );
  final initiallyAuthenticated = await SessionRestorer(
    tokenStore,
    apiClient,
    rewardNotifications: rewardNotifications,
  ).restore();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<LaunchAttendance>.value(value: attendance),
        ChangeNotifierProvider<RewardGrantNotices>.value(value: grantNotices),
        ChangeNotifierProvider<RewardEventNotifications>.value(
          value: rewardNotifications,
        ),
        Provider<TokenStore>.value(value: tokenStore),
        Provider<DollarRepository>.value(value: repository),
      ],
      child: DollarTrappedApp(
        initiallyAuthenticated: initiallyAuthenticated,
        themeController: themeController,
      ),
    ),
  );
}
