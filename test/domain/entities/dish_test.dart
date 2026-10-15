import 'package:aaj_kya_pakayen/domain/entities/dish.dart';
import 'package:aaj_kya_pakayen/domain/enums/cooking_style.dart';
import 'package:aaj_kya_pakayen/domain/enums/dish_type.dart';
import 'package:aaj_kya_pakayen/domain/enums/protein_type.dart';
import 'package:aaj_kya_pakayen/domain/enums/staple_pairing.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
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
  );

  test('defaults to an active, non-custom Pakistani main', () {
    expect(karahi.cuisine, 'pakistani');
    expect(karahi.isActive, isTrue);
    expect(karahi.isCustom, isFalse);
    expect(karahi.canBeSide, isFalse);
  });

  test('derives veg flag and protein type from the dish type', () {
    expect(karahi.isVeg, isFalse);
    expect(karahi.proteinType, ProteinType.chicken);
  });

  test('scales protein to the household', () {
    expect(karahi.proteinGramsFor(householdSize: 5), 1000);
    expect(
      karahi
          .copyWith(proteinGramsPerPerson: null)
          .proteinGramsFor(householdSize: 5),
      0,
    );
  });

  test('variant key falls back to the dish id', () {
    expect(karahi.variantKey, 'chicken_karahi');
    expect(karahi.copyWith(variantGroup: null).variantKey, 'dish:1');
  });

  test('round-trips through json', () {
    expect(Dish.fromJson(karahi.toJson()), karahi);
  });
}
