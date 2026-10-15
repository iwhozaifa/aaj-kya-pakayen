import 'package:aaj_kya_pakayen/domain/engine/suggestion_engine.dart';
import 'package:aaj_kya_pakayen/domain/entities/app_settings.dart';
import 'package:aaj_kya_pakayen/domain/entities/dish_pairing.dart';
import 'package:aaj_kya_pakayen/domain/enums/day_type.dart';
import 'package:aaj_kya_pakayen/domain/enums/dish_type.dart';
import 'package:aaj_kya_pakayen/domain/enums/protein_type.dart';
import 'package:aaj_kya_pakayen/domain/repositories/dinner_log_repository.dart';
import 'package:aaj_kya_pakayen/domain/repositories/dish_repository.dart';
import 'package:aaj_kya_pakayen/domain/repositories/pantry_repository.dart';
import 'package:aaj_kya_pakayen/domain/repositories/settings_repository.dart';
import 'package:aaj_kya_pakayen/domain/usecases/get_tonight_suggestions.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../engine/fixtures.dart';

class _Dishes extends Mock implements DishRepository;

class _Log extends Mock implements DinnerLogRepository;

class _Pantry extends Mock implements PantryRepository;

class _Settings extends Mock implements SettingsRepository;

void main() {
  late _Dishes dishes;
  late _Log log;
  late _Pantry pantry;
  late _Settings settings;
  late GetTonightSuggestions getSuggestions;

  final veg = dish(1);
  final chicken = dish(2, type: DishType.chicken);
  final evening = DateTime(2026, 10, 15, 19, 45);

  setUpAll(() => registerFallbackValue(DateTime(2026)));

  setUp(() {
    dishes = _Dishes();
    log = _Log();
    pantry = _Pantry();
    settings = _Settings();
    getSuggestions = GetTonightSuggestions(
      dishes: dishes,
      log: log,
      pantry: pantry,
      settings: settings,
    );
    when(() => settings.load()).thenAnswer((_) async => const AppSettings());
    when(() => dishes.getAll()).thenAnswer((_) async => [veg, chicken]);
    when(() => dishes.getPairings())
        .thenAnswer((_) async => const <DishPairing>[]);
    when(() => log.getSince(any())).thenAnswer((_) async => []);
    when(() => log.getLatest()).thenAnswer((_) async => null);
    when(() => pantry.getBatches())
        .thenAnswer((_) async => [batch(1, ProteinType.chicken, 5000)]);
  });

  test('feeds repository data to the engine', () async {
    when(() => log.getSince(any()))
        .thenAnswer((_) async => [cooked(1, DayType.vegDay, main: 1)]);

    final result = await getSuggestions(date: evening);

    expect(result.dayType, DayType.nonVegDay);
    expect((result.suggestions.single as HomeSuggestion).main, chicken);
  });

  test('looks back at least 30 days, or the repeat window if longer', () async {
    await getSuggestions(date: evening);
    verify(() => log.getSince(DateTime(2026, 9, 15))).called(1);

    when(() => settings.load())
        .thenAnswer((_) async => const AppSettings(repeatWindowDays: 45));
    await getSuggestions(date: evening);
    verify(() => log.getSince(DateTime(2026, 8, 31))).called(1);
  });

  test(
    'flips from the latest dinner even if it is older than the lookback',
    () async {
      when(() => log.getLatest())
          .thenAnswer((_) async => cooked(90, DayType.nonVegDay, main: 2));

      final result = await getSuggestions(date: evening);

      expect(result.dayType, DayType.vegDay);
    },
  );

  test('passes "show me another" through to the engine', () async {
    when(() => dishes.getAll())
        .thenAnswer((_) async => [veg, dish(3), dish(4)]);
    final first = await getSuggestions(date: evening);
    final next = await getSuggestions(date: evening, anotherCount: 1);

    final firstTop = (first.suggestions.first as HomeSuggestion).main;
    final nextTop = (next.suggestions.first as HomeSuggestion).main;
    expect(nextTop, isNot(firstTop));
  });
}
