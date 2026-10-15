import 'package:aaj_kya_pakayen/data/db/app_database.dart';
import 'package:aaj_kya_pakayen/data/db/converters.dart';
import 'package:aaj_kya_pakayen/data/db/tables.dart';
import 'package:drift/drift.dart';

part 'dinner_log_dao.g.dart';

@DriftAccessor(tables: [DinnerLog])
class DinnerLogDao extends DatabaseAccessor<AppDatabase>
    with _$DinnerLogDaoMixin {
  new(super.attachedDatabase);

  static const _date = DateOnlyConverter();

  OrderingTerm _newestFirst($DinnerLogTable d) =>
      OrderingTerm(expression: d.date, mode: OrderingMode.desc);

  /// Dates are `yyyy-MM-dd` text, so string comparison is date comparison.
  Future<List<DinnerLogRow>> since(DateTime date) =>
      (select(dinnerLog)
            ..where((d) => d.date.isBiggerOrEqualValue(_date.toSql(date)))
            ..orderBy([_newestFirst]))
          .get();

  Stream<List<DinnerLogRow>> watchRecent(int limit) =>
      (select(dinnerLog)
            ..orderBy([_newestFirst])
            ..limit(limit))
          .watch();

  Future<DinnerLogRow?> latest() =>
      (select(dinnerLog)
            ..orderBy([_newestFirst])
            ..limit(1))
          .getSingleOrNull();

  Future<DinnerLogRow?> forDate(DateTime date) => (select(
    dinnerLog,
  )..where((d) => d.date.equals(_date.toSql(date)))).getSingleOrNull();

  /// Inserts, or replaces the row already logged for the same date.
  Future<DinnerLogRow> upsertByDate(DinnerLogCompanion row) =>
      into(dinnerLog).insertReturning(
        row,
        onConflict: DoUpdate(
          (_) => row.copyWith(id: const Value.absent()),
          target: [dinnerLog.date],
        ),
      );

  Future<void> deleteById(int id) =>
      (delete(dinnerLog)..where((d) => d.id.equals(id))).go();
}
