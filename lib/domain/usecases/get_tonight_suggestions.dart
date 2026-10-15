import 'dart:math';

import 'package:aaj_kya_pakayen/domain/engine/scoring/weights.dart';
import 'package:aaj_kya_pakayen/domain/engine/suggestion_engine.dart';
import 'package:aaj_kya_pakayen/domain/entities/calendar_date.dart';
import 'package:aaj_kya_pakayen/domain/repositories/dinner_log_repository.dart';
import 'package:aaj_kya_pakayen/domain/repositories/dish_repository.dart';
import 'package:aaj_kya_pakayen/domain/repositories/pantry_repository.dart';
import 'package:aaj_kya_pakayen/domain/repositories/settings_repository.dart';

/// Loads everything the engine needs for [call]'s date and runs it.
final class GetTonightSuggestions {
  const new({
    required this._dishes,
    required this._log,
    required this._pantry,
    required this._settings,
    this._engine = const SuggestionEngine(),
  });

  final DishRepository _dishes;
  final DinnerLogRepository _log;
  final PantryRepository _pantry;
  final SettingsRepository _settings;
  final SuggestionEngine _engine;

  Future<SuggestionResult> call({
    required DateTime date,
    int anotherCount = 0,
  }) async {
    final settings = await _settings.load();
    final lookback = max(
      settings.repeatWindowDays,
      ScoreWeights.noveltyMaxDays,
    );
    final day = date.dateOnly;
    final from = DateTime(day.year, day.month, day.day - lookback);
    final (dishes, pairings, recent, latest, pantry) = await (
      _dishes.getAll(),
      _dishes.getPairings(),
      _log.getSince(from),
      _log.getLatest(),
      _pantry.getBatches(),
    ).wait;
    return _engine.suggest(
      SuggestionRequest(
        date: day,
        dishes: dishes,
        pairings: pairings,
        history: [
          ...recent,
          if (latest != null && !recent.any((e) => e.date == latest.date))
            latest,
        ],
        pantry: pantry,
        settings: settings,
        anotherCount: anotherCount,
      ),
    );
  }
}
