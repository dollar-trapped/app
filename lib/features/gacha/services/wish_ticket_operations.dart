import 'dart:convert';
import '../../../core/network/api_exception.dart';
import '../../shared/data/dollar_repository.dart';
import '../data/wish_ticket_models.dart';
import 'pending_draw_store.dart';
import 'request_id.dart';

class PendingWishOperation {
  const PendingWishOperation(this.id, {this.cosmeticId});
  final String id;
  final String? cosmeticId;
  bool get exchange => cosmeticId == null;
  String encode() => jsonEncode({
    'operationId': id,
    'kind': exchange ? 'EXCHANGE' : 'REDEEM',
    'cosmeticId': cosmeticId,
  });
  factory PendingWishOperation.decode(String value) {
    final json = jsonDecode(value) as Map;
    if (json['operationId'] is! String ||
        (json['operationId'] as String).isEmpty ||
        !['EXCHANGE', 'REDEEM'].contains(json['kind']) ||
        (json['kind'] == 'REDEEM' &&
            (json['cosmeticId'] is! String ||
                (json['cosmeticId'] as String).isEmpty)) ||
        (json['kind'] == 'EXCHANGE' && json['cosmeticId'] != null)) {
      throw const FormatException('Invalid saved wish operation');
    }
    return PendingWishOperation(
      json['operationId'] as String,
      cosmeticId: json['cosmeticId'] as String?,
    );
  }
}

/// One durable operation per account. A redemption stores its selected item too.
class WishTicketOperations {
  WishTicketOperations(this.repository, this.store, this.userId);
  final DollarRepository repository;
  final PendingDrawStore store;
  final String userId;
  PendingWishOperation? pending;
  bool ready = false, _running = false;
  Future<void> restore() async {
    ready = false;
    final saved = await store.read(userId);
    pending = saved == null ? null : PendingWishOperation.decode(saved);
    ready = true;
  }

  Future<WishTicketReceipt> execute({String? cosmeticId}) async {
    if (!ready || _running) throw StateError('Operation unavailable');
    _running = true;
    try {
      final operation =
          pending ??
          PendingWishOperation(newRequestId(), cosmeticId: cosmeticId);
      await store.write(userId, operation.encode());
      pending = operation;
      final receipt = operation.exchange
          ? await repository.exchangeWishTicket(operation.id)
          : await repository.redeemWishTicket(
              operation.id,
              operation.cosmeticId!,
            );
      if (receipt.operationId != operation.id ||
          (operation.exchange
              ? receipt.item != null
              : receipt.item?.id != operation.cosmeticId ||
                    receipt.item?.rarity != 'SPECIAL')) {
        throw const FormatException('Unexpected wish receipt');
      }
      await store.clear(userId);
      pending = null;
      return receipt;
    } on ApiException catch (error) {
      // Confirmed server contract: these codes guarantee NO mutation committed.
      if (const {
        'INSUFFICIENT_DOLLAR_CHIP',
        'INSUFFICIENT_WISH_TICKET',
        'COSMETIC_ALREADY_OWNED',
        'COSMETIC_NOT_SELECTABLE',
        'WISH_TICKETS_DISABLED',
      }.contains(error.code)) {
        await store.clear(userId);
        pending = null;
      }
      rethrow;
    } finally {
      _running = false;
    }
  }
}
