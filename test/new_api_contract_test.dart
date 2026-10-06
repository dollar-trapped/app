import 'dart:convert';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dollar_trapped/core/auth/token_store.dart';
import 'package:dollar_trapped/core/network/api_client.dart';
import 'package:dollar_trapped/features/shared/data/dollar_api.dart';
import 'package:dollar_trapped/features/cosmetics/models/cosmetic_models.dart';

const itemJson = {
  'id': 'color-1',
  'type': 'NAME_COLOR',
  'displayName': '파랑',
  'rarity': 'COMMON',
  'appearance': {'nameColor': '#4477CC'},
  'isDrawable': true,
};
const equipmentJson = {
  'nameColorId': 'color-1',
  'nameFontId': null,
  'nameBackgroundId': null,
  'version': 7,
};
void main() {
  test(
    'signup sends explicit bundled consent versions without client timestamps',
    () async {
      final dio = Dio(BaseOptions(baseUrl: 'https://example.test'));
      RequestOptions? captured;
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            captured = options;
            handler.reject(DioException(requestOptions: options));
          },
        ),
      );
      final tokens = _Tokens();
      final api = DollarApi.withDependencies(
        ApiClient(tokens, dio: dio),
        tokens,
      );
      await expectLater(
        api.signUp(
          email: 'test@example.com',
          password: 'password1234',
          nickname: 'test',
          verificationToken: 'verified',
          termsVersion: '2026-09-29',
          privacyVersion: '2026-09-29',
        ),
        throwsException,
      );
      expect(captured!.path, '/auth/signup');
      expect(captured!.data, {
        'email': 'test@example.com',
        'password': 'password1234',
        'nickname': 'test',
        'verificationToken': 'verified',
        'termsVersion': '2026-09-29',
        'privacyVersion': '2026-09-29',
      });
    },
  );

  test('chip exchange uses operationId and server balances', () async {
    final adapter = _Adapter();
    final dio = Dio(BaseOptions(baseUrl: 'https://example.test'))
      ..httpClientAdapter = adapter;
    final tokens = _Tokens();
    final api = DollarApi.withDependencies(ApiClient(tokens, dio: dio), tokens);
    final result = await api.exchangeChips('operation-1');
    expect(adapter.requests.single.path, '/gacha/chip-exchanges');
    expect(adapter.requests.single.method, 'POST');
    expect(adapter.requests.single.data, {'operationId': 'operation-1'});
    expect(result.chipsAfter, 22);
    expect(result.ticketsAfter, 1);
  });
  for (final reason in ['SPAM', 'ABUSE', 'OTHER']) {
    test('report $reason sends detail under the description field', () async {
      final adapter = _Adapter();
      final dio = Dio(BaseOptions(baseUrl: 'https://example.test'))
        ..httpClientAdapter = adapter;
      final store = _Tokens();
      final api = DollarApi.withDependencies(ApiClient(store, dio: dio), store);
      final receipt = await api.reportMessage(
        'message-1',
        reason: reason,
        description: '신고 상세 이유',
      );
      final request = adapter.requests.single;
      expect(request.method, 'POST');
      expect(request.path, '/messages/message-1/reports');
      expect(request.data, {'reason': reason, 'description': '신고 상세 이유'});
      expect(receipt.messageId, 'message-1');
    });
  }
  for (final reason in ['SPAM', 'ABUSE']) {
    test('report $reason omits an absent optional description', () async {
      final adapter = _Adapter();
      final dio = Dio(BaseOptions(baseUrl: 'https://example.test'))
        ..httpClientAdapter = adapter;
      final store = _Tokens();
      final api = DollarApi.withDependencies(ApiClient(store, dio: dio), store);
      await api.reportMessage('message-1', reason: reason);
      expect(adapter.requests.single.data, {'reason': reason});
    });
  }

  test(
    'password endpoints are unauthenticated and use reset-specific token fields',
    () async {
      final adapter = _Adapter();
      final dio = Dio(BaseOptions(baseUrl: 'https://example.test'))
        ..httpClientAdapter = adapter;
      final store = _Tokens();
      final api = DollarApi.withDependencies(ApiClient(store, dio: dio), store);
      await api.requestPasswordReset('user@example.com');
      final token = await api.verifyPasswordReset('user@example.com', '123456');
      await api.resetPassword(token, 'new-password');
      expect(adapter.requests.map((r) => r.path), [
        '/auth/password/verification',
        '/auth/password/verify',
        '/auth/password/reset',
      ]);
      expect(
        adapter.requests.every((r) => r.headers['Authorization'] == null),
        isTrue,
      );
      expect(adapter.requests[1].data, {
        'email': 'user@example.com',
        'code': '123456',
      });
      expect(adapter.requests[2].data, {
        'passwordResetToken': 'reset-token',
        'newPassword': 'new-password',
      });
    },
  );
  test(
    'cosmetics, draw and reward requests preserve server IDs, null slots and version',
    () async {
      final adapter = _Adapter();
      final dio = Dio(BaseOptions(baseUrl: 'https://example.test'))
        ..httpClientAdapter = adapter;
      final store = _Tokens();
      final api = DollarApi.withDependencies(ApiClient(store, dio: dio), store);
      final catalog = await api.getCosmeticCatalog();
      expect(catalog.probabilities['COMMON'], 7000);
      final mine = await api.getMyCosmetics();
      expect(mine.tickets, 2);
      expect(mine.items.single.id, 'color-1');
      await api.equipCosmetics(
        const CosmeticEquipment(version: 7, fontId: 'font-1'),
      );
      final equip = adapter.requests.last;
      expect(equip.method, 'PUT');
      expect(equip.data, {
        'nameColorId': null,
        'nameFontId': 'font-1',
        'nameBackgroundId': null,
        'expectedVersion': 7,
      });
      final draw = await api.drawCosmetic('draw-key');
      expect(draw.duplicate, isTrue);
      expect(draw.chipsGranted, 1);
      expect(adapter.requests.last.data, {'drawRequestId': 'draw-key'});
      final session = await api.createAdRewardSession('session-key');
      expect(session.customData, 'signed-data');
      expect(adapter.requests.last.data, {'sessionRequestId': 'session-key'});
      await api.getAdRewardSession(session.id);
      expect(adapter.requests.last.path, '/ad-reward-sessions/session-1');
      expect(adapter.requests.where((r) => r.path.contains('ssv')), isEmpty);
    },
  );
  test(
    'batch draw uses deployed contract and validates all ten results',
    () async {
      final adapter = _Adapter();
      final dio = Dio(BaseOptions(baseUrl: 'https://example.test'))
        ..httpClientAdapter = adapter;
      final store = _Tokens();
      final api = DollarApi.withDependencies(ApiClient(store, dio: dio), store);
      final batch = await api.drawCosmeticBatch('batch-key');
      expect(adapter.requests.single.path, '/gacha/batch-draws');
      expect(adapter.requests.single.method, 'POST');
      expect(adapter.requests.single.data, {
        'drawRequestId': 'batch-key',
        'count': 10,
      });
      expect(batch.results, hasLength(10));
      expect(batch.ticketsAfter, 0);
      expect(batch.chipsAfter, 15);
      expect(batch.results.last.duplicate, isTrue);
      expect(batch.results.last.chipsGranted, 1);
      expect(
        batch.results.last.item.appearance['styleToken'],
        'golden_shimmer',
      );
      adapter.batchResponse = {
        'drawRequestId': 'batch-key',
        'count': 10,
        'results': [],
        'drawEntitlementCountAfter': 0,
        'dollarChipBalanceAfter': 15,
      };
      await expectLater(
        api.drawCosmeticBatch('batch-key'),
        throwsFormatException,
      );
      adapter.batchResponse = null;
      adapter.batchIdOverride = 'wrong-batch';
      await expectLater(
        api.drawCosmeticBatch('batch-key'),
        throwsFormatException,
      );
    },
  );
}

