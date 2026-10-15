import 'package:aaj_kya_pakayen/domain/engine/reason.dart';
import 'package:aaj_kya_pakayen/domain/engine/scoring/dish_scorer.dart';
import 'package:aaj_kya_pakayen/domain/entities/app_settings.dart';
import 'package:aaj_kya_pakayen/domain/entities/dinner_log_entry.dart';
import 'package:aaj_kya_pakayen/domain/entities/dish.dart';
import 'package:aaj_kya_pakayen/domain/entities/pantry_batch.dart';
import 'package:aaj_kya_pakayen/domain/enums/cooking_style.dart';
import 'package:aaj_kya_pakayen/domain/enums/day_type.dart';
import 'package:aaj_kya_pakayen/domain/enums/dish_type.dart';
import 'package:aaj_kya_pakayen/domain/enums/protein_type.dart';
import 'package:aaj_kya_pakayen/domain/enums/staple_pairing.dart';
import 'package:aaj_kya_pakayen/domain/enums/time_budget.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fixtures.dart';

void main() {
  final chickenCurry = dish(1, type: DishType.chicken);
  final beefCurry = dish(2, type: DishType.beef);
  final chickenKarahi = dish(
    3,
    type: DishType.chicken,
    style: CookingStyle.karahi,
  );
  final quickVeg = dish(4, minutes: 25);
  final slowVeg = dish(5, minutes: 45);
  final daalChawal = dish(6, type: DishType.pulse, staple: StaplePairing.rice);
  final all = [
    chickenCurry,
    beefCurry,
    chickenKarahi,
    quickVeg,
    slowVeg,
    daalChawal,
  ];

  DishScorer scorer({
    List<DinnerLogEntry> history = const [],
    List<PantryBatch> pantry = const [],
    AppSettings settings = const AppSettings(),
  }) => DishScorer(
    date: today,
    history: history,
    dishesById: {for (final d in all) d.id: d},
    pantry: pantry,
    settings: settings,
  );

  double score(DishScorer s, Dish d) => s.score(d).score;
  List<Reason> reasons(DishScorer s, Dish d) => s.score(d).reasons;

  test('prefers protein that has waited longest in the pantry', () {
    final s = scorer(
      pantry: [
        batch(1, ProteinType.chicken, 2000, addedDaysAgo: 6),
        batch(2, ProteinType.beef, 2000),
      ],
    );
    expect(score(s, chickenCurry), greaterThan(score(s, beefCurry)));
    expect(
      reasons(s, chickenCurry),
      contains(
        const Reason.proteinInStock(protein: ProteinType.chicken, days: 6),
      ),
    );
    expect(reasons(s, beefCurry).whereType<ProteinInStockReason>(), isEmpty);
  });

  test('avoids the protein of the last non-veg day', () {
    final s = scorer(
      history: [
        cooked(1, DayType.vegDay, main: 4),
        cooked(2, DayType.nonVegDay, main: 1),
      ],
    );
    expect(score(s, beefCurry), greaterThan(score(s, chickenCurry)));
    expect(
      reasons(s, beefCurry),
      contains(const Reason.differentProtein(previous: ProteinType.chicken)),
    );
  });

  test('an outside dinner does not count as the last protein', () {
    final s = scorer(history: [orderedOutside(2)]);
    expect(score(s, beefCurry), score(s, chickenCurry));
  });

  test('avoids the cooking style cooked yesterday', () {
    final s = scorer(history: [cooked(1, DayType.nonVegDay, main: 3)]);
    expect(
      score(s, quickVeg.copyWith(id: 9)),
      greaterThan(
        score(s, quickVeg.copyWith(id: 9, cookingStyle: CookingStyle.karahi)),
      ),
    );
  });

  test('says when a style has not been cooked this week', () {
    final s = scorer(history: [cooked(9, DayType.nonVegDay, main: 3)]);
    expect(
      reasons(s, chickenKarahi),
      contains(const Reason.freshStyle(style: CookingStyle.karahi)),
    );
    final recent = scorer(history: [cooked(3, DayType.nonVegDay, main: 3)]);
    expect(
      reasons(recent, chickenKarahi).whereType<FreshStyleReason>(),
      isEmpty,
    );
    expect(
      reasons(
        s,
        dish(10, style: CookingStyle.other),
      ).whereType<FreshStyleReason>(),
      isEmpty,
    );
  });

  test('respects the time budget', () {
    final s = scorer(settings: const AppSettings(timeBudget: TimeBudget.quick));
    expect(score(s, quickVeg), greaterThan(score(s, slowVeg)));
    expect(reasons(s, quickVeg), contains(const Reason.fitsTime(minutes: 25)));
    expect(reasons(s, slowVeg).whereType<FitsTimeReason>(), isEmpty);

    final relaxed = scorer(
      settings: const AppSettings(timeBudget: TimeBudget.elaborate),
    );
    expect(score(relaxed, quickVeg), score(relaxed, slowVeg));
    expect(reasons(relaxed, quickVeg).whereType<FitsTimeReason>(), isEmpty);
  });

  test('pulse dishes say what they are eaten with', () {
    expect(
      reasons(scorer(), daalChawal),
      contains(const Reason.servedWith(staple: StaplePairing.rice)),
    );
    expect(reasons(scorer(), quickVeg).whereType<ServedWithReason>(), isEmpty);
  });

  test('favours dishes not cooked for a long time', () {
    final s = scorer(history: [cooked(25, DayType.vegDay, main: 4)]);
    final fresh = quickVeg.copyWith(id: 11);
    expect(score(s, fresh), greaterThan(score(s, quickVeg)));
    expect(reasons(s, quickVeg), contains(const Reason.notCookedFor(days: 25)));
  });
}
