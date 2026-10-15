import 'package:aaj_kya_pakayen/domain/entities/app_settings.dart';
import 'package:aaj_kya_pakayen/domain/entities/calendar_date.dart';
import 'package:aaj_kya_pakayen/domain/entities/dinner_log_entry.dart';
import 'package:aaj_kya_pakayen/domain/enums/day_type.dart';

final class DayTypeResolution {
  const new({required this.naturalDayType, this.overrideDayType});

  /// What alternation alone says tonight is.
  final DayType naturalDayType;

  /// Set when the cook swapped tonight's type.
  final DayType? overrideDayType;

  DayType get dayType => overrideDayType ?? naturalDayType;

  bool get isOverride => overrideDayType != null;
}

/// Hard rule 2: tonight is the opposite of the most recent dinner logged
/// before [date] (veg day when there is none). A swap override applies to
/// its own date only; the next day flips from what was actually logged.
DayTypeResolution resolveDayType({
  required DateTime date,
  required Iterable<DinnerLogEntry> history,
  required AppSettings settings,
}) {
  DinnerLogEntry? latest;
  for (final entry in history) {
    if (entry.date.daysSince(date) >= 0) continue;
    if (latest == null || entry.date.isAfter(latest.date)) latest = entry;
  }
  return DayTypeResolution(
    naturalDayType: latest?.dayType.flipped ?? DayType.vegDay,
    overrideDayType: settings.overrideFor(date),
  );
}
