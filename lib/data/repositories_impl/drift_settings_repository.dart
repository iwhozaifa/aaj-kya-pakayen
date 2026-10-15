import 'package:aaj_kya_pakayen/data/db/app_database.dart';
import 'package:aaj_kya_pakayen/data/db/converters.dart';
import 'package:aaj_kya_pakayen/data/db/daos/settings_dao.dart';
import 'package:aaj_kya_pakayen/domain/entities/app_settings.dart';
import 'package:aaj_kya_pakayen/domain/enums/day_type.dart';
import 'package:aaj_kya_pakayen/domain/enums/time_budget.dart';
import 'package:aaj_kya_pakayen/domain/repositories/settings_repository.dart';

/// Stores [AppSettings] as readable key/value rows in `app_settings`.
/// Missing or unreadable values fall back to the defaults.
class DriftSettingsRepository implements SettingsRepository {
  new(AppDatabase db) : _dao = db.settingsDao;

  final SettingsDao _dao;

  static const _date = DateOnlyConverter();

  /// Keys written by [save]; other rows (e.g. `seed_version`) are kept.
  static const ownedKeys = {
    'household_size',
    'repeat_window_days',
    'language',
    'enabled_cuisines',
    'reminder_enabled',
    'reminder_time',
    'time_budget',
    'onboarding_complete',
    'day_type_override',
  };

  @override
  Future<AppSettings> load() async => _fromMap(await _dao.all());

  @override
  Stream<AppSettings> watch() => _dao.watchAll().map(_fromMap);

  @override
  Future<void> save(AppSettings settings) =>
      _dao.replaceOwned(ownedKeys, _toMap(settings));

  static Map<String, String> _toMap(AppSettings s) {
    String two(int n) => n.toString().padLeft(2, '0');
    final override = s.dayTypeOverride;
    return {
      'household_size': '${s.householdSize}',
      'repeat_window_days': '${s.repeatWindowDays}',
      'language': s.languageCode,
      'enabled_cuisines': (s.enabledCuisines.toList()..sort()).join(','),
      'reminder_enabled': '${s.reminderEnabled}',
      'reminder_time':
          '${two(s.reminderMinutes ~/ 60)}:${two(s.reminderMinutes % 60)}',
      'time_budget': s.timeBudget.name,
      'onboarding_complete': '${s.onboardingComplete}',
      if (override != null)
        'day_type_override':
            '${_date.toSql(override.date)}:${override.dayType.name}',
    };
  }

  static AppSettings _fromMap(Map<String, String> m) {
    const d = AppSettings();
    int? positiveInt(String key) {
      final value = int.tryParse(m[key] ?? '');
      return value != null && value > 0 ? value : null;
    }

    return AppSettings(
      householdSize: positiveInt('household_size') ?? d.householdSize,
      repeatWindowDays: positiveInt('repeat_window_days') ?? d.repeatWindowDays,
      languageCode: m['language'] ?? d.languageCode,
      enabledCuisines: switch (m['enabled_cuisines']) {
        final String v when v.isNotEmpty => v.split(',').toSet(),
        _ => d.enabledCuisines,
      },
      reminderEnabled: m['reminder_enabled'] == 'true',
      reminderMinutes: _parseTime(m['reminder_time']) ?? d.reminderMinutes,
      timeBudget:
          TimeBudget.values.asNameMap()[m['time_budget']] ?? d.timeBudget,
      dayTypeOverride: _parseOverride(m['day_type_override']),
      onboardingComplete: m['onboarding_complete'] == 'true',
    );
  }

  static int? _parseTime(String? value) {
    final match = RegExp(r'^(\d{2}):(\d{2})$').firstMatch(value ?? '');
    if (match == null) return null;
    final hours = int.parse(match[1]!);
    final minutes = int.parse(match[2]!);
    return hours < 24 && minutes < 60 ? hours * 60 + minutes : null;
  }

  static DayTypeOverride? _parseOverride(String? value) {
    final match = RegExp(r'^(\d{4}-\d{2}-\d{2}):(\w+)$')
        .firstMatch(value ?? '');
    final dayType = DayType.values.asNameMap()[match?[2]];
    if (match == null || dayType == null) return null;
    return DayTypeOverride(date: _date.fromSql(match[1]!), dayType: dayType);
  }
}
