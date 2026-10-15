import 'package:aaj_kya_pakayen/data/db/app_database.dart';
import 'package:aaj_kya_pakayen/data/repositories_impl/drift_dish_repository.dart';
import 'package:aaj_kya_pakayen/domain/entities/dish.dart';
import 'package:aaj_kya_pakayen/domain/entities/dish_pairing.dart';
import 'package:aaj_kya_pakayen/domain/enums/cooking_style.dart';
import 'package:aaj_kya_pakayen/domain/enums/dish_type.dart';
import 'package:aaj_kya_pakayen/domain/enums/staple_pairing.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/test_database.dart';

const karahi = Dish(
  id: 1,
  nameEn: 'Chicken Karahi',
  nameUr: 'چکن کڑاہی',
  dishType: DishType.chicken,
  proteinGramsPerPerson: 200,
  staplePairing: StaplePairing.roti,
  cookingStyle: CookingStyle.karahi,
  prepMinutes: 45,
  variantGroup: 'chicken_karahi',
  notes: 'Tomatoes, green chillies',
);

const bhindi = Dish(
  id: 2,
  nameEn: 'Bhindi Masala',
  nameUr: 'بھنڈی مسالا',
  dishType: DishType.vegetable,
  staplePairing: StaplePairing.roti,
  cookingStyle: CookingStyle.fry,
  prepMinutes: 30,
  canBeSide: true,
);

const aloo = Dish(
  id: 3,
  nameEn: 'Aloo Gobi',
  nameUr: 'آلو گوبھی',
  dishType: DishType.vegetable,
  staplePairing: StaplePairing.roti,
  cookingStyle: CookingStyle.curry,
  prepMinutes: 30,
  canBeSide: true,
  isActive: false,
);

void main() {
  late AppDatabase db;
  late DriftDishRepository repo;

  setUp(() async {
    db = newTestDatabase();
    repo = DriftDishRepository(db);
    await repo.upsertAll(
      [karahi, bhindi, aloo],
      pairings: [const DishPairing(mainDishId: 1, sideDishId: 2)],
    );
  });
  tearDown(() => db.close());

  test('round-trips every field', () async {
    expect(await repo.getById(1), karahi);
    expect(await repo.getById(2), bhindi);
    expect(await repo.getById(99), isNull);
  });

  test('writes derived is_veg and protein_type columns', () async {
    final row = await (db.select(
      db.dishes,
    )..where((d) => d.id.equals(1))).getSingle();
    expect(row.isVeg, isFalse);
    expect(row.proteinType?.name, 'chicken');
  });

  test('lists active dishes by English name unless asked', () async {
    expect(await repo.getAll(), [bhindi, karahi]);
    expect(await repo.getAll(includeInactive: true), [aloo, bhindi, karahi]);
  });

  test('deactivates and reactivates dishes', () async {
    await repo.setActive(1, active: false);
    expect(await repo.getAll(), [bhindi]);
    await repo.setActive(1, active: true);
    expect(await repo.getAll(), [bhindi, karahi]);
  });

  test('upsert replaces existing dishes and pairings', () async {
    await repo.upsertAll(
      [karahi.copyWith(prepMinutes: 50)],
      pairings: [const DishPairing(mainDishId: 1, sideDishId: 2, priority: 3)],
    );
    expect((await repo.getById(1))!.prepMinutes, 50);
    expect(await repo.getPairings(), [
      const DishPairing(mainDishId: 1, sideDishId: 2, priority: 3),
    ]);
  });

  test('watchAll emits changes', () async {
    final stream = repo.watchAll();
    expect(await stream.first, [bhindi, karahi]);
    await repo.setActive(2, active: false);
    expect(await stream.first, [karahi]);
  });
}
