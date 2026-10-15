import 'package:drift/drift.dart';

/// Stores a calendar date as `yyyy-MM-dd` text so `dinner_log.date` can be
/// unique per day and sorts correctly.
class DateOnlyConverter extends TypeConverter<DateTime, String> {
  const new();

  @override
  DateTime fromSql(String fromDb) => DateTime.parse(fromDb);

  @override
  String toSql(DateTime value) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${value.year.toString().padLeft(4, '0')}-'
        '${two(value.month)}-${two(value.day)}';
  }
}
