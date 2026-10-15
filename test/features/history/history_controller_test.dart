import 'package:aaj_kya_pakayen/core/utils/clock.dart';
import 'package:aaj_kya_pakayen/data/db/app_database.dart';
import 'package:aaj_kya_pakayen/data/providers.dart';
import 'package:aaj_kya_pakayen/domain/enums/day_type.dart';
import 'package:aaj_kya_pakayen/domain/enums/dish_type.dart';
import 'package:aaj_kya_pakayen/domain/enums/protein_type.dart';
import 'package:aaj_kya_pakayen/features/history/history_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../engine/fixtures.dart' hide today;
import '../../helpers/test_database.dart';

void main() {
  late AppDatabase db;
  late ProviderContainer container;
  final now = DateTime(2026, 10, 15, 21);

  final daal = dish(1, type: DishType.pulse);
  final bhindi = dish(2, side: true);
  final karahi = dish(10, type: DishType.chicken, grams: 200);
  final retired = dish(3, active: false);

  setUp(() async {
    db = newTestDatabase();
    container = ProviderContainer.test(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        clockProvider.overrideWithValue(() => now),
      ],
    );
    await container.read(dishRepositoryProvider).upsertAll([
      daal,
      bhindi,
      karahi,
      retired,
    ]);
    await container
        .read(pantryRepositoryProvider)
        .addPurchase(proteinType: ProteinType.chicken, grams: 2000);
    container.listen(historyStateProvider, (_, _) {});
  });
  tearDown(() => db.close());

  Future<HistoryState> state() => container.read(historyStateProvider.future);
  HistoryActions actions() => container.read(historyActionsProvider);
  Future<int> chickenLeft() async =>
      (await container.read(pantryRepositoryProvider).getBatches()).fold<int>(
        0,
        (sum, b) => sum + b.quantityGrams,
      );

  test('the week strip covers the last 7 days, ending today', () async {
    await actions().saveHome(DateTime(2026, 10, 13), main: daal);

    final week = (await state()).week;
    expect(week.map((d) => d.date.day), [9, 10, 11, 12, 13, 14, 15]);
    expect(week[4].entry?.main, daal);
    expect(week.where((d) => d.entry != null), hasLength(1));
  });

  test(
    'entries are newest first with their dishes, even inactive ones',
    () async {
      await actions().saveHome(DateTime(2026, 10, 10), main: retired);
      await actions().saveOutside(DateTime(2026, 10, 12), note: 'nihari');
      await actions().saveHome(
        DateTime(2026, 10, 14),
        main: karahi,
        side: bhindi,
      );

      final entries = (await state()).entries;
      expect(entries.map((e) => e.entry.date.day), [14, 12, 10]);
      expect(entries.first.main, karahi);
      expect(entries.first.side, bhindi);
      expect(entries[1].entry.outsideNote, 'nihari');
      expect(entries.last.main, retired);
    },
  );

  test(
    'a past day gets its type from the dish and is not "suggested"',
    () async {
      await actions().saveHome(DateTime(2026, 10, 14), main: karahi);
      final entry = (await state()).entries.single.entry;
      expect(entry.dayType, DayType.nonVegDay);
      expect(entry.wasSuggested, isFalse);
      expect(await chickenLeft(), 1200);
    },
  );

  test('editing a day swaps the stock it used', () async {
    await actions().saveHome(DateTime(2026, 10, 14), main: karahi);
    final before = (await state()).entries.single;

    await actions().saveHome(DateTime(2026, 10, 14), main: daal);

    expect((await state()).entries.single.main, daal);
    expect(await chickenLeft(), 2000);

    await actions().restore(before);
    expect((await state()).entries.single.main, karahi);
    expect(await chickenLeft(), 1200);
  });

  test('deleting gives the stock back; restoring takes it again', () async {
    await actions().saveHome(DateTime(2026, 10, 14), main: karahi);
    final entry = (await state()).entries.single;

    await actions().delete(entry);
    expect((await state()).entries, isEmpty);
    expect(await chickenLeft(), 2000);

    await actions().restore(entry);
    expect((await state()).entries.single.main, karahi);
    expect(await chickenLeft(), 1200);
  });

  test('undoing a brand-new day removes it', () async {
    final id = await actions().saveOutside(DateTime(2026, 10, 11));
    await actions().removeById(id);
    expect((await state()).entries, isEmpty);
  });
}
