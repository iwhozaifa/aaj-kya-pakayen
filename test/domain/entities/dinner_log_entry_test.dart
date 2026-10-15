import 'package:aaj_kya_pakayen/domain/entities/dinner_log_entry.dart';
import 'package:aaj_kya_pakayen/domain/enums/day_type.dart';
import 'package:aaj_kya_pakayen/domain/enums/dinner_source.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('home and outside dinners are told apart', () {
    final home = DinnerLogEntry(
      date: DateTime(2026, 10, 15),
      dayType: DayType.nonVegDay,
      source: DinnerSource.home,
      mainDishId: 1,
      sideDishId: 2,
    );
    final outside = DinnerLogEntry(
      date: DateTime(2026, 10, 16),
      dayType: DayType.nonVegDay,
      source: DinnerSource.outside,
      outsideNote: 'biryani from Student',
    );

    expect(home.isOutside, isFalse);
    expect(home.dishIds, [1, 2]);
    expect(outside.isOutside, isTrue);
    expect(outside.dishIds, isEmpty);
    expect(home.wasSuggested, isTrue);
  });
}
