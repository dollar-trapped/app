import 'dart:convert';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dollar_trapped/core/auth/token_store.dart';
import 'package:dollar_trapped/core/network/api_client.dart';
import 'package:dollar_trapped/features/shared/data/dollar_api.dart';
import 'package:dollar_trapped/features/gacha/data/cosmetic_models.dart';

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
      expect(draw.tokensGranted, 1);
      expect(adapter.requests.last.data, {'drawRequestId': 'draw-key'});
      final session = await api.createAdRewardSession('session-key');
      expect(session.customData, 'signed-data');
      expect(adapter.requests.last.data, {'sessionRequestId': 'session-key'});
      await api.getAdRewardSession(session.id);
      expect(adapter.requests.last.path, '/ad-reward-sessions/session-1');
      expect(adapter.requests.where((r) => r.path.contains('ssv')), isEmpty);
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
  @override
  Future<ResponseBody> fetch(
    RequestOptions o,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(o);
    final Object data = switch (o.path) {
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
