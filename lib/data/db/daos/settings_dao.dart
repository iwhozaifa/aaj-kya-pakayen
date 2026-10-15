import 'package:aaj_kya_pakayen/data/db/app_database.dart';
import 'package:aaj_kya_pakayen/data/db/tables.dart';
import 'package:drift/drift.dart';

part 'settings_dao.g.dart';

@DriftAccessor(tables: [AppSettingsEntries])
class SettingsDao extends DatabaseAccessor<AppDatabase>
    with _$SettingsDaoMixin {
  new(super.attachedDatabase);

  Map<String, String> _toMap(List<SettingRow> rows) => {
    for (final row in rows) row.key: row.value,
  };

  Future<Map<String, String>> all() =>
      select(appSettingsEntries).get().then(_toMap);

  Stream<Map<String, String>> watchAll() =>
      select(appSettingsEntries).watch().map(_toMap);

  Future<String?> value(String key) => (select(
    appSettingsEntries,
  )..where((s) => s.key.equals(key))).map((row) => row.value).getSingleOrNull();

  Future<void> setValue(String key, String value) => into(appSettingsEntries)
      .insertOnConflictUpdate(
        AppSettingsEntriesCompanion.insert(key: key, value: value),
      );

  /// Writes [values] and removes any of [ownedKeys] not in [values].
  /// Keys outside [ownedKeys] are left untouched.
  Future<void> replaceOwned(
    Set<String> ownedKeys,
    Map<String, String> values,
  ) => transaction(() async {
    final stale = ownedKeys.difference(values.keys.toSet());
    await (delete(appSettingsEntries)..where((s) => s.key.isIn(stale))).go();
    await batch(
      (b) => b.insertAllOnConflictUpdate(appSettingsEntries, [
        for (final MapEntry(:key, :value) in values.entries)
          AppSettingsEntriesCompanion.insert(key: key, value: value),
      ]),
    );
  });
}
