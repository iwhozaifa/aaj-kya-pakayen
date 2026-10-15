import 'package:aaj_kya_pakayen/domain/engine/rules/day_type_rule.dart';
import 'package:aaj_kya_pakayen/domain/entities/app_settings.dart';
import 'package:aaj_kya_pakayen/domain/enums/day_type.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fixtures.dart';

void main() {
  const settings = AppSettings();

  test('first ever dinner is a veg day', () {
    final r = resolveDayType(
      date: today,
      history: const [],
      settings: settings,
    );
    expect(r.dayType, DayType.vegDay);
    expect(r.isOverride, isFalse);
  });

  test('tonight flips the most recent logged dinner', () {
    expect(
      resolveDayType(
        date: today,
        history: [cooked(1, DayType.vegDay), cooked(2, DayType.nonVegDay)],
        settings: settings,
      ).dayType,
      DayType.nonVegDay,
    );
    expect(
      resolveDayType(
        date: today,
        history: [cooked(2, DayType.vegDay), cooked(1, DayType.nonVegDay)],
        settings: settings,
      ).dayType,
      DayType.vegDay,
    );
  });

  test('flips from the last log even after a gap of days', () {
    expect(
      resolveDayType(
        date: today,
        history: [cooked(5, DayType.nonVegDay)],
        settings: settings,
      ).dayType,
      DayType.vegDay,
    );
  });

  test("ignores tonight's own entry and anything later", () {
    expect(
      resolveDayType(
        date: today,
        history: [
          cooked(1, DayType.vegDay),
          cooked(0, DayType.vegDay),
          cooked(-1, DayType.vegDay),
        ],
        settings: settings,
      ).dayType,
      DayType.nonVegDay,
    );
  });

  test('ordering outside counts as a non-veg day', () {
    expect(
      resolveDayType(
        date: today,
        history: [orderedOutside(1)],
        settings: settings,
      ).dayType,
      DayType.vegDay,
    );
  });

  group('swap override', () {
    final swapped = AppSettings(
      dayTypeOverride: DayTypeOverride(date: today, dayType: DayType.vegDay),
    );

    test('wins for its own date', () {
      final r = resolveDayType(
        date: today,
        history: [cooked(1, DayType.vegDay)],
        settings: swapped,
      );
      expect(r.dayType, DayType.vegDay);
      expect(r.isOverride, isTrue);
      expect(r.naturalDayType, DayType.nonVegDay);
    });

    test('is ignored on other dates', () {
      final r = resolveDayType(
        date: today.add(const Duration(days: 1)),
        history: [cooked(1, DayType.vegDay)],
        settings: swapped,
      );
      expect(r.isOverride, isFalse);
    });

    test('tomorrow flips from what was actually logged tonight', () {
      // Natural non-veg day swapped to veg and logged as veg:
      // tomorrow must be non-veg.
      final tomorrow = today.add(const Duration(days: 1));
      final r = resolveDayType(
        date: tomorrow,
        history: [cooked(0, DayType.vegDay), cooked(1, DayType.vegDay)],
        settings: swapped,
      );
      expect(r.dayType, DayType.nonVegDay);
    });
  });
}
