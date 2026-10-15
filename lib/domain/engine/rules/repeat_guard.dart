import 'package:aaj_kya_pakayen/domain/entities/calendar_date.dart';
import 'package:aaj_kya_pakayen/domain/entities/dinner_log_entry.dart';
import 'package:aaj_kya_pakayen/domain/entities/dish.dart';

/// Hard rule 1: no dish, or dish in the same variant group, within
/// `windowDays` of when it was last cooked as a main or a side.
final class RepeatGuard {
  new _(this._lastCooked, this._windowDays);

  /// Only entries before [date] count.
  factory fromHistory({
    required DateTime date,
    required Iterable<DinnerLogEntry> history,
    required Map<int, Dish> dishesById,
    required int windowDays,
  }) {
    final lastCooked = <String, int>{};
    for (final entry in history) {
      final days = date.daysSince(entry.date);
      if (days <= 0) continue;
      for (final id in entry.dishIds) {
        final key = dishesById[id]?.variantKey ?? 'dish:$id';
        final previous = lastCooked[key];
        if (previous == null || days < previous) lastCooked[key] = days;
      }
    }
    return RepeatGuard._(lastCooked, windowDays);
  }

  /// Days ago each variant key was last cooked.
  final Map<String, int> _lastCooked;
  final int _windowDays;

  int? daysSinceCooked(Dish dish) => _lastCooked[dish.variantKey];

  bool allows(Dish dish) {
    final days = daysSinceCooked(dish);
    return days == null || days >= _windowDays;
  }
}
