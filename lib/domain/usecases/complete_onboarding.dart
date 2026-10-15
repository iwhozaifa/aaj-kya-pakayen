import 'package:aaj_kya_pakayen/domain/enums/protein_type.dart';
import 'package:aaj_kya_pakayen/domain/repositories/pantry_repository.dart';
import 'package:aaj_kya_pakayen/domain/repositories/settings_repository.dart';

/// Saves the first-run answers: language, household size and the meat
/// already at home (stored as purchases made today).
class CompleteOnboarding {
  new({required this._settings, required this._pantry});

  final SettingsRepository _settings;
  final PantryRepository _pantry;

  Future<void> call({
    required String languageCode,
    required int householdSize,
    required Map<ProteinType, int> stock,
    required DateTime today,
  }) async {
    for (final MapEntry(key: protein, value: grams) in stock.entries) {
      if (grams <= 0) continue;
      await _pantry.addPurchase(
        proteinType: protein,
        grams: grams,
        addedOn: today,
      );
    }
    final settings = await _settings.load();
    await _settings.save(
      settings
          .withHouseholdSize(householdSize)
          .copyWith(languageCode: languageCode, onboardingComplete: true),
    );
  }
}
