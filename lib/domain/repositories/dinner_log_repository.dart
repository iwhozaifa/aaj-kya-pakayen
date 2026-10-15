import 'package:aaj_kya_pakayen/domain/entities/dinner_log_entry.dart';

abstract interface class DinnerLogRepository {
  /// Entries on or after [date], newest first.
  Future<List<DinnerLogEntry>> getSince(DateTime date);

  /// The most recent [limit] entries, newest first.
  Stream<List<DinnerLogEntry>> watchRecent({int limit = 30});

  Future<DinnerLogEntry?> getLatest();

  Future<DinnerLogEntry?> getForDate(DateTime date);

  /// Saves [entry], replacing any entry already logged for its date.
  Future<DinnerLogEntry> save(DinnerLogEntry entry);

  Future<void> delete(int id);
}
