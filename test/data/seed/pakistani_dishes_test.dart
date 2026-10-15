import 'package:aaj_kya_pakayen/data/seed/pakistani_dishes.dart';
import 'package:aaj_kya_pakayen/domain/enums/dish_type.dart';
import 'package:aaj_kya_pakayen/domain/enums/staple_pairing.dart';
import 'package:flutter_test/flutter_test.dart';

final _urduScript = RegExp(r'^[؀-ۿ\s\-()،]+$');

void main() {
  final byId = {for (final d in pakistaniDishes) d.id: d};
  final byName = {for (final d in pakistaniDishes) d.nameEn: d};

  test('has at least 70 dishes', () {
    expect(pakistaniDishes.length, greaterThanOrEqualTo(70));
  });

  test('ids and English names are unique', () {
    expect(byId.length, pakistaniDishes.length);
    expect(byName.length, pakistaniDishes.length);
  });

  test('seed ids stay below the custom-dish range', () {
    for (final d in pakistaniDishes) {
      expect(d.id, inExclusiveRange(0, firstCustomDishId), reason: d.nameEn);
    }
  });

  test('every dish has an Urdu name in Urdu script', () {
    for (final d in pakistaniDishes) {
      expect(d.nameUr, matches(_urduScript), reason: d.nameEn);
    }
  });

  test('all seed dishes are active, Pakistani and not custom', () {
    for (final d in pakistaniDishes) {
      expect(d.cuisine, 'pakistani');
      expect(d.isActive, isTrue);
      expect(d.isCustom, isFalse);
    }
  });

  test('meat dishes need protein; veg dishes need none', () {
    for (final d in pakistaniDishes) {
      if (d.isVeg) {
        expect(d.proteinGramsPerPerson, isNull, reason: d.nameEn);
      } else {
        expect(
          d.proteinGramsPerPerson,
          inInclusiveRange(50, 400),
          reason: d.nameEn,
        );
      }
    }
  });

  test('only vegetable dishes can be sides', () {
    for (final d in pakistaniDishes.where((d) => d.canBeSide)) {
      expect(d.dishType, DishType.vegetable, reason: d.nameEn);
    }
  });

  test('every pulse dish names its staple', () {
    for (final d in pakistaniDishes.where((d) => d.dishType == .pulse)) {
      expect(
        d.staplePairing,
        isIn([StaplePairing.rice, StaplePairing.roti, StaplePairing.either]),
        reason: d.nameEn,
      );
    }
  });

  test('plenty of pulse dishes are paired with rice', () {
    final withRice = pakistaniDishes.where(
      (d) => d.dishType == .pulse && d.staplePairing == StaplePairing.rice,
    );
    expect(withRice.length, greaterThanOrEqualTo(7));
  });

  test('prep times are realistic', () {
    for (final d in pakistaniDishes) {
      expect(d.prepMinutes, inInclusiveRange(10, 480), reason: d.nameEn);
    }
  });

  test('covers every dish type with enough choice', () {
    final counts = <DishType, int>{};
    for (final d in pakistaniDishes) {
      counts.update(d.dishType, (n) => n + 1, ifAbsent: () => 1);
    }
    expect(counts[DishType.vegetable], greaterThanOrEqualTo(15));
    expect(counts[DishType.pulse], greaterThanOrEqualTo(14));
    expect(counts[DishType.chicken], greaterThanOrEqualTo(10));
    expect(counts[DishType.mince], greaterThanOrEqualTo(7));
    expect(
      counts[DishType.beef]! + counts[DishType.mutton]!,
      greaterThanOrEqualTo(9),
    );
  });

  test('includes every dish named in the brief', () {
    const required = [
      // Vegetable
      'Aloo Gobi', 'Bhindi Masala', 'Baingan Bharta', 'Aloo Matar',
      'Karela Masala', 'Tinda', 'Lauki', 'Palak Paneer', 'Mixed Sabzi',
      'Khatta Meetha Kaddu', 'Turai', 'Arvi', 'Shalgam', 'Matar Pulao',
      'Aloo Palak', 'Gobi Masala',
      // Pulses
      'Daal Chawal', 'Mash ki Daal', 'Masoor Daal', 'Moong Daal',
      'Chana Daal', 'Daal Mash Tarka', 'Khichdi', 'Rajma Chawal',
      'Lobia Chawal', 'Chana Pulao', 'Kala Chana', 'Cholay', 'Kadhi Chawal',
      'Daal Palak',
      // Chicken
      'Chicken Karahi', 'Chicken Handi', 'Chicken Qorma', 'Chicken Biryani',
      'Chicken Pulao', 'Chicken Jalfrezi', 'Butter Chicken', 'Chicken Tikka',
      'Chicken White Karahi', 'Achari Chicken',
      // Beef / mutton
      'Beef Nihari', 'Beef Karahi', 'Haleem', 'Paye', 'Mutton Karahi',
      'Mutton Qorma', 'Beef Pulao', 'Bhuna Gosht', 'Shinwari Karahi',
      // Mince
      'Aloo Qeema', 'Matar Qeema', 'Qeema Karela', 'Shami Kebab',
      'Kofta Curry', 'Seekh Kebab', 'Qeema Pulao',
    ];
    expect(byName.keys, containsAll(required));
  });

  test('variant groups join dishes of the same type', () {
    final groups = <String, Set<DishType>>{};
    for (final d in pakistaniDishes.where((d) => d.variantGroup != null)) {
      groups.putIfAbsent(d.variantGroup!, () => {}).add(d.dishType);
    }
    for (final MapEntry(:key, :value) in groups.entries) {
      expect(value, hasLength(1), reason: key);
    }
    expect(
      byName['Chicken Karahi']!.variantGroup,
      byName['Chicken White Karahi']!.variantGroup,
    );
    expect(
      byName['Mash ki Daal']!.variantGroup,
      byName['Daal Mash Tarka']!.variantGroup,
    );
  });

  group('pairings', () {
    test('there are curated pairings', () {
      expect(pakistaniPairings.length, greaterThanOrEqualTo(15));
    });

    test('pair a meat main with a vegetable side that can be a side', () {
      for (final p in pakistaniPairings) {
        final main = byId[p.mainDishId];
        final side = byId[p.sideDishId];
        expect(main, isNotNull, reason: '${p.mainDishId}');
        expect(side, isNotNull, reason: '${p.sideDishId}');
        expect(main!.isVeg, isFalse, reason: main.nameEn);
        expect(side!.dishType, DishType.vegetable, reason: side.nameEn);
        expect(side.canBeSide, isTrue, reason: side.nameEn);
      }
    });

    test('are unique per main and side', () {
      final keys = {
        for (final p in pakistaniPairings) (p.mainDishId, p.sideDishId),
      };
      expect(keys.length, pakistaniPairings.length);
    });

    test('include chicken karahi with bhindi masala', () {
      expect(
        pakistaniPairings.any(
          (p) =>
              p.mainDishId == byName['Chicken Karahi']!.id &&
              p.sideDishId == byName['Bhindi Masala']!.id,
        ),
        isTrue,
      );
    });
  });
}
