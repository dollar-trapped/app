import 'dart:async';

import 'package:dollar_trapped/features/chat/widgets/chat_guidelines.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  // Existing feature tests represent returning users. First-entry tests reset
  // this preference explicitly so the introduction is exercised separately.
  FlutterSecureStorage.setMockInitialValues({
    ChatGuidelinesStore.storageKey: 'true',
  });
  await testMain();
}
