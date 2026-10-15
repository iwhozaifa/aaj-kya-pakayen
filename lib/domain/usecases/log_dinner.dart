import 'dart:math';

import 'package:aaj_kya_pakayen/domain/entities/calendar_date.dart';
import 'package:aaj_kya_pakayen/domain/entities/dinner_log_entry.dart';
import 'package:aaj_kya_pakayen/domain/entities/dish.dart';
import 'package:aaj_kya_pakayen/domain/enums/day_type.dart';
import 'package:aaj_kya_pakayen/domain/enums/dinner_source.dart';
import 'package:aaj_kya_pakayen/domain/enums/movement_reason.dart';
import 'package:aaj_kya_pakayen/domain/repositories/dinner_log_repository.dart';
import 'package:aaj_kya_pakayen/domain/repositories/pantry_repository.dart';

/// Writes tonight's dinner and keeps the pantry in step with it.
///
/// One entry per date: logging a date again first gives back the stock the
/// earlier entry used. Every log can be undone by its entry id.
final class LogDinner {
  const new({required this._log, required this._pantry});

  final DinnerLogRepository _log;
  final PantryRepository _pantry;

  /// Saves a home-cooked dinner and deducts the main's protein for the
  /// whole household, oldest batches first. If stock fell short since the
  /// suggestion, only what is left is deducted.
  Future<DinnerLogEntry> cookAtHome({
    required DateTime date,
    required DayType dayType,
    required Dish main,
    required int householdSize,
    Dish? side,
    bool wasSuggested = true,
  }) async {
    final entry = await _replace(
      DinnerLogEntry(
        date: date.dateOnly,
        dayType: dayType,
        source: DinnerSource.home,
        mainDishId: main.id,
        sideDishId: side?.id,
        wasSuggested: wasSuggested,
      ),
    );
    final protein = main.proteinType;
    if (protein != null) {
      final available = (await _pantry.getBatches(proteinType: protein))
          .fold<int>(0, (sum, b) => sum + b.quantityGrams);
      final grams = min(
        main.proteinGramsFor(householdSize: householdSize),
        available,
      );
      if (grams > 0) {
        await _pantry.deductFifo(
          proteinType: protein,
          grams: grams,
          reason: MovementReason.cooked,
          dinnerLogId: entry.id,
        );
      }
    }
    return entry;
  }

  /// Saves an "ordered from outside" dinner (always a non-veg day).
  Future<DinnerLogEntry> orderOutside({
    required DateTime date,
    String? note,
    bool wasSuggested = true,
  }) {
    final trimmed = note?.trim();
    return _replace(
      DinnerLogEntry(
        date: date.dateOnly,
        dayType: DayType.nonVegDay,
        source: DinnerSource.outside,
        outsideNote: trimmed == null || trimmed.isEmpty ? null : trimmed,
        wasSuggested: wasSuggested,
      ),
    );
  }

  /// Removes the entry and gives back any stock it used.
  Future<void> undo(int entryId) async {
    await _giveBackStock(entryId);
    await _log.delete(entryId);
  }

  Future<DinnerLogEntry> _replace(DinnerLogEntry entry) async {
    final existing = await _log.getForDate(entry.date);
    if (existing?.id case final id?) await _giveBackStock(id);
    return await _log.save(entry);
  }

  Future<void> _giveBackStock(int entryId) async {
    final movements = await _pantry.getMovements(dinnerLogId: entryId);
    if (movements.isNotEmpty) {
      await _pantry.revertMovements([for (final m in movements) m.id]);
    }
  }
}
