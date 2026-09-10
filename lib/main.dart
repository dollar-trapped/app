import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'core/auth/token_store.dart';
import 'core/network/api_client.dart';
import 'features/shared/data/dollar_api.dart';
import 'features/shared/data/dollar_repository.dart';
import 'features/shared/data/mock_dollar_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized(); //runApp 전에 Flutter 서비스 사용을 위해 바인딩 초기화
  try {
    await dotenv.load(fileName: '.env');
  } catch (_) {
    // CI and production builds may use --dart-define instead of a local .env.
  }
  SystemChrome.setSystemUIOverlayStyle(
    //상태바/시스템 내비게이션 바 스타일 설정
    const SystemUiOverlayStyle(
      //OS 시스템 UI의 색상/아이콘 밝기 설정
      statusBarColor: Color(0xFFFFFFFF),
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Color(0xFFFFFFFF),
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );
  runApp(
    MultiProvider(
      providers: [
        Provider<TokenStore>(create: (_) => SecureTokenStore()),
        Provider<DollarRepository>(
          create: (context) {
            if (const bool.fromEnvironment('USE_MOCK_REPOSITORY')) {
              return MockDollarRepository();
            }
            final tokenStore = context.read<TokenStore>();
            return DollarApi.withDependencies(
              ApiClient(tokenStore),
              tokenStore,
            );
          },
        ),
      ],
      child: const DollarTrappedApp(),
    ),
  );
}
