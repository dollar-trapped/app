import '../../cosmetics/models/cosmetic_models.dart';

/// Ownership and equipment only: no draw, reward or advertising dependency.
abstract interface class CosmeticInventoryRepository {
  Future<CosmeticInventory> getMyCosmetics();
  Future<CosmeticEquipment> equipCosmetics(CosmeticEquipment equipment);
}
