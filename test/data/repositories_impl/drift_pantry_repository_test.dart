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

  group('FIFO deduction', () {
    Future<void> stockChicken() async {
      await repo.addPurchase(
        proteinType: ProteinType.chicken,
        grams: 500,
        addedOn: DateTime(2026, 10, 14),
      );
      await repo.addPurchase(
        proteinType: ProteinType.chicken,
        grams: 300,
        addedOn: DateTime(2026, 10, 10),
      );
      await repo.addPurchase(proteinType: ProteinType.beef, grams: 900);
    }

    test('uses the oldest batches first, one movement per batch', () async {
      await stockChicken();

      final movements = await repo.deductFifo(
        proteinType: ProteinType.chicken,
        grams: 600,
        reason: MovementReason.adjust,
      );

      expect(movements.map((m) => m.deltaGrams), [-300, -300]);
      expect(movements.every((m) => m.reason == MovementReason.adjust), isTrue);
      final chicken = await repo.getBatches(proteinType: ProteinType.chicken);
      expect(chicken.single.quantityGrams, 200);
      expect(chicken.single.addedOn, DateTime(2026, 10, 14));
      expect(
        (await repo.getBatches(proteinType: ProteinType.beef))
            .single
            .quantityGrams,
        900,
      );
    });

    test('links cooked movements to the dinner', () async {
      await stockChicken();
      await db.customStatement(
        'INSERT INTO dinner_log (id, date, day_type, source, created_at) '
        "VALUES (5, '2026-10-15', 'nonVegDay', 'home', 0)",
      );

      await repo.deductFifo(
        proteinType: ProteinType.chicken,
        grams: 400,
        reason: MovementReason.cooked,
        dinnerLogId: 5,
      );

      expect(await repo.getMovements(dinnerLogId: 5), hasLength(2));
    });

    test('refuses to deduct more than is in stock, changing nothing', () async {
      await stockChicken();

      await expectLater(
        repo.deductFifo(
          proteinType: ProteinType.chicken,
          grams: 801,
          reason: MovementReason.cooked,
        ),
        throwsStateError,
      );
      expect(
        (await repo.getBatches(proteinType: ProteinType.chicken))
            .map((b) => b.quantityGrams),
        [300, 500],
      );
    });

    test('rejects zero or negative amounts', () {
      expect(
        () => repo.deductFifo(
          proteinType: ProteinType.chicken,
          grams: 0,
          reason: MovementReason.adjust,
        ),
        throwsArgumentError,
      );
    });
  });

  group('quick add', () {
    test('tops up the newest batch', () async {
      await repo.addPurchase(
        proteinType: ProteinType.mince,
        grams: 500,
        addedOn: DateTime(2026, 10),
      );
      final newest = await repo.addPurchase(
        proteinType: ProteinType.mince,
        grams: 500,
        addedOn: DateTime(2026, 10, 12),
      );

      final movement = await repo.addToNewest(
        proteinType: ProteinType.mince,
        grams: 250,
      );

      expect(movement.pantryItemId, newest.id);
      expect(movement.reason, MovementReason.adjust);
      expect((await repo.getBatches()).map((b) => b.quantityGrams), [500, 750]);
    });

    test('starts a new batch when there is none', () async {
      final movement = await repo.addToNewest(
        proteinType: ProteinType.beef,
        grams: 250,
      );

      final batch = (await repo.getBatches()).single;
      expect(batch.id, movement.pantryItemId);
      expect(batch.quantityGrams, 250);
      expect(batch.addedOn, now);
      expect(movement.reason, MovementReason.adjust);
    });
  });

  group('revert (undo)', () {
    test('restores deducted stock and forgets the movements', () async {
      await repo.addPurchase(proteinType: ProteinType.chicken, grams: 500);
      final movements = await repo.deductFifo(
        proteinType: ProteinType.chicken,
        grams: 200,
        reason: MovementReason.cooked,
      );

      await repo.revertMovements(movements.map((m) => m.id));

      expect((await repo.getBatches()).single.quantityGrams, 500);
      expect(await repo.getMovements(), hasLength(1));
    });

    test('undoing a purchase removes the batch entirely', () async {
      final batch = await repo.addPurchase(
        proteinType: ProteinType.mutton,
        grams: 1000,
      );
      final purchase = await repo.getMovements(pantryItemId: batch.id);

      await repo.revertMovements(purchase.map((m) => m.id));

      expect(await repo.getBatches(), isEmpty);
      expect(await repo.getMovements(), isEmpty);
      final rows = await db.select(db.pantryItems).get();
      expect(rows, isEmpty);
    });
  });
}
