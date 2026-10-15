import 'package:aaj_kya_pakayen/core/l10n/locale_provider.dart';
import 'package:aaj_kya_pakayen/data/db/app_database.dart';
import 'package:aaj_kya_pakayen/data/providers.dart';
import 'package:aaj_kya_pakayen/domain/entities/app_settings.dart';
import 'package:aaj_kya_pakayen/domain/enums/time_budget.dart';
import 'package:aaj_kya_pakayen/features/settings/settings_controller.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fake_reminder_scheduler.dart';
import '../../helpers/test_database.dart';

void main() {
  late AppDatabase db;
  late ProviderContainer container;
  late FakeReminderScheduler reminders;

  setUp(() {
    db = newTestDatabase();
    reminders = FakeReminderScheduler();
    container = ProviderContainer.test(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        reminderSchedulerProvider.overrideWithValue(reminders),
      ],
    )..listen(appSettingsProvider, (_, _) {});
  });
  tearDown(() => db.close());

  SettingsActions actions() => container.read(settingsActionsProvider);
  Future<AppSettings> saved() =>
      container.read(settingsRepositoryProvider).load();

  test('household size, repeat window and time budget persist', () async {
    await actions().setHouseholdSize(6);
    await actions().setRepeatWindow(10);
    await actions().setTimeBudget(TimeBudget.quick);

    final s = await saved();
    expect(s.householdSize, 6);
    expect(s.repeatWindowDays, 10);
    expect(s.timeBudget, TimeBudget.quick);

    await actions().setHouseholdSize(0);
    expect((await saved()).householdSize, AppSettings.householdSizes.min);
  });

  test('the app language follows the saved setting', () async {
    expect(container.read(appLocaleProvider), const Locale('ur'));

    await actions().setLanguage('en');
    await container.read(appSettingsProvider.future);
    await pumpEventQueue();
    expect(container.read(appLocaleProvider), const Locale('en'));
    expect((await saved()).languageCode, 'en');
  });

  test('turning the reminder on schedules it for 4:30 PM in Urdu', () async {
    expect(await actions().setReminderEnabled(enabled: true), isTrue);

    expect(reminders.permissionRequests, 1);
    expect(reminders.scheduled, (
      minutes: 16 * 60 + 30,
      title: 'آج کیا پکائیں؟',
      body: 'آج رات کا مشورہ دیکھنے کے لیے ٹیپ کریں۔',
    ));
    expect((await saved()).reminderEnabled, isTrue);
  });

  test('a refused permission leaves the reminder off', () async {
    reminders.permissionGranted = false;

    expect(await actions().setReminderEnabled(enabled: true), isFalse);
    expect(reminders.scheduled, isNull);
    expect((await saved()).reminderEnabled, isFalse);
  });

  test(
    'changing the time or language reschedules a reminder that is on',
    () async {
      await actions().setReminderEnabled(enabled: true);

      await actions().setReminderTime(18 * 60);
      expect(reminders.scheduled?.minutes, 18 * 60);
      expect((await saved()).reminderMinutes, 18 * 60);

      await actions().setLanguage('en');
      expect(reminders.scheduled?.title, "What's for dinner?");
      expect(reminders.scheduled?.minutes, 18 * 60);
    },
  );

  test('changing the time while off only saves it', () async {
    await actions().setReminderTime(17 * 60);
    expect(reminders.scheduled, isNull);
    expect((await saved()).reminderMinutes, 17 * 60);
  });

  test('turning the reminder off cancels it', () async {
    await actions().setReminderEnabled(enabled: true);
    await actions().setReminderEnabled(enabled: false);

    expect(reminders.scheduled, isNull);
    expect((await saved()).reminderEnabled, isFalse);
  });
}
