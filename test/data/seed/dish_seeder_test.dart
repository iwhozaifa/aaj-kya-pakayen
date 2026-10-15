import 'package:aaj_kya_pakayen/data/db/app_database.dart';
import 'package:aaj_kya_pakayen/data/repositories_impl/drift_dish_repository.dart';
import 'package:aaj_kya_pakayen/data/seed/dish_seeder.dart';
import 'package:aaj_kya_pakayen/data/seed/pakistani_dishes.dart';
import 'package:aaj_kya_pakayen/domain/entities/dish.dart';
import 'package:aaj_kya_pakayen/domain/enums/cooking_style.dart';
import 'package:aaj_kya_pakayen/domain/enums/dish_type.dart';
import 'package:aaj_kya_pakayen/domain/enums/staple_pairing.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/test_database.dart';

void main() {
  late AppDatabase db;
  late DriftDishRepository dishes;
  late DishSeeder seeder;

  setUp(() {
    db = newTestDatabase();
    dishes = DriftDishRepository(db);
    seeder = DishSeeder(db);
  });
  tearDown(() => db.close());

  test('first run inserts every dish and pairing', () async {
    expect(await seeder.seedIfNeeded(), isTrue);

    expect(
      await dishes.getAll(includeInactive: true),
      hasLength(pakistaniDishes.length),
    );
    expect(await dishes.getPairings(), hasLength(pakistaniPairings.length));
    expect(await seeder.installedVersion(), seedVersion);
  });

  test('running again does nothing', () async {
    await seeder.seedIfNeeded();
    expect(await seeder.seedIfNeeded(), isFalse);
    expect(
      await dishes.getAll(includeInactive: true),
      hasLength(pakistaniDishes.length),
    );
  });

  test('a newer seed updates dishes but keeps family choices', () async {
    await seeder.seedIfNeeded();
    await dishes.setActive(2, active: false);
    const custom = Dish(
      id: firstCustomDishId,
      nameEn: "Ammi's Special",
      nameUr: 'امی کی خاص ڈش',
      dishType: DishType.vegetable,
      staplePairing: StaplePairing.roti,
      cookingStyle: CookingStyle.other,
      prepMinutes: 30,
      isCustom: true,
    );
    await dishes.upsertAll([custom]);

    final renamed = [
      for (final d in pakistaniDishes)
        if (d.id == 2) d.copyWith(prepMinutes: 25) else d,
    ];
    final seeded = await seeder.seedIfNeeded(
      version: seedVersion + 1,
      dishes: renamed,
    );

    expect(seeded, isTrue);
    final bhindi = (await dishes.getById(2))!;
    expect(bhindi.prepMinutes, 25);
    expect(bhindi.isActive, isFalse);
    expect(await dishes.getById(firstCustomDishId), custom);
    expect(await seeder.installedVersion(), seedVersion + 1);
  });
}
