import 'dart:math';

import 'package:aaj_kya_pakayen/domain/engine/reason.dart';
import 'package:aaj_kya_pakayen/domain/engine/rules/day_type_rule.dart';
import 'package:aaj_kya_pakayen/domain/engine/rules/side_picker.dart';
import 'package:aaj_kya_pakayen/domain/engine/scoring/dish_scorer.dart';
import 'package:aaj_kya_pakayen/domain/engine/suggestion.dart';
import 'package:aaj_kya_pakayen/domain/entities/dish.dart';
import 'package:aaj_kya_pakayen/domain/enums/day_type.dart';
import 'package:aaj_kya_pakayen/domain/enums/protein_type.dart';

export 'package:aaj_kya_pakayen/domain/engine/suggestion.dart';

/// Picks tonight's dinner. Pure and deterministic: the same request always
/// gives the same result.
///
/// 1. Day type: alternation plus the swap override.
/// 2. Hard filters: active, enabled cuisine, no repeat within the window,
///    day type, and (meat) enough stock for the household.
/// 3. Soft score with a date-seeded jitter, best first.
/// 4. "Show me another" rotates the ranking by one per tap.
/// 5. Top three, each meat main with at most one curated side. With no
///    cookable meat dish on a non-veg day, suggest ordering outside.
final class SuggestionEngine {
  const new();

  static const maxSuggestions = 3;

  /// Seed for the day's jitter, e.g. 2026-10-15 → 20261015 * 31.
  static int seedFor(DateTime date) =>
      (date.year * 10000 + date.month * 100 + date.day) * 31;

  SuggestionResult suggest(SuggestionRequest request) {
    final settings = request.settings;
    final day = resolveDayType(
      date: request.date,
      history: request.history,
      settings: settings,
    );
    final dishesById = {for (final d in request.dishes) d.id: d};
    final scorer = DishScorer(
      date: request.date,
      history: request.history,
      dishesById: dishesById,
      pantry: request.pantry,
      settings: settings,
    );

    bool eligible(Dish d) =>
        d.isActive &&
        settings.enabledCuisines.contains(d.cuisine) &&
        scorer.guard.allows(d);
    bool cookable(Dish d) =>
        scorer.stock.canCook(d, householdSize: settings.householdSize);

    final vegDay = day.dayType == DayType.vegDay;
    final allowed = request.dishes
        .where((d) => eligible(d) && d.isVeg == vegDay)
        .toList();
    final candidates = allowed.where(cookable).toList()
      ..sort((a, b) => a.id.compareTo(b.id));

    if (candidates.isEmpty && !vegDay) {
      final restock = <ProteinType>{for (final d in allowed) ?d.proteinType};
      return SuggestionResult(
        day: day,
        suggestions: [
          OutsideSuggestion(
            restock: restock,
            reasons: [
              if (restock.isNotEmpty) Reason.restock(proteins: restock),
            ],
          ),
        ],
      );
    }

    final random = Random(seedFor(request.date));
    final ranked = [for (final d in candidates) scorer.score(d, random: random)]
      ..sort(
        (a, b) => a.score != b.score
            ? b.score.compareTo(a.score)
            : a.dish.id.compareTo(b.dish.id),
      );
    final offset = ranked.isEmpty ? 0 : request.anotherCount % ranked.length;
    final rotated = [...ranked.skip(offset), ...ranked.take(offset)];

    return SuggestionResult(
      day: day,
      suggestions: [
        for (final scored in rotated.take(maxSuggestions))
          HomeSuggestion(
            main: scored.dish,
            score: scored.score,
            reasons: scored.reasons,
            side: pickSide(
              main: scored.dish,
              pairings: request.pairings,
              dishesById: dishesById,
              allowed: (side) => side.id != scored.dish.id && eligible(side),
            ),
          ),
      ],
    );
  }
}
