import 'package:aaj_kya_pakayen/domain/entities/calendar_date.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('dateOnly drops the time of day', () {
    expect(DateTime(2026, 10, 15, 21, 30, 5).dateOnly, DateTime(2026, 10, 15));
  });

  test('daysSince counts calendar days, ignoring time of day', () {
    final today = DateTime(2026, 10, 15, 0, 5);
    expect(today.daysSince(DateTime(2026, 10, 14, 23, 55)), 1);
    expect(today.daysSince(DateTime(2026, 10, 8, 12)), 7);
    expect(today.daysSince(DateTime(2026, 10, 15, 22)), 0);
    expect(DateTime(2026, 10, 14).daysSince(today), -1);
  });

  test('daysSince is not thrown off by daylight saving changes', () {
    expect(DateTime(2026, 3, 30).daysSince(DateTime(2026, 3, 28)), 2);
    expect(DateTime(2026, 11, 2).daysSince(DateTime(2026, 10, 31)), 2);
  });

  test('isSameDay compares calendar dates', () {
    expect(
      DateTime(2026, 10, 15, 1).isSameDay(DateTime(2026, 10, 15, 23)),
      isTrue,
    );
    expect(DateTime(2026, 10, 15).isSameDay(DateTime(2026, 10, 16)), isFalse);
  });
}
