typedef JsonMap = Map<String, dynamic>;

class CosmeticItem {
  const CosmeticItem({
    required this.id,
    required this.type,
    required this.name,
    required this.rarity,
    required this.appearance,
    this.drawable = false,
  });
  final String id, type, name, rarity;
  final JsonMap appearance;
  final bool drawable;
  factory CosmeticItem.fromJson(JsonMap j) => CosmeticItem(
    id: j['id'] as String,
    type: j['type'] as String,
    name: j['displayName'] as String,
    rarity: j['rarity'] as String,
    appearance: Map<String, dynamic>.from(j['appearance'] as Map),
    drawable: j['isDrawable'] == true,
  );
}

class CosmeticEquipment {
  const CosmeticEquipment({
    this.colorId,
    this.fontId,
    this.backgroundId,
    required this.version,
  });
  final String? colorId, fontId, backgroundId;
  final int version;
  factory CosmeticEquipment.fromJson(JsonMap j) => CosmeticEquipment(
    colorId: j['nameColorId'] as String?,
    fontId: j['nameFontId'] as String?,
    backgroundId: j['nameBackgroundId'] as String?,
    version: (j['version'] as num).toInt(),
  );
  JsonMap toRequest() => {
    'nameColorId': colorId,
    'nameFontId': fontId,
    'nameBackgroundId': backgroundId,
    'expectedVersion': version,
  };
}

class CosmeticInventory {
  const CosmeticInventory({
    required this.items,
    required this.equipment,
    required this.tickets,
    required this.dollarChips,
  });
  final List<CosmeticItem> items;
  final CosmeticEquipment equipment;
  final int tickets, dollarChips;
  factory CosmeticInventory.fromJson(JsonMap j) => CosmeticInventory(
    items: (j['items'] as List)
        .map(
          (e) => CosmeticItem.fromJson(
            Map<String, dynamic>.from(e['cosmetic'] as Map),
          ),
        )
        .toList(),
    equipment: CosmeticEquipment.fromJson(
      Map<String, dynamic>.from(j['equipment'] as Map),
    ),
    tickets: (j['drawEntitlementCount'] as num).toInt(),
    dollarChips: ((j['dollarChip'] ?? j['settingToken']) as num).toInt(),
  );
}

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

/// Appearance snapshot sent with each message; does not change chat transport.
class MessageCosmetics {
  const MessageCosmetics({this.color, this.font, this.background});
  final CosmeticItem? color, font, background;
  factory MessageCosmetics.fromJson(JsonMap j) {
    CosmeticItem? slot(String key, String type, String property) {
      final value = j[key];
      if (value is! Map) return null;
      return CosmeticItem(
        id: value['id'] as String? ?? '',
        type: type,
        name: '',
        rarity: value['rarity'] as String? ?? 'COMMON',
        appearance: {key: value[property]},
      );
    }

    return MessageCosmetics(
      color: slot('nameColor', 'NAME_COLOR', 'color'),
      font: slot('nameFont', 'NAME_FONT', 'font'),
      background: slot('nameBackground', 'NAME_BACKGROUND', 'background'),
    );
  }
}

class ChipExchange {
  const ChipExchange({required this.chipsAfter, required this.ticketsAfter});
  final int chipsAfter, ticketsAfter;
  factory ChipExchange.fromJson(JsonMap j) => ChipExchange(
    chipsAfter: (j['dollarChipBalanceAfter'] as num).toInt(),
    ticketsAfter: (j['drawEntitlementBalance'] as num).toInt(),
  );
}
