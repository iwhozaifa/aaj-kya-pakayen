import 'dart:math';

import 'package:aaj_kya_pakayen/core/utils/clock.dart';
import 'package:aaj_kya_pakayen/data/providers.dart';
import 'package:aaj_kya_pakayen/domain/entities/calendar_date.dart';
import 'package:aaj_kya_pakayen/domain/enums/movement_reason.dart';
import 'package:aaj_kya_pakayen/domain/enums/protein_type.dart';
import 'package:aaj_kya_pakayen/domain/repositories/pantry_repository.dart';
import 'package:aaj_kya_pakayen/domain/usecases/summarize_pantry.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'pantry_controller.g.dart';

/// What to revert when the cook taps "Undo".
final class PantryUndo {
  const new(this.movementIds);

  final List<int> movementIds;
}

/// Pantry changes made from the UI. Each returns a [PantryUndo].
class PantryActions {
  new(this._repo);

  /// Grams added or removed by one tap of + or −.
  static const quickStepGrams = 250;

  final PantryRepository _repo;

  Future<PantryUndo> addPurchase(
    ProteinType protein,
    int grams, {
    required DateTime boughtOn,
  }) async {
    final batch = await _repo.addPurchase(
      proteinType: protein,
      grams: grams,
      addedOn: boughtOn.dateOnly,
    );
    final movements = await _repo.getMovements(pantryItemId: batch.id);
    return PantryUndo([for (final m in movements) m.id]);
  }

  Future<PantryUndo> increase(ProteinType protein) async {
    final movement = await _repo.addToNewest(
      proteinType: protein,
      grams: quickStepGrams,
    );
    return PantryUndo([movement.id]);
  }

  /// Returns null when there is nothing left to remove.
  Future<PantryUndo?> decrease(ProteinType protein) async {
    final available = (await _repo.getBatches(proteinType: protein))
        .fold<int>(0, (sum, b) => sum + b.quantityGrams);
    if (available == 0) return null;
    final movements = await _repo.deductFifo(
      proteinType: protein,
      grams: min(quickStepGrams, available),
      reason: MovementReason.adjust,
    );
    return PantryUndo([for (final m in movements) m.id]);
  }

  Future<void> undo(PantryUndo undo) => _repo.revertMovements(undo.movementIds);
}

@riverpod
PantryActions pantryActions(Ref ref) =>
    PantryActions(ref.watch(pantryRepositoryProvider));

/// One entry per protein (the four tiles), refreshed on every change.
@riverpod
Stream<List<ProteinStock>> pantrySummary(Ref ref) async* {
  final settings = await ref.watch(appSettingsProvider.future);
  final clock = ref.watch(clockProvider);
  yield* ref
      .watch(pantryRepositoryProvider)
      .watchBatches()
      .map(
        (batches) => summarizePantry(
          batches: batches,
          date: clock(),
          householdSize: settings.householdSize,
        ),
      );
}
