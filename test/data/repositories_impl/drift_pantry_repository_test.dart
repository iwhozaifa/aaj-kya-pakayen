import 'package:aaj_kya_pakayen/data/db/app_database.dart';
import 'package:aaj_kya_pakayen/data/repositories_impl/drift_pantry_repository.dart';
import 'package:aaj_kya_pakayen/domain/enums/movement_reason.dart';
import 'package:aaj_kya_pakayen/domain/enums/protein_type.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/test_database.dart';

void main() {
  late AppDatabase db;
  late DriftPantryRepository repo;
  final now = DateTime(2026, 10, 15, 18);

  setUp(() {
    db = newTestDatabase();
    repo = DriftPantryRepository(db, clock: () => now);
  });
  tearDown(() => db.close());

  test('a purchase creates a batch and a purchase movement', () async {
    final batch = await repo.addPurchase(
      proteinType: ProteinType.chicken,
      grams: 1000,
    );

    expect(batch.proteinType, ProteinType.chicken);
    expect(batch.quantityGrams, 1000);
    expect(batch.addedOn, now);
    final movements = await repo.getMovements();
    expect(movements.single.pantryItemId, batch.id);
    expect(movements.single.deltaGrams, 1000);
    expect(movements.single.reason, MovementReason.purchase);
  });

  test('rejects purchases of zero or less', () {
    expect(
      () => repo.addPurchase(proteinType: ProteinType.beef, grams: 0),
      throwsArgumentError,
    );
  });

  test(
    'lists batches with stock, oldest first, optionally by protein',
    () async {
      final newer = await repo.addPurchase(
        proteinType: ProteinType.chicken,
        grams: 500,
        addedOn: DateTime(2026, 10, 14),
      );
      final older = await repo.addPurchase(
        proteinType: ProteinType.chicken,
        grams: 500,
        addedOn: DateTime(2026, 10, 10),
      );
      final mince = await repo.addPurchase(
        proteinType: ProteinType.mince,
        grams: 250,
        addedOn: DateTime(2026, 10, 12),
      );
      final empty = await repo.addPurchase(
        proteinType: ProteinType.beef,
        grams: 300,
      );
      await repo.applyMovement(
        pantryItemId: empty.id,
        deltaGrams: -300,
        reason: MovementReason.discard,
      );

      expect((await repo.getBatches()).map((b) => b.id), [
        older.id,
        mince.id,
        newer.id,
      ]);
      expect(
        (await repo.getBatches(proteinType: ProteinType.chicken))
            .map((b) => b.id),
        [older.id, newer.id],
      );
    },
  );

  test('a movement changes the batch and is recorded', () async {
    final batch = await repo.addPurchase(
      proteinType: ProteinType.mutton,
      grams: 1000,
    );
    await db.customStatement(
      'INSERT INTO dinner_log (id, date, day_type, source, created_at) '
      "VALUES (7, '2026-10-15', 'nonVegDay', 'home', 0)",
    );

    final movement = await repo.applyMovement(
      pantryItemId: batch.id,
      deltaGrams: -800,
      reason: MovementReason.cooked,
      dinnerLogId: 7,
    );

    expect(movement.deltaGrams, -800);
    expect(movement.dinnerLogId, 7);
    expect((await repo.getBatches()).single.quantityGrams, 200);
    expect(await repo.getMovements(dinnerLogId: 7), [movement]);
  });

  test('never lets a batch go below zero', () async {
    final batch = await repo.addPurchase(
      proteinType: ProteinType.mince,
      grams: 100,
    );

    await expectLater(
      repo.applyMovement(
        pantryItemId: batch.id,
        deltaGrams: -101,
        reason: MovementReason.adjust,
      ),
      throwsStateError,
    );
    expect((await repo.getBatches()).single.quantityGrams, 100);
    expect(await repo.getMovements(), hasLength(1));
  });

  test('watchBatches emits on change', () async {
    final stream = repo.watchBatches();
    expect(await stream.first, isEmpty);
    await repo.addPurchase(proteinType: ProteinType.beef, grams: 500);
    expect((await stream.first).single.quantityGrams, 500);
  });
}
