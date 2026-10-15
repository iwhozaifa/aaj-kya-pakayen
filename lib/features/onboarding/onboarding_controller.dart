import 'package:aaj_kya_pakayen/core/utils/clock.dart';
import 'package:aaj_kya_pakayen/data/providers.dart';
import 'package:aaj_kya_pakayen/domain/entities/calendar_date.dart';
import 'package:aaj_kya_pakayen/domain/enums/protein_type.dart';
import 'package:aaj_kya_pakayen/domain/repositories/settings_repository.dart';
import 'package:aaj_kya_pakayen/domain/usecases/complete_onboarding.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'onboarding_controller.g.dart';

/// Saves the first-run answers. The router then leaves onboarding by
/// itself, because it watches `onboardingComplete`.
class OnboardingActions {
  new({required this._complete, required this._settings, required this._clock});

  final CompleteOnboarding _complete;
  final SettingsRepository _settings;
  final DateTime Function() _clock;

  /// Saves the language at once so the next questions are asked in it.
  Future<void> chooseLanguage(String languageCode) async {
    final settings = await _settings.load();
    await _settings.save(settings.copyWith(languageCode: languageCode));
  }

  Future<void> finish({
    required String languageCode,
    required int householdSize,
    required Map<ProteinType, int> stock,
  }) => _complete(
    languageCode: languageCode,
    householdSize: householdSize,
    stock: stock,
    today: _clock().dateOnly,
  );
}

@Riverpod(keepAlive: true)
OnboardingActions onboardingActions(Ref ref) => OnboardingActions(
  complete: CompleteOnboarding(
    settings: ref.watch(settingsRepositoryProvider),
    pantry: ref.watch(pantryRepositoryProvider),
  ),
  settings: ref.watch(settingsRepositoryProvider),
  clock: ref.watch(clockProvider),
);
