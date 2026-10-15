import 'package:aaj_kya_pakayen/data/db/app_database.dart';
import 'package:aaj_kya_pakayen/data/db/daos/dinner_log_dao.dart';
import 'package:aaj_kya_pakayen/domain/entities/calendar_date.dart';
import 'package:aaj_kya_pakayen/domain/entities/dinner_log_entry.dart';
import 'package:aaj_kya_pakayen/domain/repositories/dinner_log_repository.dart';
import 'package:drift/drift.dart';

class DriftDinnerLogRepository implements DinnerLogRepository {
  new(AppDatabase db, {this.clock = DateTime.now}) : _dao = db.dinnerLogDao;

  final DinnerLogDao _dao;
  final DateTime Function() clock;

  @override
  Future<List<DinnerLogEntry>> getSince(DateTime date) async =>
      (await _dao.since(date)).map(_toEntry).toList();

  @override
  Stream<List<DinnerLogEntry>> watchRecent({int limit = 30}) =>
      _dao.watchRecent(limit).map((rows) => rows.map(_toEntry).toList());

  @override
  Future<DinnerLogEntry?> getLatest() async =>
      _toEntryOrNull(await _dao.latest());

  @override
  Future<DinnerLogEntry?> getForDate(DateTime date) async =>
      _toEntryOrNull(await _dao.forDate(date));

  @override
  Future<DinnerLogEntry> save(DinnerLogEntry entry) async {
    final row = await _dao.upsertByDate(
      DinnerLogCompanion.insert(
        date: entry.date.dateOnly,
        dayType: entry.dayType,
        source: entry.source,
        mainDishId: Value(entry.mainDishId),
        sideDishId: Value(entry.sideDishId),
        outsideNote: Value(entry.outsideNote),
        wasSuggested: Value(entry.wasSuggested),
        createdAt: entry.createdAt ?? clock(),
      ),
    );
    return _toEntry(row);
  }

  @override
  Future<void> delete(int id) => _dao.deleteById(id);

  static DinnerLogEntry? _toEntryOrNull(DinnerLogRow? row) =>
      row == null ? null : _toEntry(row);

  static DinnerLogEntry _toEntry(DinnerLogRow r) => DinnerLogEntry(
    id: r.id,
    date: r.date,
    dayType: r.dayType,
    source: r.source,
    mainDishId: r.mainDishId,
    sideDishId: r.sideDishId,
    outsideNote: r.outsideNote,
    wasSuggested: r.wasSuggested,
    createdAt: r.createdAt,
  );
}
