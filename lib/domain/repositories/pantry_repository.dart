import 'package:aaj_kya_pakayen/domain/entities/pantry_batch.dart';
import 'package:aaj_kya_pakayen/domain/entities/pantry_movement.dart';
import 'package:aaj_kya_pakayen/domain/enums/movement_reason.dart';
import 'package:aaj_kya_pakayen/domain/enums/protein_type.dart';

abstract interface class PantryRepository {
  /// Batches with stock left, oldest first.
  Future<List<PantryBatch>> getBatches({ProteinType? proteinType});

  Stream<List<PantryBatch>> watchBatches();

  /// Records a purchase as a new batch plus a `purchase` movement.
  Future<PantryBatch> addPurchase({
    required ProteinType proteinType,
    required int grams,
    DateTime? addedOn,
  });

  /// Changes one batch by [deltaGrams] and records the movement, atomically.
  Future<PantryMovement> applyMovement({
    required int pantryItemId,
    required int deltaGrams,
    required MovementReason reason,
    int? dinnerLogId,
  });

  /// Takes [grams] of [proteinType] from the oldest batches first, one
  /// movement per batch. Throws [StateError] if there is not enough stock.
  Future<List<PantryMovement>> deductFifo({
    required ProteinType proteinType,
    required int grams,
    required MovementReason reason,
    int? dinnerLogId,
  });

  /// Quick "+": adds [grams] to the newest batch, or starts one.
  Future<PantryMovement> addToNewest({
    required ProteinType proteinType,
    required int grams,
  });

  /// Undo: reverses the movements' effect on their batches and deletes them.
  /// A batch left with no movements (an undone purchase) is deleted too.
  Future<void> revertMovements(Iterable<int> movementIds);

  Future<List<PantryMovement>> getMovements({
    int? dinnerLogId,
    int? pantryItemId,
  });
}
