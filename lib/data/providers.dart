import 'package:aaj_kya_pakayen/data/db/app_database.dart';
import 'package:aaj_kya_pakayen/data/repositories_impl/drift_dinner_log_repository.dart';
import 'package:aaj_kya_pakayen/data/repositories_impl/drift_dish_repository.dart';
import 'package:aaj_kya_pakayen/data/repositories_impl/drift_pantry_repository.dart';
import 'package:aaj_kya_pakayen/data/repositories_impl/drift_settings_repository.dart';
import 'package:aaj_kya_pakayen/data/repositories_impl/noop_sync_repository.dart';
import 'package:aaj_kya_pakayen/domain/repositories/dinner_log_repository.dart';
import 'package:aaj_kya_pakayen/domain/repositories/dish_repository.dart';
import 'package:aaj_kya_pakayen/domain/repositories/pantry_repository.dart';
import 'package:aaj_kya_pakayen/domain/repositories/settings_repository.dart';
import 'package:aaj_kya_pakayen/domain/repositories/sync_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'providers.g.dart';

// Features depend on these domain-typed providers, never on DAOs.

@Riverpod(keepAlive: true)
AppDatabase appDatabase(Ref ref) {
  final db = AppDatabase.open();
  ref.onDispose(db.close);
  return db;
}

@Riverpod(keepAlive: true)
DishRepository dishRepository(Ref ref) =>
    DriftDishRepository(ref.watch(appDatabaseProvider));

@Riverpod(keepAlive: true)
PantryRepository pantryRepository(Ref ref) =>
    DriftPantryRepository(ref.watch(appDatabaseProvider));

@Riverpod(keepAlive: true)
DinnerLogRepository dinnerLogRepository(Ref ref) =>
    DriftDinnerLogRepository(ref.watch(appDatabaseProvider));

@Riverpod(keepAlive: true)
SettingsRepository settingsRepository(Ref ref) =>
    DriftSettingsRepository(ref.watch(appDatabaseProvider));

@Riverpod(keepAlive: true)
SyncRepository syncRepository(Ref ref) => const NoopSyncRepository();
