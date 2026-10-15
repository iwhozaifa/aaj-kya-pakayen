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

  /// Replaces every stored setting with [values].
  Future<void> replaceAll(Map<String, String> values) => transaction(() async {
    await delete(appSettingsEntries).go();
    await batch(
      (b) => b.insertAll(appSettingsEntries, [
        for (final MapEntry(:key, :value) in values.entries)
          AppSettingsEntriesCompanion.insert(key: key, value: value),
      ]),
    );
  });
}
