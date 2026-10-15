import 'package:aaj_kya_pakayen/domain/engine/rules/pantry_stock.dart';
import 'package:aaj_kya_pakayen/domain/enums/dish_type.dart';
import 'package:aaj_kya_pakayen/domain/enums/protein_type.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fixtures.dart';

void main() {
  final stock = PantryStock.fromBatches(
    date: today,
    batches: [
      batch(1, ProteinType.chicken, 500, addedDaysAgo: 2),
      batch(2, ProteinType.chicken, 400, addedDaysAgo: 6),
      batch(3, ProteinType.mince, 300),
      batch(4, ProteinType.beef, 0, addedDaysAgo: 20),
    ],
  );

  test('totals grams per protein across batches', () {
    expect(stock.gramsOf(ProteinType.chicken), 900);
    expect(stock.gramsOf(ProteinType.mince), 300);
    expect(stock.gramsOf(ProteinType.mutton), 0);
  });

  test('knows how long the oldest batch with stock has waited', () {
    expect(stock.oldestBatchDays(ProteinType.chicken), 6);
    expect(stock.oldestBatchDays(ProteinType.beef), isNull);
  });

  test('a meat dish is cookable when stock covers the whole household', () {
    final karahi = dish(1, type: DishType.chicken, grams: 200);
    expect(stock.canCook(karahi, householdSize: 4), isTrue); // 800 <= 900
    expect(stock.canCook(karahi, householdSize: 5), isFalse); // 1000 > 900
  });

  test('veg dishes never need stock', () {
    expect(stock.canCook(dish(2), householdSize: 10), isTrue);
  });
}
