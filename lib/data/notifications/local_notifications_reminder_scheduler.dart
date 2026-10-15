import 'package:aaj_kya_pakayen/domain/services/reminder_scheduler.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

/// [ReminderScheduler] backed by flutter_local_notifications. Android only
/// for now; other platforms quietly do nothing.
class LocalNotificationsReminderScheduler implements ReminderScheduler {
  new({required this.channelName, FlutterLocalNotificationsPlugin? plugin})
    : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  static const _id = 1;
  static const _channelId = 'dinner_reminder';

  /// Shown in Android's notification settings.
  final String channelName;
  final FlutterLocalNotificationsPlugin _plugin;
  Future<bool>? _ready;

  bool get _supported =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  AndroidFlutterLocalNotificationsPlugin? get _android => _plugin
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >();

  Future<bool> _init() => _ready ??= () async {
    if (!_supported) return false;
    tz_data.initializeTimeZones();
    try {
      final local = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(local.identifier));
    } on Object {
      // Unknown zone name: fall back to Pakistan time, the app's home.
      tz.setLocalLocation(tz.getLocation('Asia/Karachi'));
    }
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      ),
    );
    return true;
  }();

  @override
  Future<bool> requestPermission() async {
    if (!await _init()) return false;
    return await _android?.requestNotificationsPermission() ?? false;
  }

  @override
  Future<void> scheduleDaily({
    required int minutesAfterMidnight,
    required String title,
    required String body,
  }) async {
    if (!await _init()) return;
    final now = tz.TZDateTime.now(tz.local);
    final next = nextDailyOccurrence(now, minutesAfterMidnight);
    await _plugin.zonedSchedule(
      id: _id,
      title: title,
      body: body,
      scheduledDate: tz.TZDateTime(
        tz.local,
        next.year,
        next.month,
        next.day,
        next.hour,
        next.minute,
      ),
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(_channelId, channelName),
      ),
      // Inexact is fine for a dinner nudge and needs no exact-alarm
      // permission (docs/DECISIONS.md D-031).
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  @override
  Future<void> cancel() async {
    if (!await _init()) return;
    await _plugin.cancel(id: _id);
  }
}
