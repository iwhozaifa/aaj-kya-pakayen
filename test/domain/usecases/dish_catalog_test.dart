import 'package:aaj_kya_pakayen/domain/entities/dish.dart';
import 'package:aaj_kya_pakayen/domain/enums/cooking_style.dart';
import 'package:aaj_kya_pakayen/domain/enums/dish_type.dart';
import 'package:aaj_kya_pakayen/domain/enums/staple_pairing.dart';
import 'package:aaj_kya_pakayen/domain/repositories/dish_repository.dart';
import 'package:aaj_kya_pakayen/domain/usecases/dish_catalog.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../engine/fixtures.dart';

class _Dishes extends Mock implements DishRepository;

Dish named(
  int id,
  String en,
  String ur, {
  DishType type = DishType.vegetable,
  bool active = true,
}) => dish(id, type: type, active: active).copyWith(nameEn: en, nameUr: ur);

void main() {
  final bhindi = named(2, 'Bhindi Masala', 'بھنڈی مسالا');
  final daal = named(30, 'Daal Chawal', 'دال چاول', type: DishType.pulse);
  final karahi = named(
    50,
    'Chicken Karahi',
    'چکن کڑاہی',
    type: DishType.chicken,
  );
  final hiddenAloo = named(1, 'Aloo Gobi', 'آلو گوبھی', active: false);
  final all = [hiddenAloo, bhindi, karahi, daal];

  group('filterDishes', () {
    test('keeps everything, hidden dishes last', () {
      expect(filterDishes(all), [bhindi, karahi, daal, hiddenAloo]);
    });

    test('filters by dish type', () {
      expect(filterDishes(all, type: DishType.chicken), [karahi]);
      expect(filterDishes(all, type: DishType.vegetable), [bhindi, hiddenAloo]);
    });

    test('searches English names ignoring case and extra spaces', () {
      expect(filterDishes(all, query: '  KARA '), [karahi]);
      expect(filterDishes(all, query: 'chicken  karahi'), [karahi]);
    });

    test('searches Urdu names', () {
      expect(filterDishes(all, query: 'دال'), [daal]);
    });

    test('combines search and type', () {
      expect(filterDishes(all, query: 'a', type: DishType.pulse), [daal]);
    });
  });

  group('findByName', () {
    test('matches either name, ignoring case and spacing', () {
      expect(findByName(all, 'bhindi   masala'), bhindi);
      expect(findByName(all, 'چکن کڑاہی'), karahi);
      expect(findByName(all, 'aloo gobi'), hiddenAloo);
      expect(findByName(all, 'Nihari'), isNull);
    });
  });

  group('defaultProteinGrams', () {
    test('is null for veg and sized per adult for meat', () {
      expect(defaultProteinGrams(DishType.vegetable), isNull);
      expect(defaultProteinGrams(DishType.pulse), isNull);
      expect(defaultProteinGrams(DishType.chicken), 200);
      expect(defaultProteinGrams(DishType.beef), 200);
      expect(defaultProteinGrams(DishType.mutton), 200);
      expect(defaultProteinGrams(DishType.mince), 150);
    });
  });

  group('AddCustomDish', () {
    late _Dishes repo;
    late AddCustomDish addCustomDish;
    List<Dish> saved() =>
        verify(() => repo.upsertAll(captureAny())).captured.single
            as List<Dish>;

    setUpAll(() => registerFallbackValue(<Dish>[]));

    setUp(() {
      repo = _Dishes();
      addCustomDish = AddCustomDish(repo);
      when(() => repo.upsertAll(any())).thenAnswer((_) async {});
      when(
        () => repo.getAll(includeInactive: true),
      ).thenAnswer((_) async => all);
    });

    const draft = CustomDishDraft(
      name: '  Ammi ka Qorma ',
      dishType: DishType.mutton,
      staplePairing: StaplePairing.roti,
      cookingStyle: CookingStyle.curry,
      prepMinutes: 90,
    );

    test('saves the first custom dish with the first custom id', () async {
      final added = await addCustomDish(draft);

      expect(
        added,
        const Dish(
          id: firstCustomDishId,
          nameEn: 'Ammi ka Qorma',
          nameUr: 'Ammi ka Qorma',
          dishType: DishType.mutton,
          proteinGramsPerPerson: 200,
          staplePairing: StaplePairing.roti,
          cookingStyle: CookingStyle.curry,
          prepMinutes: 90,
          isCustom: true,
        ),
      );
      expect(saved(), [added]);
    });

    test('numbers later custom dishes after the newest one', () async {
      when(() => repo.getAll(includeInactive: true)).thenAnswer(
        (_) async => [
          ...all,
          named(firstCustomDishId + 4, 'Old one', 'پرانی'),
        ],
      );
      final added = await addCustomDish(
        draft.copyWith(dishType: DishType.vegetable),
      );
      expect(added.id, firstCustomDishId + 5);
      expect(added.proteinGramsPerPerson, isNull);
    });

    test('refuses a name the cook already has, even a hidden one', () async {
      await expectLater(
        addCustomDish(draft.copyWith(name: 'ALOO gobi')),
        throwsA(
          isA<DuplicateDishException>().having(
            (e) => e.existing,
            'existing',
            hiddenAloo,
          ),
        ),
      );
      verifyNever(() => repo.upsertAll(any()));
    });

    test('refuses a blank name', () async {
      await expectLater(
        addCustomDish(draft.copyWith(name: '   ')),
        throwsArgumentError,
      );
    });
  });
}
