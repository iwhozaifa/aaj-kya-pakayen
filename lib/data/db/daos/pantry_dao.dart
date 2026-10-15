import 'package:aaj_kya_pakayen/data/db/app_database.dart';
import 'package:aaj_kya_pakayen/data/db/tables.dart';
import 'package:aaj_kya_pakayen/domain/enums/protein_type.dart';
import 'package:drift/drift.dart';

part 'pantry_dao.g.dart';

@DriftAccessor(tables: [PantryItems, PantryMovements])
class PantryDao extends DatabaseAccessor<AppDatabase> with _$PantryDaoMixin {
  new(super.attachedDatabase);

  /// Batches with stock left, oldest first (ties broken by id).
  SimpleSelectStatement<$PantryItemsTable, PantryItemRow> _inStock(
    ProteinType? proteinType,
  ) {
    final query = select(pantryItems)
      ..where((p) => p.quantityGrams.isBiggerThanValue(0))
      ..orderBy([
        (p) => OrderingTerm(expression: p.addedOn),
        (p) => OrderingTerm(expression: p.id),
      ]);
    if (proteinType != null) {
      query.where((p) => p.proteinType.equalsValue(proteinType));
    }
    return query;
  }

  Future<List<PantryItemRow>> inStock(ProteinType? proteinType) =>
      _inStock(proteinType).get();

  Stream<List<PantryItemRow>> watchInStock() => _inStock(null).watch();

  Future<PantryItemRow> batchById(int id) =>
      (select(pantryItems)..where((p) => p.id.equals(id))).getSingle();

  Future<int> insertBatch(PantryItemsCompanion row) =>
      into(pantryItems).insert(row);

  Future<void> setQuantity(int id, int grams, DateTime updatedAt) =>
      (update(pantryItems)..where((p) => p.id.equals(id))).write(
        PantryItemsCompanion(
          quantityGrams: Value(grams),
          updatedAt: Value(updatedAt),
        ),
      );

  Future<PantryMovementRow> insertMovement(PantryMovementsCompanion row) =>
      into(pantryMovements).insertReturning(row);

  Future<List<PantryMovementRow>> movements({int? dinnerLogId}) {
    final query = select(pantryMovements)
      ..orderBy([(m) => OrderingTerm(expression: m.id)]);
    if (dinnerLogId != null) {
      query.where((m) => m.dinnerLogId.equals(dinnerLogId));
    }
    return query.get();
  }
}
