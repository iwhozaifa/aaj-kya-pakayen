import 'package:aaj_kya_pakayen/domain/services/reminder_scheduler.dart';

/// Records what would be scheduled instead of touching the platform.
class FakeReminderScheduler implements ReminderScheduler {
  bool permissionGranted = true;
  int permissionRequests = 0;

  /// The reminder currently scheduled, or null.
  ({int minutes, String title, String body})? scheduled;

  @override
  Future<bool> requestPermission() async {
    permissionRequests++;
    return permissionGranted;
  }

  @override
  Future<void> scheduleDaily({
    required int minutesAfterMidnight,
    required String title,
    required String body,
  }) async =>
      scheduled = (minutes: minutesAfterMidnight, title: title, body: body);

  @override
  Future<void> cancel() async => scheduled = null;
}
