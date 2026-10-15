import 'package:aaj_kya_pakayen/domain/engine/reason.dart';
import 'package:aaj_kya_pakayen/domain/engine/suggestion.dart';
import 'package:aaj_kya_pakayen/domain/engine/suggestion_engine.dart';
import 'package:aaj_kya_pakayen/domain/entities/app_settings.dart';
import 'package:aaj_kya_pakayen/domain/entities/dinner_log_entry.dart';
import 'package:aaj_kya_pakayen/domain/entities/dish.dart';
import 'package:aaj_kya_pakayen/domain/entities/dish_pairing.dart';
import 'package:aaj_kya_pakayen/domain/entities/pantry_batch.dart';
import 'package:aaj_kya_pakayen/domain/enums/day_type.dart';
import 'package:aaj_kya_pakayen/domain/enums/dish_type.dart';
import 'package:aaj_kya_pakayen/domain/enums/protein_type.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fixtures.dart';

void main() {
  const engine = SuggestionEngine();

  final vegA = dish(1, side: true);
  final vegB = dish(2, side: true);
  final daal = dish(3, type: DishType.pulse);
  final vegC = dish(4);
  final chickenKarahi = dish(10, type: DishType.chicken, group: 'karahi');
  final whiteKarahi = dish(11, type: DishType.chicken, group: 'karahi');
  final beefCurry = dish(12, type: DishType.beef, grams: 250);
  final minceCurry = dish(13, type: DishType.mince, grams: 100);
  final catalogue = [
    vegA,
    vegB,
    daal,
    vegC,
    chickenKarahi,
    whiteKarahi,
    beefCurry,
    minceCurry,
  ];
  const pairings = [
    DishPairing(mainDishId: 10, sideDishId: 1),
    DishPairing(mainDishId: 10, sideDishId: 2, priority: 1),
  ];
  final plentyOfMeat = [
    batch(1, ProteinType.chicken, 5000),
    batch(2, ProteinType.beef, 5000),
    batch(3, ProteinType.mince, 5000),
  ];
  // Yesterday was veg, so tonight is naturally non-veg.
  final yesterdayVeg = [cooked(1, DayType.vegDay, main: 4)];

  SuggestionResult suggest({
    List<Dish>? dishes,
    List<DinnerLogEntry>? history,
    List<PantryBatch>? pantry,
    AppSettings settings = const AppSettings(),
    DateTime? date,
    int another = 0,
  }) => engine.suggest(
    SuggestionRequest(
      date: date ?? today,
      dishes: dishes ?? catalogue,
      pairings: pairings,
      history: history ?? yesterdayVeg,
      pantry: pantry ?? plentyOfMeat,
      settings: settings,
      anotherCount: another,
    ),
  );

  List<Dish> mains(SuggestionResult r) =>
      r.suggestions.whereType<HomeSuggestion>().map((s) => s.main).toList();

  test('veg day suggests up to three veg or pulse dishes, no sides', () {
    final r = suggest(history: [cooked(1, DayType.nonVegDay, main: 12)]);
    expect(r.dayType, DayType.vegDay);
    expect(r.suggestions, hasLength(3));
    for (final s in r.suggestions.cast<HomeSuggestion>()) {
      expect(s.main.isVeg, isTrue);
      expect(s.side, isNull);
    }
    expect(r.canOrderOutside, isFalse);
  });

  test('non-veg day suggests meat dishes that the pantry can cover', () {
    final r = suggest(
      pantry: [batch(1, ProteinType.chicken, 800)],
      settings: const AppSettings(householdSize: 4),
    );
    expect(r.dayType, DayType.nonVegDay);
    expect(mains(r), unorderedEquals([chickenKarahi, whiteKarahi]));
    expect(r.canOrderOutside, isTrue);
  });

  test('a meat main gets its curated side', () {
    final r = suggest(pantry: [batch(1, ProteinType.chicken, 5000)]);
    final karahi = r.suggestions.cast<HomeSuggestion>().firstWhere(
      (s) => s.main == chickenKarahi,
    );
    expect(karahi.side, vegA);
  });

  test('a recently cooked side falls back to the next pairing', () {
    final r = suggest(
      pantry: [batch(1, ProteinType.chicken, 5000)],
      history: [cooked(1, DayType.vegDay, main: 1)],
    );
    final karahi = r.suggestions.cast<HomeSuggestion>().firstWhere(
      (s) => s.main == chickenKarahi,
    );
    expect(karahi.side, vegB);
  });

  test('pantry shortage makes ordering outside the suggestion', () {
    final r = suggest(pantry: [batch(1, ProteinType.chicken, 100)]);
    final outside = r.suggestions.single as OutsideSuggestion;
    expect(outside.restock, {
      ProteinType.chicken,
      ProteinType.beef,
      ProteinType.mince,
    });
    expect(outside.reasons, [
      const Reason.restock(
        proteins: {ProteinType.chicken, ProteinType.beef, ProteinType.mince},
      ),
    ]);
  });

  test('restock only names proteins of dishes that are allowed tonight', () {
    final r = suggest(
      dishes: [vegC, chickenKarahi, whiteKarahi],
      pantry: const [],
      history: [
        cooked(1, DayType.vegDay, main: 4),
        cooked(3, DayType.nonVegDay, main: 10),
      ],
    );
    final outside = r.suggestions.single as OutsideSuggestion;
    expect(outside.restock, isEmpty);
    expect(outside.reasons, isEmpty);
  });

  test('never repeats a dish or its variant within the window', () {
    final r = suggest(
      history: [...yesterdayVeg, cooked(3, DayType.nonVegDay, main: 11)],
    );
    expect(mains(r), isNot(contains(chickenKarahi)));
    expect(mains(r), isNot(contains(whiteKarahi)));
  });

  test('skips inactive dishes and cuisines that are not enabled', () {
    final r = suggest(
      dishes: [
        vegC,
        beefCurry.copyWith(isActive: false),
        chickenKarahi.copyWith(cuisine: 'chinese'),
        minceCurry,
      ],
    );
    expect(mains(r), [minceCurry]);
  });

  test("swap override suggests the other type for tonight", () {
    final r = suggest(
      settings: AppSettings(
        dayTypeOverride: DayTypeOverride(date: today, dayType: DayType.vegDay),
      ),
    );
    expect(r.dayType, DayType.vegDay);
    expect(r.isOverride, isTrue);
    expect(mains(r).every((d) => d.isVeg), isTrue);
  });

  test('pulse dishes carry what they are eaten with', () {
    final r = suggest(
      dishes: [daal, vegC],
      history: [cooked(1, DayType.nonVegDay, main: 12)],
    );
    final s = r.suggestions.cast<HomeSuggestion>().firstWhere(
      (s) => s.main == daal,
    );
    expect(s.reasons.whereType<ServedWithReason>(), hasLength(1));
  });

  group('seeded ranking', () {
    test('the same day always gives the same answer', () {
      expect(mains(suggest()), mains(suggest()));
    });

    test('different days can give different answers', () {
      final tops = {
        for (var d = 0; d < 14; d++)
          mains(suggest(date: today.add(Duration(days: d)))).first,
      };
      expect(tops.length, greaterThan(1));
    });

    test('"show me another" moves to the next dish and wraps around', () {
      final first = mains(suggest());
      final second = mains(suggest(another: 1));
      expect(second.first, isNot(first.first));
      expect(second.first, first[1]);

      final count = mains(suggest(another: 100)).length;
      expect(count, lessThanOrEqualTo(3));
      // 4 cookable mains: offset 4 wraps back to the start.
      expect(mains(suggest(another: 4)), first);
    });
  });
}
