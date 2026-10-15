import 'package:aaj_kya_pakayen/domain/engine/reason.dart';
import 'package:aaj_kya_pakayen/domain/engine/rules/day_type_rule.dart';
import 'package:aaj_kya_pakayen/domain/entities/app_settings.dart';
import 'package:aaj_kya_pakayen/domain/entities/dinner_log_entry.dart';
import 'package:aaj_kya_pakayen/domain/entities/dish.dart';
import 'package:aaj_kya_pakayen/domain/entities/dish_pairing.dart';
import 'package:aaj_kya_pakayen/domain/entities/pantry_batch.dart';
import 'package:aaj_kya_pakayen/domain/enums/day_type.dart';
import 'package:aaj_kya_pakayen/domain/enums/protein_type.dart';

/// Everything the engine needs; it reads nothing else.
final class SuggestionRequest {
  const new({
    required this.date,
    required this.dishes,
    required this.pairings,
    required this.history,
    required this.pantry,
    required this.settings,
    this.anotherCount = 0,
  });

  final DateTime date;
  final List<Dish> dishes;
  final List<DishPairing> pairings;

  /// Dinner log; entries on or after [date] are ignored.
  final List<DinnerLogEntry> history;
  final List<PantryBatch> pantry;
  final AppSettings settings;

  /// Times "Show me another" was tapped tonight.
  final int anotherCount;
}

sealed class Suggestion {
  const new(this.reasons);

  final List<Reason> reasons;
}

final class HomeSuggestion extends Suggestion {
  const new({
    required this.main,
    required this.score,
    required List<Reason> reasons,
    this.side,
  }) : super(reasons);

  final Dish main;

  /// At most one vegetable side, on non-veg days only.
  final Dish? side;
  final double score;
}

/// "Order from outside". Suggested when no home dish is possible.
final class OutsideSuggestion extends Suggestion {
  const new({required this.restock, required List<Reason> reasons})
    : super(reasons);

  /// Proteins whose dishes are only blocked by low stock.
  final Set<ProteinType> restock;
}

final class SuggestionResult {
  const new({required this.day, required this.suggestions});

  final DayTypeResolution day;

  /// Best first, at most `SuggestionEngine.maxSuggestions`.
  final List<Suggestion> suggestions;

  DayType get dayType => day.dayType;

  bool get isOverride => day.isOverride;

  /// Ordering outside is always an option on non-veg days.
  bool get canOrderOutside => dayType == DayType.nonVegDay;
}
