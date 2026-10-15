import 'package:aaj_kya_pakayen/core/utils/clock.dart';
import 'package:aaj_kya_pakayen/data/db/app_database.dart';
import 'package:aaj_kya_pakayen/data/providers.dart';
import 'package:aaj_kya_pakayen/domain/engine/suggestion_engine.dart';
import 'package:aaj_kya_pakayen/domain/enums/day_type.dart';
import 'package:aaj_kya_pakayen/domain/enums/dinner_source.dart';
import 'package:aaj_kya_pakayen/domain/enums/dish_type.dart';
import 'package:aaj_kya_pakayen/domain/enums/protein_type.dart';
import 'package:aaj_kya_pakayen/features/today/today_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../engine/fixtures.dart' hide today;
import '../../helpers/test_database.dart';

void main() {
  late AppDatabase db;
  late ProviderContainer container;
  final evening = DateTime(2026, 10, 15, 19);

  final vegs = [for (var id = 1; id <= 4; id++) dish(id)];
  final chicken = dish(10, type: DishType.chicken, grams: 200);
  final beef = dish(11, type: DishType.beef, grams: 200);

  setUp(() async {
    db = newTestDatabase();
    container = ProviderContainer.test(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        clockProvider.overrideWithValue(() => evening),
      ],
    );
    await container.read(dishRepositoryProvider).upsertAll([
      ...vegs,
      chicken,
      beef,
    ]);
    container.listen(todayStateProvider, (_, _) {});
  });
  tearDown(() => db.close());

  Future<TodayState> state() => container.read(todayStateProvider.future);
  TodayActions actions() => container.read(todayActionsProvider);
  HomeSuggestion top(TodayState s) =>
      s.result.suggestions.first as HomeSuggestion;

  test('first evening is a veg day with veg suggestions', () async {
    final s = await state();
    expect(s.result.dayType, DayType.vegDay);
    expect(s.tonight, isNull);
    expect(top(s).main.isVeg, isTrue);
  });

  test('cooking logs tonight; undo takes it back', () async {
    final s = await state();
    final entryId = await actions().cook(top(s), s.result.dayType);

    final logged = await state();
    expect(logged.tonight?.id, entryId);
    expect(logged.tonightMain, top(s).main);

    await actions().undo(entryId);
    expect((await state()).tonight, isNull);
  });

  test('cooking meat deducts it from the pantry', () async {
    await container
        .read(pantryRepositoryProvider)
        .addPurchase(proteinType: ProteinType.chicken, grams: 1000);
    await actions().swapDayType((await state()).result);
    final s = await state();
    expect(s.result.dayType, DayType.nonVegDay);

    await actions().cook(top(s), s.result.dayType);

    final left = await container.read(pantryRepositoryProvider).getBatches();
    expect(left.single.quantityGrams, 200); // 1000 - 4 x 200
  });

  test('show another brings a different dish to the top', () async {
    final first = top(await state()).main;
    actions().showAnother();
    expect(top(await state()).main, isNot(first));
  });

  test('swap flips tonight, swapping again flips back', () async {
    await actions().swapDayType((await state()).result);
    final swapped = await state();
    expect(swapped.result.dayType, DayType.nonVegDay);
    expect(swapped.result.isOverride, isTrue);

    await actions().swapDayType(swapped.result);
    final back = await state();
    expect(back.result.dayType, DayType.vegDay);
    expect(back.result.isOverride, isFalse);
  });

  test('ordering outside logs a non-veg outside dinner with a note', () async {
    await actions().orderOutside('nihari from Javed');
    final s = await state();
    expect(s.tonight?.source, DinnerSource.outside);
    expect(s.tonight?.outsideNote, 'nihari from Javed');
  });
}
