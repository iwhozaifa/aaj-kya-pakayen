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

  Future<List<PantryMovement>> getMovements({int? dinnerLogId});
}
