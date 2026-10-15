import 'package:aaj_kya_pakayen/core/l10n/generated/app_localizations.dart';
import 'package:aaj_kya_pakayen/data/providers.dart';
import 'package:aaj_kya_pakayen/domain/entities/app_settings.dart';
import 'package:aaj_kya_pakayen/domain/enums/time_budget.dart';
import 'package:aaj_kya_pakayen/domain/repositories/settings_repository.dart';
import 'package:aaj_kya_pakayen/domain/services/reminder_scheduler.dart';
import 'package:flutter/widgets.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'settings_controller.g.dart';

/// Changes made on the Settings screen. Each one saves straight away; the
/// rest of the app follows through the settings stream.
class SettingsActions {
  new({required this._settings, required this._reminders});

  final SettingsRepository _settings;
  final ReminderScheduler _reminders;

  Future<AppSettings> _update(AppSettings Function(AppSettings) change) async {
    final updated = change(await _settings.load());
    await _settings.save(updated);
    return updated;
  }

  Future<void> setLanguage(String languageCode) async {
    final updated = await _update(
      (s) => s.copyWith(languageCode: languageCode),
    );
    await _reschedule(updated);
  }

  Future<void> setHouseholdSize(int size) =>
      _update((s) => s.withHouseholdSize(size));

  Future<void> setRepeatWindow(int days) =>
      _update((s) => s.withRepeatWindow(days));

  Future<void> setTimeBudget(TimeBudget budget) =>
      _update((s) => s.copyWith(timeBudget: budget));

  /// Returns false, leaving the reminder off, when notifications are not
  /// allowed.
  Future<bool> setReminderEnabled({required bool enabled}) async {
    if (enabled && !await _reminders.requestPermission()) return false;
    final updated = await _update((s) => s.copyWith(reminderEnabled: enabled));
    if (enabled) {
      await _reschedule(updated);
    } else {
      await _reminders.cancel();
    }
    return true;
  }

  Future<void> setReminderTime(int minutesAfterMidnight) async {
    final updated = await _update(
      (s) => s.copyWith(reminderMinutes: minutesAfterMidnight),
    );
    await _reschedule(updated);
  }

  /// Keeps a reminder that is on in step with its time and language.
  Future<void> _reschedule(AppSettings settings) async {
    if (!settings.reminderEnabled) return;
    final l10n = lookupAppLocalizations(Locale(settings.languageCode));
    await _reminders.scheduleDaily(
      minutesAfterMidnight: settings.reminderMinutes,
      title: l10n.reminderTitle,
      body: l10n.reminderBody,
    );
  }
}

@Riverpod(keepAlive: true)
SettingsActions settingsActions(Ref ref) => SettingsActions(
  settings: ref.watch(settingsRepositoryProvider),
  reminders: ref.watch(reminderSchedulerProvider),
);
