import '../../cosmetics/models/cosmetic_models.dart';

int _balance(JsonMap json, String key) {
  final value = json[key];
  if (value is! int || value < 0) throw FormatException('Invalid $key');
  return value;
}

class WishTicketOption {
  const WishTicketOption({required this.item, required this.owned});
  final CosmeticItem item;
  final bool owned;
  bool get selectable =>
      !owned &&
      item.drawable &&
      item.rarity == 'SPECIAL' &&
      const {'NAME_COLOR', 'NAME_FONT', 'NAME_BACKGROUND'}.contains(item.type);
  factory WishTicketOption.fromJson(JsonMap json) {
    if (json['isOwned'] is! bool) {
      throw const FormatException('Missing ownership');
    }
    return WishTicketOption(
      item: CosmeticItem.fromJson(JsonMap.from(json['cosmetic'] as Map)),
      owned: json['isOwned'] as bool,
    );
  }
}

class WishTicketState {
  const WishTicketState({
    required this.enabled,
    required this.chips,
    required this.tickets,
    required this.options,
    this.exchangeCost = 100,
  });
  final bool enabled;
  final int chips, tickets, exchangeCost;
  final List<WishTicketOption> options;
  // This client supports the agreed 100-chip policy only.
  bool get supported => enabled && exchangeCost == 100;
  factory WishTicketState.fromJson(JsonMap json) {
    if (json['enabled'] is! bool) {
      throw const FormatException('Missing feature status');
    }
    return WishTicketState(
      enabled: json['enabled'] as bool,
      chips: _balance(json, 'dollarChipBalance'),
      tickets: _balance(json, 'wishTicketCount'),
      exchangeCost: _balance(json, 'exchangeCost'),
      options: (json['items'] as List)
          .map((v) => WishTicketOption.fromJson(JsonMap.from(v as Map)))
          .toList(),
    );
  }
}

class WishTicketReceipt {
  const WishTicketReceipt({
    required this.operationId,
    required this.chips,
    required this.tickets,
    this.item,
  });
  final String operationId;
  final int chips, tickets;
  final CosmeticItem? item;
  factory WishTicketReceipt.fromJson(JsonMap json) => WishTicketReceipt(
    operationId: json['operationId'] as String,
    chips: _balance(json, 'dollarChipBalanceAfter'),
    tickets: _balance(json, 'wishTicketCountAfter'),
    item: json['cosmetic'] == null
        ? null
        : CosmeticItem.fromJson(JsonMap.from(json['cosmetic'] as Map)),
  );
}
