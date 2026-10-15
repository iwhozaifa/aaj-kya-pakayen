import 'package:aaj_kya_pakayen/data/db/app_database.dart';
import 'package:aaj_kya_pakayen/data/providers.dart';
import 'package:aaj_kya_pakayen/data/repositories_impl/drift_dinner_log_repository.dart';
import 'package:aaj_kya_pakayen/data/repositories_impl/drift_dish_repository.dart';
import 'package:aaj_kya_pakayen/data/repositories_impl/drift_pantry_repository.dart';
import 'package:aaj_kya_pakayen/data/repositories_impl/drift_settings_repository.dart';
import 'package:aaj_kya_pakayen/data/repositories_impl/noop_sync_repository.dart';
import 'package:aaj_kya_pakayen/domain/entities/app_settings.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/test_database.dart';

void main() {
  late AppDatabase db;
  late ProviderContainer container;

  setUp(() {
    db = newTestDatabase();
    container = ProviderContainer.test(
      overrides: [appDatabaseProvider.overrideWithValue(db)],
    );
  });
  tearDown(() => db.close());

  test('repositories are drift-backed and share the database', () async {
    expect(container.read(dishRepositoryProvider), isA<DriftDishRepository>());
    expect(
      container.read(pantryRepositoryProvider),
      isA<DriftPantryRepository>(),
    );
    expect(
      container.read(dinnerLogRepositoryProvider),
      isA<DriftDinnerLogRepository>(),
    );
    expect(
      container.read(settingsRepositoryProvider),
      isA<DriftSettingsRepository>(),
    );
    expect(container.read(syncRepositoryProvider), isA<NoopSyncRepository>());

    await container
        .read(settingsRepositoryProvider)
        .save(const AppSettings(householdSize: 9));
    expect((await DriftSettingsRepository(db).load()).householdSize, 9);
  });
}
