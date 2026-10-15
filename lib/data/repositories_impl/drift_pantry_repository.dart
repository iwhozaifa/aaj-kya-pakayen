import 'package:aaj_kya_pakayen/data/db/app_database.dart';
import 'package:aaj_kya_pakayen/data/db/daos/pantry_dao.dart';
import 'package:aaj_kya_pakayen/domain/entities/pantry_batch.dart';
import 'package:aaj_kya_pakayen/domain/entities/pantry_movement.dart';
import 'package:aaj_kya_pakayen/domain/enums/movement_reason.dart';
import 'package:aaj_kya_pakayen/domain/enums/protein_type.dart';
import 'package:aaj_kya_pakayen/domain/repositories/pantry_repository.dart';
import 'package:drift/drift.dart';

class DriftPantryRepository implements PantryRepository {
  new(this._db, {this.clock = DateTime.now}) : _dao = _db.pantryDao;

  final AppDatabase _db;
  final PantryDao _dao;
  final DateTime Function() clock;

  @override
  Future<List<PantryBatch>> getBatches({ProteinType? proteinType}) async =>
      (await _dao.inStock(proteinType)).map(_toBatch).toList();

  @override
  Stream<List<PantryBatch>> watchBatches() =>
      _dao.watchInStock().map((rows) => rows.map(_toBatch).toList());

  @override
  Future<PantryBatch> addPurchase({
    required ProteinType proteinType,
    required int grams,
    DateTime? addedOn,
  }) {
    if (grams <= 0) throw ArgumentError.value(grams, 'grams', 'must be > 0');
    final now = clock();
    return _db.transaction(() async {
      final id = await _dao.insertBatch(
        PantryItemsCompanion.insert(
          proteinType: proteinType,
          quantityGrams: grams,
          addedOn: addedOn ?? now,
          updatedAt: now,
        ),
      );
      await _dao.insertMovement(
        PantryMovementsCompanion.insert(
          pantryItemId: id,
          deltaGrams: grams,
          reason: MovementReason.purchase,
          createdAt: now,
        ),
      );
      return _toBatch(await _dao.batchById(id));
    });
  }

  @override
  Future<PantryMovement> applyMovement({
    required int pantryItemId,
    required int deltaGrams,
    required MovementReason reason,
    int? dinnerLogId,
  }) => _db.transaction(() async {
    final batch = await _dao.batchById(pantryItemId);
    final remaining = batch.quantityGrams + deltaGrams;
    if (remaining < 0) {
      throw StateError(
        'Batch $pantryItemId has ${batch.quantityGrams} g, '
        'cannot apply $deltaGrams g',
      );
    }
    final now = clock();
    await _dao.setQuantity(pantryItemId, remaining, now);
    final row = await _dao.insertMovement(
      PantryMovementsCompanion.insert(
        pantryItemId: pantryItemId,
        deltaGrams: deltaGrams,
        reason: reason,
        dinnerLogId: Value(dinnerLogId),
        createdAt: now,
      ),
    );
    return _toMovement(row);
  });

  @override
  Future<List<PantryMovement>> getMovements({int? dinnerLogId}) async =>
      (await _dao.movements(dinnerLogId: dinnerLogId))
          .map(_toMovement)
          .toList();

  static PantryBatch _toBatch(PantryItemRow r) => PantryBatch(
    id: r.id,
    proteinType: r.proteinType,
    quantityGrams: r.quantityGrams,
    addedOn: r.addedOn,
    updatedAt: r.updatedAt,
  );

  static PantryMovement _toMovement(PantryMovementRow r) => PantryMovement(
    id: r.id,
    pantryItemId: r.pantryItemId,
    deltaGrams: r.deltaGrams,
    reason: r.reason,
    dinnerLogId: r.dinnerLogId,
    createdAt: r.createdAt,
  );
}
