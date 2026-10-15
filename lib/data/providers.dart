import 'package:aaj_kya_pakayen/core/l10n/generated/app_localizations.dart';
import 'package:aaj_kya_pakayen/data/db/app_database.dart';
import 'package:aaj_kya_pakayen/data/notifications/local_notifications_reminder_scheduler.dart';
import 'package:aaj_kya_pakayen/data/repositories_impl/drift_dinner_log_repository.dart';
import 'package:aaj_kya_pakayen/data/repositories_impl/drift_dish_repository.dart';
import 'package:aaj_kya_pakayen/data/repositories_impl/drift_pantry_repository.dart';
import 'package:aaj_kya_pakayen/data/repositories_impl/drift_settings_repository.dart';
import 'package:aaj_kya_pakayen/data/repositories_impl/noop_sync_repository.dart';
import 'package:aaj_kya_pakayen/domain/entities/app_settings.dart';
import 'package:aaj_kya_pakayen/domain/entities/dinner_log_entry.dart';
import 'package:aaj_kya_pakayen/domain/entities/dish.dart';
import 'package:aaj_kya_pakayen/domain/entities/pantry_batch.dart';
import 'package:aaj_kya_pakayen/domain/repositories/dinner_log_repository.dart';
import 'package:aaj_kya_pakayen/domain/repositories/dish_repository.dart';
import 'package:aaj_kya_pakayen/domain/repositories/pantry_repository.dart';
import 'package:aaj_kya_pakayen/domain/repositories/settings_repository.dart';
import 'package:aaj_kya_pakayen/domain/repositories/sync_repository.dart';
import 'package:aaj_kya_pakayen/domain/services/reminder_scheduler.dart';
import 'package:flutter/widgets.dart';
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

@Riverpod(keepAlive: true)
ReminderScheduler reminderScheduler(Ref ref) =>
    LocalNotificationsReminderScheduler(
      // Android names the channel once, so it shows both languages.
      channelName: [
        for (final code in ['ur', 'en'])
          lookupAppLocalizations(Locale(code)).reminderChannel,
      ].join(' / '),
    );

@Riverpod(keepAlive: true)
Stream<AppSettings> appSettings(Ref ref) =>
    ref.watch(settingsRepositoryProvider).watch();

// Change feeds: screens watch these to refresh when data changes elsewhere.

@Riverpod(keepAlive: true)
Stream<List<DinnerLogEntry>> recentDinners(Ref ref) =>
    ref.watch(dinnerLogRepositoryProvider).watchRecent(limit: 60);

@Riverpod(keepAlive: true)
Stream<List<PantryBatch>> pantryBatches(Ref ref) =>
    ref.watch(pantryRepositoryProvider).watchBatches();

@Riverpod(keepAlive: true)
Stream<List<Dish>> activeDishes(Ref ref) =>
    ref.watch(dishRepositoryProvider).watchAll();
