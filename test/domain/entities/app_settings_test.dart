import 'package:aaj_kya_pakayen/domain/entities/app_settings.dart';
import 'package:aaj_kya_pakayen/domain/enums/day_type.dart';
import 'package:aaj_kya_pakayen/domain/enums/time_budget.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('has sensible first-run defaults', () {
    const s = AppSettings();
    expect(s.householdSize, 4);
    expect(s.repeatWindowDays, 7);
    expect(s.languageCode, 'ur');
    expect(s.enabledCuisines, {'pakistani'});
    expect(s.reminderEnabled, isFalse);
    expect(s.reminderMinutes, 16 * 60 + 30);
    expect(s.timeBudget, TimeBudget.normal);
    expect(s.dayTypeOverride, isNull);
    expect(s.onboardingComplete, isFalse);
  });

  test('a day type override only applies on its own date', () {
    final s = AppSettings(
      dayTypeOverride: DayTypeOverride(
        date: DateTime(2026, 10, 15),
        dayType: DayType.nonVegDay,
      ),
    );
    expect(s.overrideFor(DateTime(2026, 10, 15, 18)), DayType.nonVegDay);
    expect(s.overrideFor(DateTime(2026, 10, 16)), isNull);
  });

  test('round-trips through json', () {
    final s = AppSettings(
      householdSize: 6,
      enabledCuisines: const {'pakistani', 'chinese'},
      dayTypeOverride: DayTypeOverride(
        date: DateTime(2026, 10, 15),
        dayType: DayType.vegDay,
      ),
    );
    expect(AppSettings.fromJson(s.toJson()), s);
  });
}
