import 'package:aaj_kya_pakayen/domain/entities/dinner_log_entry.dart';
import 'package:aaj_kya_pakayen/domain/entities/dish_pairing.dart';
import 'package:aaj_kya_pakayen/domain/entities/pantry_batch.dart';
import 'package:aaj_kya_pakayen/domain/entities/pantry_movement.dart';
import 'package:aaj_kya_pakayen/domain/enums/day_type.dart';
import 'package:aaj_kya_pakayen/domain/enums/dinner_source.dart';
import 'package:aaj_kya_pakayen/domain/enums/movement_reason.dart';
import 'package:aaj_kya_pakayen/domain/enums/protein_type.dart';
import 'package:flutter_test/flutter_test.dart';

// JSON is the future sync wire format (docs/ARCHITECTURE.md).
void main() {
  final at = DateTime(2026, 10, 15, 18);

  test('DinnerLogEntry', () {
    final entry = DinnerLogEntry(
      id: 3,
      date: DateTime(2026, 10, 15),
      dayType: DayType.nonVegDay,
      source: DinnerSource.home,
      mainDishId: 1,
      sideDishId: 2,
      createdAt: at,
    );
    expect(DinnerLogEntry.fromJson(entry.toJson()), entry);
  });

  test('DishPairing', () {
    const pairing = DishPairing(mainDishId: 1, sideDishId: 2, priority: 1);
    expect(DishPairing.fromJson(pairing.toJson()), pairing);
  });

  test('PantryBatch', () {
    final batch = PantryBatch(
      id: 1,
      proteinType: ProteinType.mince,
      quantityGrams: 500,
      addedOn: at,
      updatedAt: at,
    );
    expect(PantryBatch.fromJson(batch.toJson()), batch);
  });

  test('PantryMovement', () {
    final movement = PantryMovement(
      id: 1,
      pantryItemId: 1,
      deltaGrams: -400,
      reason: MovementReason.cooked,
      dinnerLogId: 3,
      createdAt: at,
    );
    expect(PantryMovement.fromJson(movement.toJson()), movement);
  });
}
