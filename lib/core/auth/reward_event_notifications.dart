import 'dart:collection';

import 'package:flutter/foundation.dart';

class GrantedRewardEvent {
  const GrantedRewardEvent({
    required this.id,
    required this.name,
    required this.amount,
  });
  final String id;
  final String name;
  final int amount;
}

/// A receipt from the server, never a client-calculated entitlement.
class RewardEventReceipt {
  const RewardEventReceipt({
    required this.amount,
    required this.balance,
    required this.events,
  });
  final int amount;
  final int balance;
  final List<GrantedRewardEvent> events;

  static RewardEventReceipt? fromJson(Map<String, dynamic> json) {
    final amount = json['grantedAmount'];
    if (amount is! int || amount <= 0) return null;
    final balance = json['drawEntitlementBalance'];
    final rawEvents = json['events'];
    if (balance is! int || balance < 0 || rawEvents is! List) {
      throw const FormatException('Invalid reward receipt');
    }
    final events = <GrantedRewardEvent>[];
    for (final raw in rawEvents) {
      if (raw is! Map) throw const FormatException('Invalid reward event');
      if (raw['outcome'] != 'GRANTED') continue;
      final id = raw['eventId'], name = raw['name'], count = raw['amount'];
      if (id is! String ||
          id.isEmpty ||
          name is! String ||
          name.trim().isEmpty ||
          count is! int ||
          count <= 0) {
        throw const FormatException('Invalid granted event');
      }
      events.add(GrantedRewardEvent(id: id, name: name, amount: count));
    }
    if (events.isEmpty ||
        events.fold<int>(0, (sum, event) => sum + event.amount) != amount) {
      throw const FormatException('Inconsistent reward receipt');
    }
    return RewardEventReceipt(
      amount: amount,
      balance: balance,
      events: List.unmodifiable(events),
    );
  }
}

/// Buffers startup/auth rewards until an authenticated screen is mounted.
class RewardEventNotifications extends ChangeNotifier {
  final _pending = Queue<RewardEventReceipt>();

  void add(RewardEventReceipt receipt) {
    _pending.add(receipt);
    notifyListeners();
  }

  RewardEventReceipt? take() =>
      _pending.isEmpty ? null : _pending.removeFirst();

  void clear() => _pending.clear();
}
