import '../../cosmetics/models/cosmetic_models.dart';

class CosmeticCatalog {
  const CosmeticCatalog({
    required this.items,
    required this.probabilities,
    this.chipExchangeCost = 10,
  });
  final int chipExchangeCost;
  final List<CosmeticItem> items;
  final Map<String, int> probabilities;
  factory CosmeticCatalog.fromJson(JsonMap j) => CosmeticCatalog(
    items: (j['items'] as List)
        .map((e) => CosmeticItem.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList(),
    chipExchangeCost:
        (j['drawPolicy']['chipExchangeCost'] as num?)?.toInt() ?? 10,
    probabilities: (j['drawPolicy']['rarityProbabilityBps'] as Map).map(
      (k, v) => MapEntry(k as String, (v as num).toInt()),
    ),
  );
}

class CosmeticDraw {
  const CosmeticDraw({
    required this.item,
    required this.duplicate,
    required this.chipsGranted,
    required this.ticketsAfter,
  });
  final CosmeticItem item;
  final bool duplicate;
  final int chipsGranted, ticketsAfter;
  factory CosmeticDraw.fromJson(JsonMap j) => CosmeticDraw(
    item: CosmeticItem.fromJson(
      Map<String, dynamic>.from(j['cosmetic'] as Map),
    ),
    duplicate: j['outcome'] == 'DUPLICATE',
    chipsGranted: ((j['dollarChipGranted'] ?? j['settingTokenGranted']) as num)
        .toInt(),
    ticketsAfter: (j['drawEntitlementCountAfter'] as num).toInt(),
  );
}

class AdRewardSession {
  const AdRewardSession({
    required this.id,
    required this.status,
    required this.customData,
    required this.expiresAt,
  });
  final String id, status, customData;
  final DateTime expiresAt;
  factory AdRewardSession.fromJson(JsonMap j) => AdRewardSession(
    id: j['id'] as String,
    status: j['status'] as String,
    customData: j['customData'] as String,
    expiresAt: DateTime.parse(j['adEventExpiresAt'] as String),
  );
}

class ChipExchange {
  const ChipExchange({required this.chipsAfter, required this.ticketsAfter});
  final int chipsAfter, ticketsAfter;
  factory ChipExchange.fromJson(JsonMap j) => ChipExchange(
    chipsAfter: (j['dollarChipBalanceAfter'] as num).toInt(),
    ticketsAfter: (j['drawEntitlementBalance'] as num).toInt(),
  );
}
