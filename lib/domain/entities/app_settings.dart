// freezed can't parse `new` constructors yet (docs/DECISIONS.md D-014).
// ignore_for_file: unnecessary_type_name_in_constructor

import 'package:aaj_kya_pakayen/domain/entities/calendar_date.dart';
import 'package:aaj_kya_pakayen/domain/enums/day_type.dart';
import 'package:aaj_kya_pakayen/domain/enums/time_budget.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'app_settings.freezed.dart';
part 'app_settings.g.dart';

/// "Swap today's type": applies to [date] only (DECISIONS D-007).
@freezed
abstract class DayTypeOverride with _$DayTypeOverride {
  const factory DayTypeOverride({
    required DateTime date,
    required DayType dayType,
  }) = _DayTypeOverride;

  factory DayTypeOverride.fromJson(Map<String, dynamic> json) =>
      _$DayTypeOverrideFromJson(json);
}

@freezed
abstract class AppSettings with _$AppSettings {
  const factory AppSettings({
    @Default(4) int householdSize,
    @Default(7) int repeatWindowDays,
    @Default('ur') String languageCode,
    @Default({'pakistani'}) Set<String> enabledCuisines,
    @Default(false) bool reminderEnabled,

    /// Reminder time as minutes after midnight (default 4:30 PM).
    @Default(16 * 60 + 30) int reminderMinutes,
    @Default(TimeBudget.normal) TimeBudget timeBudget,
    DayTypeOverride? dayTypeOverride,
    @Default(false) bool onboardingComplete,
  }) = _AppSettings;

  const AppSettings._();

  factory AppSettings.fromJson(Map<String, dynamic> json) =>
      _$AppSettingsFromJson(json);

  DayType? overrideFor(DateTime date) {
    final override = dayTypeOverride;
    return override != null && override.date.isSameDay(date)
        ? override.dayType
        : null;
  }
}
