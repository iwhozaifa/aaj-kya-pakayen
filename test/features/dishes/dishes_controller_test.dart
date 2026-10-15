import 'package:aaj_kya_pakayen/data/db/app_database.dart';
import 'package:aaj_kya_pakayen/data/providers.dart';
import 'package:aaj_kya_pakayen/domain/entities/dish.dart';
import 'package:aaj_kya_pakayen/domain/enums/cooking_style.dart';
import 'package:aaj_kya_pakayen/domain/enums/dish_type.dart';
import 'package:aaj_kya_pakayen/domain/enums/staple_pairing.dart';
import 'package:aaj_kya_pakayen/domain/usecases/dish_catalog.dart';
import 'package:aaj_kya_pakayen/features/dishes/dishes_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../engine/fixtures.dart';
import '../../helpers/test_database.dart';

void main() {
  late AppDatabase db;
  late ProviderContainer container;

  final bhindi = dish(2, side: true).copyWith(nameEn: 'Bhindi');
  final karahi = dish(
    50,
    type: DishType.chicken,
  ).copyWith(nameEn: 'Karahi');
  final retired = dish(3, active: false).copyWith(nameEn: 'Arvi');

  const draft = CustomDishDraft(
    name: 'Ammi ka Qorma',
    dishType: DishType.mutton,
    staplePairing: StaplePairing.roti,
    cookingStyle: CookingStyle.curry,
    prepMinutes: 90,
  );

  setUp(() async {
    db = newTestDatabase();
    container = ProviderContainer.test(
      overrides: [appDatabaseProvider.overrideWithValue(db)],
    );
    await container.read(dishRepositoryProvider).upsertAll([
      bhindi,
      karahi,
      retired,
    ]);
    container.listen(allDishesProvider, (_, _) {});
  });
  tearDown(() => db.close());

  Future<List<Dish>> all() => container.read(allDishesProvider.future);
  Future<List<Dish>> active() =>
      container.read(dishRepositoryProvider).getAll();
  DishesActions actions() => container.read(dishesActionsProvider);

  test('lists every dish, hidden ones included', () async {
    expect(await all(), [retired, bhindi, karahi]);
  });

  test('hiding a dish keeps it out of suggestions until shown again', () async {
    await actions().setActive(karahi, active: false);
    expect(await active(), [bhindi]);

    await actions().setActive(karahi, active: true);
    expect(await active(), [bhindi, karahi]);
  });

  test('adds a custom dish, and undo removes it again', () async {
    final added = await actions().addCustom(draft);
    expect(added.isCustom, isTrue);
    expect(await active(), contains(added));

    await actions().undoAdd(added);
    expect(await active(), [bhindi, karahi]);
  });

  test('refuses a duplicate name', () async {
    await expectLater(
      actions().addCustom(draft.copyWith(name: 'arvi')),
      throwsA(isA<DuplicateDishException>()),
    );
  });
}
