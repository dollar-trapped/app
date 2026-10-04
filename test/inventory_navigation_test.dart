import 'package:dollar_trapped/features/cosmetics/models/cosmetic_models.dart';
import 'package:dollar_trapped/features/inventory/data/cosmetic_inventory_repository.dart';
import 'package:dollar_trapped/features/inventory/screens/owned_cosmetics_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('inventory only needs ownership API and delegated navigation', (
    tester,
  ) async {
    final repository = _InventoryOnly();
    var opened = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: OwnedCosmeticsPage(
          repository: repository,
          nickname: '달러',
          onOpenGacha: (_) async {
            opened++;
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('닉네임 뽑기'));
    await tester.tap(find.text('닉네임 뽑기'));
    await tester.pumpAndSettle();
    expect(opened, 1);
    expect(repository.loads, 2);
    expect(tester.takeException(), isNull);
  });
}

class _InventoryOnly implements CosmeticInventoryRepository {
  int loads = 0;
  @override
  Future<CosmeticInventory> getMyCosmetics() async {
    loads++;
    return const CosmeticInventory(
      items: [],
      equipment: CosmeticEquipment(version: 1),
      tickets: 0,
      dollarChips: 0,
    );
  }

  @override
  Future<CosmeticEquipment> equipCosmetics(CosmeticEquipment equipment) async =>
      equipment;
}
