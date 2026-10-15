import 'package:aaj_kya_pakayen/domain/enums/day_type.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DayType.flipped', () {
    test('veg day flips to non-veg day', () {
      expect(DayType.vegDay.flipped, DayType.nonVegDay);
    });

    test('non-veg day flips to veg day', () {
      expect(DayType.nonVegDay.flipped, DayType.vegDay);
    });

    test('flipping twice is identity', () {
      for (final type in DayType.values) {
        expect(type.flipped.flipped, type);
      }
    });
  });
}
