import 'package:aaj_kya_pakayen/domain/enums/dish_type.dart';
import 'package:aaj_kya_pakayen/domain/enums/protein_type.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('vegetables and pulses are veg, everything else is not', () {
    expect(DishType.values.where((t) => t.isVeg), [
      DishType.vegetable,
      DishType.pulse,
    ]);
  });

  test('meat dish types map to their protein', () {
    expect(DishType.chicken.proteinType, ProteinType.chicken);
    expect(DishType.beef.proteinType, ProteinType.beef);
    expect(DishType.mutton.proteinType, ProteinType.mutton);
    expect(DishType.mince.proteinType, ProteinType.mince);
    expect(DishType.vegetable.proteinType, isNull);
    expect(DishType.pulse.proteinType, isNull);
  });
}
