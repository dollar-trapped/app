import '../../cosmetics/models/cosmetic_models.dart';

class CosmeticCatalog {
  const CosmeticCatalog({
    required this.items,
    required this.probabilities,
    this.chipExchangeCost = 10,
    this.withinRaritySelection = 'UNIFORM',
    this.duplicateChipRewards = const {'COMMON': 1, 'RARE': 3, 'SPECIAL': 5},
  });
  final int chipExchangeCost;
  final String withinRaritySelection;
  final Map<String, int> duplicateChipRewards;
  // These are the server's currently enabled cosmetic slots, not UI filters.
  List<CosmeticItem> get drawableItems => items
      .where(
        (item) =>
            item.drawable &&
            const {
              'NAME_COLOR',
              'NAME_FONT',
              'NAME_BACKGROUND',
            }.contains(item.type),
      )
      .toList();

  double? itemProbabilityPercent(CosmeticItem item) {
    if (withinRaritySelection != 'UNIFORM' ||
        !drawableItems.any((i) => i.id == item.id)) {
      return null;
    }
    final count = drawableItems.where((i) => i.rarity == item.rarity).length;
    final bps = probabilities[item.rarity];
    return bps == null || count == 0 ? null : bps / 100 / count;
  }

  final List<CosmeticItem> items;
  final Map<String, int> probabilities;
  factory CosmeticCatalog.fromJson(JsonMap j) => CosmeticCatalog(
    items: (j['items'] as List)
        .map((e) => CosmeticItem.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList(),
    withinRaritySelection:
        j['drawPolicy']['withinRaritySelection'] as String? ?? 'UNIFORM',
    duplicateChipRewards: j['drawPolicy']['duplicateChipReward'] is Map
        ? (j['drawPolicy']['duplicateChipReward'] as Map).map(
            (key, value) =>
                MapEntry((key as String).toUpperCase(), (value as num).toInt()),
          )
        : const {'COMMON': 1, 'RARE': 3, 'SPECIAL': 5},
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

class CosmeticBatchDraw {
  CosmeticBatchDraw({
    required this.requestId,
    required this.count,
    required List<CosmeticDraw> results,
    required this.ticketsAfter,
    required this.chipsAfter,
  }) : results = List.unmodifiable(results) {
    if (count <= 0 || results.length != count) {
      throw const FormatException('Batch draw result count does not match');
    }
  }

  final String requestId;
  final int count, ticketsAfter, chipsAfter;
  final List<CosmeticDraw> results;

  factory CosmeticBatchDraw.fromJson(JsonMap json) => CosmeticBatchDraw(
    requestId: json['drawRequestId'] as String,
    count: (json['count'] as num).toInt(),
    results: (json['results'] as List)
        .map((value) => CosmeticDraw.fromJson(JsonMap.from(value as Map)))
        .toList(),
    ticketsAfter: (json['drawEntitlementCountAfter'] as num).toInt(),
    chipsAfter: (json['dollarChipBalanceAfter'] as num).toInt(),
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
