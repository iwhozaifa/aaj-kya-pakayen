import 'package:aaj_kya_pakayen/domain/engine/rules/side_picker.dart';
import 'package:aaj_kya_pakayen/domain/entities/dish.dart';
import 'package:aaj_kya_pakayen/domain/entities/dish_pairing.dart';
import 'package:aaj_kya_pakayen/domain/enums/dish_type.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fixtures.dart';

void main() {
  final karahi = dish(1, type: DishType.chicken);
  final bhindi = dish(2, side: true);
  final bhujia = dish(3, side: true);
  final notASide = dish(4);
  final inactive = dish(5, side: true, active: false);
  final dishes = {
    for (final d in [karahi, bhindi, bhujia, notASide, inactive]) d.id: d,
  };

  Dish? pick(
    Dish main,
    List<DishPairing> pairings, {
    bool Function(Dish)? allowed,
  }) => pickSide(
    main: main,
    pairings: pairings,
    dishesById: dishes,
    allowed: allowed ?? (_) => true,
  );

  test('proposes the highest-priority curated side', () {
    expect(
      pick(karahi, const [
        DishPairing(mainDishId: 1, sideDishId: 3, priority: 1),
        DishPairing(mainDishId: 1, sideDishId: 2),
      ]),
      bhindi,
    );
  });

  test('falls back when the preferred side is not allowed', () {
    expect(
      pick(karahi, const [
        DishPairing(mainDishId: 1, sideDishId: 2),
        DishPairing(mainDishId: 1, sideDishId: 3, priority: 1),
      ], allowed: (d) => d.id != 2),
      bhujia,
    );
  });

  test('skips sides that are inactive, not sides, or unknown', () {
    expect(
      pick(karahi, const [
        DishPairing(mainDishId: 1, sideDishId: 4),
        DishPairing(mainDishId: 1, sideDishId: 5),
        DishPairing(mainDishId: 1, sideDishId: 99),
      ]),
      isNull,
    );
  });

  test('no side without a curated pairing, and never for veg mains', () {
    expect(pick(karahi, const []), isNull);
    expect(
      pick(bhindi, const [DishPairing(mainDishId: 2, sideDishId: 3)]),
      isNull,
    );
  });
}
