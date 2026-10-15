import 'package:aaj_kya_pakayen/core/utils/clock.dart';
import 'package:aaj_kya_pakayen/data/db/app_database.dart';
import 'package:aaj_kya_pakayen/data/providers.dart';
import 'package:aaj_kya_pakayen/domain/entities/app_settings.dart';
import 'package:aaj_kya_pakayen/domain/enums/protein_type.dart';
import 'package:aaj_kya_pakayen/features/pantry/pantry_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/test_database.dart';

void main() {
  late AppDatabase db;
  late ProviderContainer container;
  late PantryActions actions;
  final now = DateTime(2026, 10, 15, 18);

  setUp(() {
    db = newTestDatabase();
    container = ProviderContainer.test(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        clockProvider.overrideWithValue(() => now),
      ],
    );
    actions = container.read(pantryActionsProvider);
  });
  tearDown(() => db.close());

  Future<int> grams(ProteinType p) async =>
      (await container
              .read(pantryRepositoryProvider)
              .getBatches(proteinType: p))
          .fold<int>(0, (sum, b) => sum + b.quantityGrams);

  test('a purchase is stored with its date and can be undone', () async {
    final undo = await actions.addPurchase(
      ProteinType.beef,
      1000,
      boughtOn: DateTime(2026, 10, 13),
    );
    final batch =
        (await container.read(pantryRepositoryProvider).getBatches()).single;
    expect(batch.quantityGrams, 1000);
    expect(batch.addedOn, DateTime(2026, 10, 13));

    await actions.undo(undo);
    expect(await grams(ProteinType.beef), 0);
  });

  test('+ adds a quick step and can be undone', () async {
    final undo = await actions.increase(ProteinType.chicken);
    expect(await grams(ProteinType.chicken), PantryActions.quickStepGrams);

    await actions.undo(undo);
    expect(await grams(ProteinType.chicken), 0);
  });

  test('− removes a quick step, or whatever is left, oldest first', () async {
    await actions.addPurchase(ProteinType.mince, 600, boughtOn: now);

    final first = await actions.decrease(ProteinType.mince);
    expect(await grams(ProteinType.mince), 350);
    await actions.decrease(ProteinType.mince);
    final last = await actions.decrease(ProteinType.mince);
    expect(last, isNotNull);
    expect(await grams(ProteinType.mince), 0);
    expect(await actions.decrease(ProteinType.mince), isNull);

    await actions.undo(first!);
    expect(await grams(ProteinType.mince), 250);
  });

  test('summary covers all proteins using the household size', () async {
    await container
        .read(settingsRepositoryProvider)
        .save(const AppSettings(householdSize: 2));
    await actions.addPurchase(
      ProteinType.chicken,
      500,
      boughtOn: DateTime(2026, 10, 12),
    );

    final summary = await container.read(pantrySummaryProvider.future);

    expect(summary.map((s) => s.protein), ProteinType.values);
    expect(summary.first.grams, 500);
    expect(summary.first.oldestDays, 3);
    expect(summary.first.isLow, isFalse); // 2 people x 200 g
    expect(summary[1].isLow, isTrue);
  });
}
