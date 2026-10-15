import 'package:aaj_kya_pakayen/data/db/app_database.dart';
import 'package:aaj_kya_pakayen/data/db/tables.dart';
import 'package:drift/drift.dart';

part 'dishes_dao.g.dart';

@DriftAccessor(tables: [Dishes, DishPairings])
class DishesDao extends DatabaseAccessor<AppDatabase> with _$DishesDaoMixin {
  new(super.attachedDatabase);

  SimpleSelectStatement<$DishesTable, DishRow> _all({
    required bool includeInactive,
  }) {
    final query = select(dishes)
      ..orderBy([(d) => OrderingTerm(expression: d.nameEn)]);
    if (!includeInactive) query.where((d) => d.isActive);
    return query;
  }

  Future<List<DishRow>> all({required bool includeInactive}) =>
      _all(includeInactive: includeInactive).get();

  Stream<List<DishRow>> watchAll({required bool includeInactive}) =>
      _all(includeInactive: includeInactive).watch();

  Future<DishRow?> byId(int id) =>
      (select(dishes)..where((d) => d.id.equals(id))).getSingleOrNull();

  Future<List<DishPairingRow>> allPairings() => select(dishPairings).get();

  Future<void> upsert(
    List<DishesCompanion> dishRows,
    List<DishPairingsCompanion> pairingRows,
  ) => transaction(() async {
    await batch((b) {
      b
        ..insertAllOnConflictUpdate(dishes, dishRows)
        ..insertAllOnConflictUpdate(dishPairings, pairingRows);
    });
  });

  Future<void> setActive(int id, {required bool active}) =>
      (update(dishes)..where((d) => d.id.equals(id))).write(
        DishesCompanion(isActive: Value(active)),
      );
}
