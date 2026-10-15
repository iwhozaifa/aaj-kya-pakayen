import 'package:aaj_kya_pakayen/core/utils/clock.dart';
import 'package:aaj_kya_pakayen/data/db/app_database.dart';
import 'package:aaj_kya_pakayen/data/providers.dart';
import 'package:aaj_kya_pakayen/domain/enums/protein_type.dart';
import 'package:aaj_kya_pakayen/features/onboarding/onboarding_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/test_database.dart';

void main() {
  late AppDatabase db;
  late ProviderContainer container;

  setUp(() {
    db = newTestDatabase();
    container = ProviderContainer.test(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        clockProvider.overrideWithValue(() => DateTime(2026, 10, 15, 18)),
      ],
    );
  });
  tearDown(() => db.close());

  test('finishing onboarding saves the answers and the meat stock', () async {
    await container
        .read(onboardingActionsProvider)
        .finish(
          languageCode: 'en',
          householdSize: 5,
          stock: const {ProteinType.chicken: 1000},
        );

    final settings = await container.read(settingsRepositoryProvider).load();
    expect(settings.onboardingComplete, isTrue);
    expect(settings.householdSize, 5);
    expect(settings.languageCode, 'en');

    final batches = await container.read(pantryRepositoryProvider).getBatches();
    expect(batches.single.proteinType, ProteinType.chicken);
    expect(batches.single.quantityGrams, 1000);
    expect(batches.single.addedOn, DateTime(2026, 10, 15));
  });
}
