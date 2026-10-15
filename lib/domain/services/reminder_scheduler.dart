/// Shows the daily "What's for dinner?" reminder. The app only talks to
/// this interface; the platform plugin lives in the data layer.
abstract interface class ReminderScheduler {
  /// Asks for permission to notify. True when reminders can be shown.
  Future<bool> requestPermission();

  /// Replaces any earlier reminder with one every day at
  /// [minutesAfterMidnight] local time.
  Future<void> scheduleDaily({
    required int minutesAfterMidnight,
    required String title,
    required String body,
  });

  Future<void> cancel();
}

/// The first time strictly after [now] that the clock shows
/// [minutesAfterMidnight].
DateTime nextDailyOccurrence(DateTime now, int minutesAfterMidnight) {
  final today = DateTime(
    now.year,
    now.month,
    now.day,
    minutesAfterMidnight ~/ 60,
    minutesAfterMidnight % 60,
  );
  return today.isAfter(now)
      ? today
      : DateTime(now.year, now.month, now.day + 1, today.hour, today.minute);
}
