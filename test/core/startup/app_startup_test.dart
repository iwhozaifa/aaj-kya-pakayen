import 'package:aaj_kya_pakayen/core/startup/app_startup.dart';
import 'package:aaj_kya_pakayen/data/db/app_database.dart';
import 'package:aaj_kya_pakayen/data/providers.dart';
import 'package:aaj_kya_pakayen/data/seed/pakistani_dishes.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/test_database.dart';

void main() {
  late AppDatabase db;

  setUp(() => db = newTestDatabase());
  tearDown(() => db.close());

  test('startup seeds the dish catalogue', () async {
    final container = ProviderContainer.test(
      overrides: [appDatabaseProvider.overrideWithValue(db)],
    );

    await container.read(appStartupProvider.future);

    final dishes = await container.read(dishRepositoryProvider).getAll();
    expect(dishes, hasLength(pakistaniDishes.length));
  });

  test('startup loads settings so the first screen is the right one', () async {
    final container = ProviderContainer.test(
      overrides: [appDatabaseProvider.overrideWithValue(db)],
    );

    await container.read(appStartupProvider.future);

    expect(container.read(appSettingsProvider).hasValue, isTrue);
  });
}
