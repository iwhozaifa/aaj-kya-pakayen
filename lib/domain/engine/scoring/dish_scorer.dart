import 'dart:math';

import 'package:aaj_kya_pakayen/domain/engine/reason.dart';
import 'package:aaj_kya_pakayen/domain/engine/rules/pantry_stock.dart';
import 'package:aaj_kya_pakayen/domain/engine/rules/repeat_guard.dart';
import 'package:aaj_kya_pakayen/domain/engine/scoring/weights.dart';
import 'package:aaj_kya_pakayen/domain/entities/app_settings.dart';
import 'package:aaj_kya_pakayen/domain/entities/calendar_date.dart';
import 'package:aaj_kya_pakayen/domain/entities/dinner_log_entry.dart';
import 'package:aaj_kya_pakayen/domain/entities/dish.dart';
import 'package:aaj_kya_pakayen/domain/entities/pantry_batch.dart';
import 'package:aaj_kya_pakayen/domain/enums/cooking_style.dart';
import 'package:aaj_kya_pakayen/domain/enums/dish_type.dart';
import 'package:aaj_kya_pakayen/domain/enums/protein_type.dart';
import 'package:aaj_kya_pakayen/domain/enums/time_budget.dart';

final class ScoredDish {
  const new(this.dish, this.score, this.reasons);

  final Dish dish;
  final double score;

  /// Most convincing first.
  final List<Reason> reasons;
}

/// Soft scoring for dishes that already passed the hard rules.
final class DishScorer {
  factory({
    required DateTime date,
    required Iterable<DinnerLogEntry> history,
    required Map<int, Dish> dishesById,
    required Iterable<PantryBatch> pantry,
    required AppSettings settings,
  }) {
    final past = history.where((e) => date.daysSince(e.date) > 0).toList()
      ..sort((a, b) => b.date.compareTo(a.date));
    Dish? mainOf(DinnerLogEntry e) =>
        e.isOutside ? null : dishesById[e.mainDishId];

    ProteinType? lastProtein;
    for (final entry in past) {
      final protein = mainOf(entry)?.proteinType;
      if (protein != null) {
        lastProtein = protein;
        break;
      }
    }
    final window = settings.repeatWindowDays;
    return DishScorer._(
      stock: PantryStock.fromBatches(date: date, batches: pantry),
      guard: RepeatGuard.fromHistory(
        date: date,
        history: past,
        dishesById: dishesById,
        windowDays: window,
      ),
      timeBudget: settings.timeBudget,
      lastProtein: lastProtein,
      yesterdayStyle: [
        for (final e in past)
          if (date.daysSince(e.date) == 1) ?mainOf(e)?.cookingStyle,
      ].firstOrNull,
      recentStyles: {
        for (final e in past)
          if (date.daysSince(e.date) < window) ?mainOf(e)?.cookingStyle,
      },
    );
  }

  new _({
    required this.stock,
    required this.guard,
    required this.timeBudget,
    required this.lastProtein,
    required this.yesterdayStyle,
    required this.recentStyles,
  });

  final PantryStock stock;
  final RepeatGuard guard;
  final TimeBudget timeBudget;
  final ProteinType? lastProtein;
  final CookingStyle? yesterdayStyle;
  final Set<CookingStyle> recentStyles;

  ScoredDish score(Dish dish, {Random? random}) {
    var score = 0.0;
    final reasons = <Reason>[];

    final protein = dish.proteinType;
    if (protein != null) {
      final days = stock.oldestBatchDays(protein) ?? 0;
      score +=
          ScoreWeights.useItFirstPerDay *
          min(days, ScoreWeights.useItFirstMaxDays);
      if (days >= ScoreWeights.proteinInStockReasonMinDays) {
        reasons.add(Reason.proteinInStock(protein: protein, days: days));
      }
      final last = lastProtein;
      if (last == protein) {
        score += ScoreWeights.sameProtein;
      } else if (last != null) {
        reasons.add(Reason.differentProtein(previous: last));
      }
    }

    final style = dish.cookingStyle;
    if (style == yesterdayStyle) score += ScoreWeights.sameStyleAsYesterday;
    if (style != CookingStyle.other && !recentStyles.contains(style)) {
      score += ScoreWeights.freshStyle;
      reasons.add(Reason.freshStyle(style: style));
    }

    if (timeBudget != TimeBudget.elaborate) {
      if (timeBudget.allows(dish.prepMinutes)) {
        score += ScoreWeights.fitsTimeBudget;
        reasons.add(Reason.fitsTime(minutes: dish.prepMinutes));
      } else {
        score += ScoreWeights.overTimeBudget;
      }
    }

    if (dish.dishType == DishType.pulse) {
      reasons.add(Reason.servedWith(staple: dish.staplePairing));
    }

    final lastCooked = guard.daysSinceCooked(dish);
    score +=
        ScoreWeights.noveltyPerDay *
        min(
          lastCooked ?? ScoreWeights.noveltyMaxDays,
          ScoreWeights.noveltyMaxDays,
        );
    if (lastCooked != null &&
        lastCooked >= ScoreWeights.notCookedReasonMinDays) {
      reasons.add(Reason.notCookedFor(days: lastCooked));
    }

    if (random != null) score += random.nextDouble() * ScoreWeights.jitter;
    return ScoredDish(dish, score, reasons);
  }
}
