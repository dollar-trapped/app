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

/// Appearance and rarity captured when a message was sent; never reclassified.
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
        appearance: {
          key: value[property],
          if (value['styleToken'] != null) 'styleToken': value['styleToken'],
        },
      );
    }

    return MessageCosmetics(
      color: slot('nameColor', 'NAME_COLOR', 'color'),
      font: slot('nameFont', 'NAME_FONT', 'font'),
      background: slot('nameBackground', 'NAME_BACKGROUND', 'background'),
    );
  }
}
