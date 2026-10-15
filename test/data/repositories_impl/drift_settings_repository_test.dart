import 'package:aaj_kya_pakayen/data/db/app_database.dart';
import 'package:aaj_kya_pakayen/data/repositories_impl/drift_settings_repository.dart';
import 'package:aaj_kya_pakayen/domain/entities/app_settings.dart';
import 'package:aaj_kya_pakayen/domain/enums/day_type.dart';
import 'package:aaj_kya_pakayen/domain/enums/time_budget.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/test_database.dart';

void main() {
  late AppDatabase db;
  late DriftSettingsRepository repo;

  setUp(() {
    db = newTestDatabase();
    repo = DriftSettingsRepository(db);
  });
  tearDown(() => db.close());

  final custom = AppSettings(
    householdSize: 6,
    repeatWindowDays: 5,
    languageCode: 'en',
    enabledCuisines: const {'pakistani', 'chinese'},
    reminderEnabled: true,
    reminderMinutes: 17 * 60,
    timeBudget: TimeBudget.quick,
    dayTypeOverride: DayTypeOverride(
      date: DateTime(2026, 10, 15),
      dayType: DayType.vegDay,
    ),
    onboardingComplete: true,
  );

  test('loads defaults when nothing is stored', () async {
    expect(await repo.load(), const AppSettings());
  });

  test('saves and loads every field', () async {
    await repo.save(custom);
    expect(await repo.load(), custom);
  });

  test('stores one readable key/value row per setting', () async {
    await repo.save(custom);
    final rows = {
      for (final r in await db.select(db.appSettingsEntries).get())
        r.key: r.value,
    };
    expect(rows['household_size'], '6');
    expect(rows['repeat_window_days'], '5');
    expect(rows['language'], 'en');
    expect(rows['enabled_cuisines'], 'chinese,pakistani');
    expect(rows['reminder_time'], '17:00');
    expect(rows['time_budget'], 'quick');
    expect(rows['day_type_override'], '2026-10-15:vegDay');
  });

  test('clearing the override removes it', () async {
    await repo.save(custom);
    await repo.save(custom.copyWith(dayTypeOverride: null));
    expect((await repo.load()).dayTypeOverride, isNull);
  });

  test(
    'saving leaves keys it does not own (e.g. seed_version) alone',
    () async {
      await db.customStatement(
        "INSERT INTO app_settings (key, value) VALUES ('seed_version', '1')",
      );
      await repo.save(custom);
      await repo.save(const AppSettings());

      final row = await db
          .customSelect(
            "SELECT value FROM app_settings WHERE key = 'seed_version'",
          )
          .getSingle();
      expect(row.read<String>('value'), '1');
    },
  );

  test('ignores unreadable values and falls back to defaults', () async {
    await db.customStatement(
      "INSERT INTO app_settings (key, value) VALUES ('household_size', 'abc'),"
      " ('time_budget', 'forever'), ('day_type_override', 'garbage')",
    );
    expect(await repo.load(), const AppSettings());
  });

  test('watch emits saved settings', () async {
    final stream = repo.watch();
    expect(await stream.first, const AppSettings());
    await repo.save(custom);
    expect(await stream.first, custom);
  });
}
