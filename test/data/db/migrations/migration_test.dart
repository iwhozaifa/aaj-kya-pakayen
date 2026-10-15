import 'package:aaj_kya_pakayen/data/db/app_database.dart';
import 'package:drift/drift.dart';
import 'package:drift_dev/api/migrations_native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'generated/schema.dart';

// Regenerate after a schema change (docs/DATABASE.md):
//   dart run drift_dev make-migrations
void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  late SchemaVerifier verifier;

  setUpAll(() => verifier = SchemaVerifier(GeneratedHelper()));

  test('the code schema matches the latest committed schema dump', () async {
    final connection = await verifier.startAt(GeneratedHelper.versions.last);
    final db = AppDatabase(connection);
    await verifier.migrateAndValidate(db, db.schemaVersion);
    await db.close();
  });

  const versions = GeneratedHelper.versions;
  for (final from in versions) {
    for (final to in versions.where((v) => v > from)) {
      test('migrates from v$from to v$to', () async {
        final schema = await verifier.schemaAt(from);
        final db = AppDatabase(schema.newConnection());
        await verifier.migrateAndValidate(db, to);
        await db.close();
      });
    }
  }
}