class _Tokens implements TokenStore {
  @override
  Future<void> clear() async {}
  @override
  Future<TokenPair?> read() async => TokenPair(
    accessToken: 'access',
    refreshToken: 'refresh',
    accessExpiresAt: DateTime.utc(2099),
    refreshExpiresAt: DateTime.utc(2099),
  );
  @override
  Future<void> write(TokenPair tokens) async {}
}

class _Adapter implements HttpClientAdapter {
  final requests = <RequestOptions>[];
  Map<String, dynamic>? batchResponse;
  String? batchIdOverride;
  @override
  Future<ResponseBody> fetch(
    RequestOptions o,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(o);
    final Object data = switch (o.path) {
      '/messages/message-1/reports' => {
        'id': 'report-1',
        'messageId': 'message-1',
        'status': 'RECEIVED',
        'createdAt': '2026-09-26T00:00:00Z',
      },
      '/auth/password/verify' => {
        'passwordResetToken': 'reset-token',
        'expiresAt': '2099-01-01T00:00:00Z',
      },
      '/cosmetics' => {
        'items': [itemJson],
        'drawPolicy': {
          'rarityProbabilityBps': {'COMMON': 7000},
          'duplicateSettingTokenAmount': 1,
        },
      },
      '/users/me/cosmetics' => {
        'items': [
          {'cosmetic': itemJson},
        ],
        'equipment': equipmentJson,
        'drawEntitlementCount': 2,
        'settingToken': 3,
      },
      '/users/me/cosmetic-equipment' => equipmentJson,
      '/gacha/chip-exchanges' => {
        'dollarChipBalanceAfter': 22,
        'drawEntitlementBalance': 1,
      },
      '/gacha/batch-draws' =>
        batchResponse ??
            {
              'drawRequestId':
                  batchIdOverride ?? (o.data as Map)['drawRequestId'],
              'count': 10,
              'drawEntitlementCountAfter': 0,
              'dollarChipBalanceAfter': 15,
              'results': List.generate(
                10,
                (i) => {
                  'cosmetic': {
                    ...itemJson,
                    'appearance': {
                      'nameColor': null,
                      'styleToken': 'golden_shimmer',
                    },
                  },
                  'outcome': 'DUPLICATE',
                  'dollarChipGranted': 1,
                  'drawEntitlementCountAfter': 9 - i,
                },
              ),
            },
      '/gacha/draws' => {
        'cosmetic': itemJson,
        'outcome': 'DUPLICATE',
        'settingTokenGranted': 1,
        'drawEntitlementCountAfter': 1,
      },
      '/ad-reward-sessions' || '/ad-reward-sessions/session-1' => {
        'id': 'session-1',
        'status': 'PENDING',
        'customData': 'signed-data',
        'adEventExpiresAt': '2099-01-01T00:00:00Z',
      },
      _ => {},
    };
    return ResponseBody.fromString(
      jsonEncode(data),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}
