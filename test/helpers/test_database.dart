import 'package:aaj_kya_pakayen/data/db/app_database.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';

/// A fresh in-memory database per test.
AppDatabase newTestDatabase() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  return AppDatabase(NativeDatabase.memory());
}
