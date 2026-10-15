import 'package:aaj_kya_pakayen/domain/entities/app_settings.dart';
import 'package:aaj_kya_pakayen/domain/entities/pantry_batch.dart';
import 'package:aaj_kya_pakayen/domain/enums/protein_type.dart';
import 'package:aaj_kya_pakayen/domain/repositories/pantry_repository.dart';
import 'package:aaj_kya_pakayen/domain/repositories/settings_repository.dart';
import 'package:aaj_kya_pakayen/domain/usecases/complete_onboarding.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _Settings extends Mock implements SettingsRepository;

class _Pantry extends Mock implements PantryRepository;

void main() {
  late _Settings settings;
  late _Pantry pantry;
  late CompleteOnboarding completeOnboarding;
  final today = DateTime(2026, 10, 15);

  setUpAll(() => registerFallbackValue(const AppSettings()));

  setUp(() {
    settings = _Settings();
    pantry = _Pantry();
    completeOnboarding = CompleteOnboarding(settings: settings, pantry: pantry);
    when(() => settings.load())
        .thenAnswer((_) async => const AppSettings(reminderEnabled: true));
    when(() => settings.save(any())).thenAnswer((_) async {});
    when(
      () => pantry.addPurchase(
        proteinType: any(named: 'proteinType'),
        grams: any(named: 'grams'),
        addedOn: any(named: 'addedOn'),
      ),
    ).thenAnswer(
      (i) async => PantryBatch(
        id: 1,
        proteinType: i.namedArguments[#proteinType] as ProteinType,
        quantityGrams: i.namedArguments[#grams] as int,
        addedOn: today,
      ),
    );
  });

  test('saves language and household and marks onboarding done', () async {
    await completeOnboarding(
      languageCode: 'en',
      householdSize: 6,
      stock: const {},
      today: today,
    );

    final saved =
        verify(() => settings.save(captureAny())).captured.single
            as AppSettings;
    expect(saved.languageCode, 'en');
    expect(saved.householdSize, 6);
    expect(saved.onboardingComplete, isTrue);
    expect(saved.reminderEnabled, isTrue, reason: 'other settings kept');
    verifyNever(
      () => pantry.addPurchase(
        proteinType: any(named: 'proteinType'),
        grams: any(named: 'grams'),
        addedOn: any(named: 'addedOn'),
      ),
    );
  });

  test('records the meat already in the freezer, skipping zeros', () async {
    await completeOnboarding(
      languageCode: 'ur',
      householdSize: 99,
      stock: const {
        ProteinType.chicken: 1500,
        ProteinType.beef: 0,
        ProteinType.mince: 500,
      },
      today: today,
    );

    verify(
      () => pantry.addPurchase(
        proteinType: ProteinType.chicken,
        grams: 1500,
        addedOn: today,
      ),
    ).called(1);
    verify(
      () => pantry.addPurchase(
        proteinType: ProteinType.mince,
        grams: 500,
        addedOn: today,
      ),
    ).called(1);
    verifyNoMoreInteractions(pantry);
    final saved =
        verify(() => settings.save(captureAny())).captured.single
            as AppSettings;
    expect(saved.householdSize, AppSettings.householdSizes.max);
  });
}
