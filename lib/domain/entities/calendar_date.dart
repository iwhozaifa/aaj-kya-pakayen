/// Calendar-day helpers. Dinners are logged per local calendar date.
extension CalendarDate on DateTime {
  /// Midnight (local) of this date.
  DateTime get dateOnly => DateTime(year, month, day);

  /// Whole calendar days from [other] to this date. DST-safe.
  int daysSince(DateTime other) => DateTime.utc(
    year,
    month,
    day,
  ).difference(DateTime.utc(other.year, other.month, other.day)).inDays;

  bool isSameDay(DateTime other) => daysSince(other) == 0;
}
