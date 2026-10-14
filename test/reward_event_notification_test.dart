import 'dart:convert';
import 'dart:async';

import 'package:dio/dio.dart';
import 'package:dollar_trapped/core/auth/reward_event_claim.dart';
import 'package:dollar_trapped/core/auth/reward_event_notifications.dart';
import 'package:dollar_trapped/core/auth/token_store.dart';
import 'package:dollar_trapped/core/network/api_client.dart';
import 'package:dollar_trapped/features/gacha/widgets/reward_event_listener.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:dollar_trapped/features/home/screens/usd_krw_page.dart';
import 'package:dollar_trapped/features/shared/data/mock_dollar_repository.dart';
import 'package:dollar_trapped/features/legal/consent_versions.dart';
import 'package:flutter_test/flutter_test.dart';

const _granted = {
  'grantedAmount': 3,
  'drawEntitlementBalance': 12,
  'events': [
    {'eventId': 'today', 'name': '오늘의 뽑기권', 'outcome': 'GRANTED', 'amount': 3},
    {
      'eventId': 'old',
      'name': '지난 보상',
      'outcome': 'ALREADY_CLAIMED',
      'amount': 5,
    },
  ],
};

void main() {
  test(
    'contention omissions are normal and a later call can grant the skipped event',
    () async {
      final logs = <String>[];
      final originalPrint = debugPrint;
      debugPrint = (message, {wrapWidth}) {
        if (message != null) logs.add(message);
      };
      addTearDown(() => debugPrint = originalPrint);
      final response = <String, dynamic>{
        'grantedAmount': 0,
        'drawEntitlementBalance': 8,
        'events': [],
      };
      final client = _client(response);
      final notifications = RewardEventNotifications();
      await claimRewardEvents(client, notifications: notifications);
      expect(notifications.take(), isNull);
      expect(logs, isEmpty);

      response.addAll({
        'grantedAmount': 1,
        'drawEntitlementBalance': 9,
        'events': [
          {
            'eventId': 'unlocked',
            'name': '먼저 지급된 이벤트',
            'outcome': 'GRANTED',
            'amount': 1,
          },
        ],
      });
      await claimRewardEvents(client, notifications: notifications);
      expect(notifications.take()?.events.single.id, 'unlocked');
      expect(logs, isEmpty);

      response.addAll({
        'grantedAmount': 2,
        'drawEntitlementBalance': 11,
        'events': [
          {
            'eventId': 'unlocked',
            'name': '먼저 지급된 이벤트',
            'outcome': 'ALREADY_CLAIMED',
            'amount': 1,
          },
          {
            'eventId': 'previously-locked',
            'name': '나중에 지급된 이벤트',
            'outcome': 'GRANTED',
            'amount': 2,
          },
        ],
      });
      await claimRewardEvents(client, notifications: notifications);
      final granted = notifications.take();
      expect(granted?.amount, 2);
      expect(granted?.events.single.id, 'previously-locked');
      expect(logs, isEmpty);
    },
  );

  testWidgets('startup claim waits for a screen and displays only new grants', (
    tester,
  ) async {
    final notifications = RewardEventNotifications();
    await tester.runAsync(
      () => claimRewardEvents(_client(_granted), notifications: notifications),
    );
    await tester.pumpWidget(_app(notifications));
    await tester.pumpAndSettle();
    expect(find.text('뽑기권 3장 획득!'), findsOneWidget);
    expect(find.text('오늘의 뽑기권 · 3장'), findsOneWidget);
    expect(find.textContaining('지난 보상'), findsNothing);
    expect(find.text('현재 보유 뽑기권 12장'), findsOneWidget);
    await tester.tap(find.text('확인'));
    await tester.pumpAndSettle();
    await tester.pumpWidget(
      _app(notifications, key: const ValueKey('remount')),
    );
    await tester.pumpAndSettle();
    expect(find.text('뽑기권 3장 획득!'), findsNothing);
  });

  testWidgets('home waits for consent check before showing startup reward', (
    tester,
  ) async {
    final notifications = RewardEventNotifications();
    await tester.runAsync(
      () => claimRewardEvents(_client(_granted), notifications: notifications),
    );
    final repository = _ConsentRepository();
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: notifications,
        child: MaterialApp(
          home: UsdKrwPage(repository: repository, checkConsent: true),
        ),
      ),
    );
    await tester.pump();
    expect(find.text('뽑기권 3장 획득!'), findsNothing);
    repository.consent.complete({
      'terms': {'reagreementRequired': false},
      'privacy': {'reagreementRequired': false},
    });
    await tester.pumpAndSettle();
    expect(find.text('뽑기권 3장 획득!'), findsOneWidget);
  });

  testWidgets(
    'login navigation and completing both consents preserve the reward popup',
    (tester) async {
      final notifications = RewardEventNotifications();
      await tester.runAsync(
        () =>
            claimRewardEvents(_client(_granted), notifications: notifications),
      );
      final repository = _ReconsentRepository();
      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: notifications,
          child: MaterialApp(
            home: Builder(
              builder: (context) => Scaffold(
                body: TextButton(
                  onPressed: () => Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute<void>(
                      builder: (_) => UsdKrwPage(
                        repository: repository,
                        checkConsent: true,
                      ),
                    ),
                    (_) => false,
                  ),
                  child: const Text('로그인 완료'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('로그인 완료'));
      await tester.pumpAndSettle();
      expect(find.text('뽑기권 3장 획득!'), findsNothing);
      await tester.tap(find.byType(CheckboxListTile).first);
      await tester.tap(find.byType(CheckboxListTile).last);
      await tester.pump();
      await tester.tap(find.text('동의하고 계속하기'));
      await tester.pumpAndSettle();
      expect(find.text('뽑기권 3장 획득!'), findsOneWidget);
    },
  );

  testWidgets('claim after screen mounts displays a reward', (tester) async {
    final notifications = RewardEventNotifications();
    await tester.pumpWidget(_app(notifications));
    await tester.runAsync(
      () => claimRewardEvents(_client(_granted), notifications: notifications),
    );
    await tester.pumpAndSettle();
    expect(find.text('뽑기권 3장 획득!'), findsOneWidget);
  });

  for (final response in [
    {
      'grantedAmount': 0,
      'drawEntitlementBalance': 12,
      'events': _granted['events'],
    },
    {'grantedAmount': 3, 'drawEntitlementBalance': 12, 'events': []},
    {
      'grantedAmount': 9,
      'drawEntitlementBalance': 12,
      'events': _granted['events'],
    },
  ]) {
    testWidgets(
      'zero or inconsistent reward data never announces a grant: $response',
      (tester) async {
        final notifications = RewardEventNotifications();
        await tester.runAsync(
          () => claimRewardEvents(
            _client(response),
            notifications: notifications,
          ),
        );
        await tester.pumpWidget(_app(notifications));
        await tester.pumpAndSettle();
        expect(find.byType(Dialog), findsNothing);
      },
    );
  }

  testWidgets(
    'server outage leaves the screen usable without a success popup',
    (tester) async {
      final notifications = RewardEventNotifications();
      await tester.runAsync(
        () => claimRewardEvents(
          _client({}, status: 503),
          notifications: notifications,
        ),
      );
      await tester.pumpWidget(_app(notifications));
      await tester.pumpAndSettle();
      expect(find.text('홈'), findsOneWidget);
      expect(find.byType(Dialog), findsNothing);
    },
  );
}

Widget _app(RewardEventNotifications notifications, {Key? key}) => MaterialApp(
  home: RewardEventListener(
    key: key,
    notifications: notifications,
    child: const Scaffold(body: Text('홈')),
  ),
);

ApiClient _client(Map<String, dynamic> response, {int status = 200}) {
  final dio = Dio(
    BaseOptions(
      baseUrl: 'https://example.test',
      contentType: Headers.jsonContentType,
    ),
  );
  dio.httpClientAdapter = _Adapter(response, status);
  return ApiClient(_Tokens(), dio: dio);
}

class _Tokens implements TokenStore {
  @override
  Future<TokenPair?> read() async => TokenPair(
    accessToken: 'access',
    refreshToken: 'refresh',
    accessExpiresAt: DateTime.utc(2030),
    refreshExpiresAt: DateTime.utc(2030),
  );
  @override
  Future<void> clear() async {}
  @override
  Future<void> write(TokenPair tokens) async {}
}

class _Adapter implements HttpClientAdapter {
  _Adapter(this.response, this.status);
  final Map<String, dynamic> response;
  final int status;
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    expect(options.path, '/reward-events/claims');
    expect(options.method, 'POST');
    expect(options.data, isNull);
    expect(options.queryParameters, isEmpty);
    expect(options.uri.query, isEmpty);
    final bodyBytes =
        await requestStream?.fold<int>(
          0,
          (size, chunk) => size + chunk.length,
        ) ??
        0;
    expect(bodyBytes, 0, reason: 'claims must send no HTTP body');
    expect(options.headers['Authorization'], 'Bearer access');
    return ResponseBody.fromString(
      jsonEncode(response),
      status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

class _ConsentRepository extends MockDollarRepository {
  final consent = Completer<Map<String, dynamic>>();
  @override
  Future<Map<String, dynamic>> getTermsAgreements() => consent.future;
}

class _ReconsentRepository extends MockDollarRepository {
  bool terms = false, privacy = false;
  @override
  Future<Map<String, dynamic>> getTermsAgreements() async => {
    'terms': {
      'reagreementRequired': !terms,
      'currentVersion': bundledTermsVersion,
    },
    'privacy': {
      'reagreementRequired': !privacy,
      'currentVersion': bundledPrivacyVersion,
    },
  };
  @override
  Future<void> agreeToDocument(String document, String version) async {
    if (document == 'SERVICE') terms = true;
    if (document == 'PRIVACY') privacy = true;
  }
}
