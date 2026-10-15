import 'dart:math';

import 'package:aaj_kya_pakayen/data/seed/pakistani_dishes.dart';
import 'package:aaj_kya_pakayen/domain/engine/suggestion_engine.dart';
import 'package:aaj_kya_pakayen/domain/entities/app_settings.dart';
import 'package:aaj_kya_pakayen/domain/entities/calendar_date.dart';
import 'package:aaj_kya_pakayen/domain/entities/dinner_log_entry.dart';
import 'package:aaj_kya_pakayen/domain/entities/pantry_batch.dart';
import 'package:aaj_kya_pakayen/domain/enums/day_type.dart';
import 'package:aaj_kya_pakayen/domain/enums/dinner_source.dart';
import 'package:aaj_kya_pakayen/domain/enums/dish_type.dart';
import 'package:aaj_kya_pakayen/domain/enums/protein_type.dart';
import 'package:flutter_test/flutter_test.dart';

/// Property-style checks: simulate a household cooking from the real seed
/// catalogue for 60 days and assert every hard rule on every day.
void main() {
  const engine = SuggestionEngine();
  const days = 60;
  final dishesById = {for (final d in pakistaniDishes) d.id: d};
  final start = DateTime(2026);

  for (var run = 0; run < 20; run++) {
    test('household simulation #$run keeps every hard rule', () {
      final rng = Random(run);
      final settings = AppSettings(
        householdSize: 2 + rng.nextInt(6),
        repeatWindowDays: 3 + rng.nextInt(8),
      );
      final history = <DinnerLogEntry>[];
      final pantry = <PantryBatch>[];
      var nextBatchId = 1;
      var outsideNights = 0;

      for (var day = 0; day < days; day++) {
        final date = start.add(Duration(days: day));

        // Shopping: now and then buy a random protein.
        if (rng.nextDouble() < 0.35) {
          pantry.add(
            PantryBatch(
              id: nextBatchId++,
              proteinType: ProteinType.values[rng.nextInt(4)],
              quantityGrams: 500 + rng.nextInt(4) * 500,
              addedOn: date,
              updatedAt: date,
            ),
          );
        }

        // Sometimes the cook swaps tonight's type.
        final swap = rng.nextDouble() < 0.1;
        final natural = history.isEmpty
            ? DayType.vegDay
            : history.last.dayType.flipped;
        final tonightSettings = swap
            ? settings.copyWith(
                dayTypeOverride: DayTypeOverride(
                  date: date,
                  dayType: natural.flipped,
                ),
              )
            : settings;

        final request = SuggestionRequest(
          date: date,
          dishes: pakistaniDishes,
          pairings: pakistaniPairings,
          history: history,
          pantry: pantry,
          settings: tonightSettings,
        );
        final result = engine.suggest(request);

        // Alternation (with the swap honoured).
        expect(result.dayType, swap ? natural.flipped : natural);
        // Determinism.
        expect(
          engine.suggest(request).suggestions.map(_describe),
          result.suggestions.map(_describe),
        );
        expect(result.suggestions, isNotEmpty);
        expect(result.suggestions.length, lessThanOrEqualTo(3));

        final homes = result.suggestions.whereType<HomeSuggestion>().toList();
        expect(homes.map((s) => s.main.id).toSet(), hasLength(homes.length));
        for (final s in homes) {
          final main = s.main;
          // Day type.
          expect(main.isVeg, result.dayType == DayType.vegDay);
          // No repeats of main or side (or their variants) in the window.
          for (final dish in [main, ?s.side]) {
            for (final past in history) {
              final ago = date.daysSince(past.date);
              if (ago >= settings.repeatWindowDays) continue;
              final pastKeys = past.dishIds.map(
                (id) => dishesById[id]!.variantKey,
              );
              expect(pastKeys, isNot(contains(dish.variantKey)));
            }
          }
          // Pantry covers the household.
          final protein = main.proteinType;
          if (protein != null) {
            final stock = pantry
                .where((b) => b.proteinType == protein)
                .fold(0, (sum, b) => sum + b.quantityGrams);
            expect(
              stock,
              greaterThanOrEqualTo(
                main.proteinGramsFor(householdSize: settings.householdSize),
              ),
            );
          }
          // At most one side: a curated vegetable side of a meat main.
          final side = s.side;
          if (side != null) {
            expect(main.isVeg, isFalse);
            expect(side.dishType, DishType.vegetable);
            expect(
              pakistaniPairings.any(
                (p) => p.mainDishId == main.id && p.sideDishId == side.id,
              ),
              isTrue,
            );
          }
        }
        if (homes.isEmpty) {
          expect(result.dayType, DayType.nonVegDay);
          expect(result.suggestions.single, isA<OutsideSuggestion>());
        }

        // Cook one of the suggestions and log it.
        final pick = result.suggestions[rng.nextInt(result.suggestions.length)];
        switch (pick) {
          case HomeSuggestion(:final main, :final side):
            history.add(
              DinnerLogEntry(
                date: date,
                dayType: result.dayType,
                source: DinnerSource.home,
                mainDishId: main.id,
                sideDishId: side?.id,
              ),
            );
            _deductFifo(
              pantry,
              main.proteinType,
              main.proteinGramsFor(householdSize: settings.householdSize),
            );
          case OutsideSuggestion():
            outsideNights++;
            history.add(
              DinnerLogEntry(
                date: date,
                dayType: result.dayType,
                source: DinnerSource.outside,
              ),
            );
        }
      }
      // Sanity: the simulation exercised home cooking, not just takeaway.
      expect(outsideNights, lessThan(days));
    });
  }
}

String _describe(Suggestion s) => switch (s) {
  HomeSuggestion(:final main, :final side) => '${main.id}+${side?.id}',
  OutsideSuggestion(:final restock) => 'outside$restock',
};

void _deductFifo(List<PantryBatch> pantry, ProteinType? protein, int grams) {
  if (protein == null) return;
  var left = grams;
  for (var i = 0; i < pantry.length && left > 0; i++) {
    final b = pantry[i];
    if (b.proteinType != protein || b.quantityGrams == 0) continue;
    final take = min(left, b.quantityGrams);
    pantry[i] = b.copyWith(quantityGrams: b.quantityGrams - take);
    left -= take;
  }
}
