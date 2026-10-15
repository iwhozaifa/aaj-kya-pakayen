import 'package:aaj_kya_pakayen/core/utils/clock.dart';
import 'package:aaj_kya_pakayen/data/providers.dart';
import 'package:aaj_kya_pakayen/domain/entities/calendar_date.dart';
import 'package:aaj_kya_pakayen/domain/entities/dinner_log_entry.dart';
import 'package:aaj_kya_pakayen/domain/entities/dish.dart';
import 'package:aaj_kya_pakayen/domain/enums/day_type.dart';
import 'package:aaj_kya_pakayen/domain/repositories/settings_repository.dart';
import 'package:aaj_kya_pakayen/domain/usecases/log_dinner.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'history_controller.g.dart';

/// A logged dinner with its dishes resolved.
final class HistoryEntry {
  const new({required this.entry, this.main, this.side});

  final DinnerLogEntry entry;
  final Dish? main;
  final Dish? side;
}

final class HistoryDay {
  const new({required this.date, this.entry});

  final DateTime date;
  final HistoryEntry? entry;
}

final class HistoryState {
  const new({required this.week, required this.entries});

  /// The last 7 days, oldest first, ending today.
  final List<HistoryDay> week;

  /// Every recent entry, newest first.
  final List<HistoryEntry> entries;
}

/// How far back the history list goes.
const historyDays = 60;

@riverpod
Future<HistoryState> historyState(Ref ref) async {
  // Change feeds only trigger a refresh; data is read fresh below.
  ref
    ..watch(recentDinnersProvider)
    ..watch(activeDishesProvider);
  final today = ref.watch(clockProvider)().dateOnly;
  final recent = await ref
      .watch(dinnerLogRepositoryProvider)
      .getSince(DateTime(today.year, today.month, today.day - historyDays));
  final dishes = {
    for (final d
        in await ref
            .watch(dishRepositoryProvider)
            .getAll(includeInactive: true))
      d.id: d,
  };

  final entries = [
    for (final e in recent)
      HistoryEntry(
        entry: e,
        main: dishes[e.mainDishId],
        side: dishes[e.sideDishId],
      ),
  ];
  return HistoryState(
    week: [
      for (var back = 6; back >= 0; back--)
        () {
          final date = DateTime(today.year, today.month, today.day - back);
          return HistoryDay(
            date: date,
            entry: entries
                .where((e) => e.entry.date.isSameDay(date))
                .firstOrNull,
          );
        }(),
    ],
    entries: entries,
  );
}

/// Add, edit and delete past dinners. The engine recalculates by itself
/// because suggestions watch the dinner log.
class HistoryActions {
  new({
    required this._logDinner,
    required this._settings,
    required this._refresh,
  });

  final LogDinner _logDinner;
  final SettingsRepository _settings;
  final void Function() _refresh;

  /// Logs (or replaces) a home dinner on [date]. Returns the entry id.
  Future<int> saveHome(
    DateTime date, {
    required Dish main,
    Dish? side,
    DayType? dayType,
    bool wasSuggested = false,
  }) async {
    final settings = await _settings.load();
    final entry = await _logDinner.cookAtHome(
      date: date,
      dayType: dayType ?? (main.isVeg ? DayType.vegDay : DayType.nonVegDay),
      main: main,
      side: side,
      householdSize: settings.householdSize,
      wasSuggested: wasSuggested,
    );
    _refresh();
    return entry.id!;
  }

  Future<int> saveOutside(
    DateTime date, {
    String? note,
    bool wasSuggested = false,
  }) async {
    final entry = await _logDinner.orderOutside(
      date: date,
      note: note,
      wasSuggested: wasSuggested,
    );
    _refresh();
    return entry.id!;
  }

  Future<void> delete(HistoryEntry entry) => removeById(entry.entry.id!);

  Future<void> removeById(int id) async {
    await _logDinner.undo(id);
    _refresh();
  }

  /// Undo for an edit or delete: puts [previous] back as it was.
  Future<void> restore(HistoryEntry previous) async {
    final e = previous.entry;
    final main = previous.main;
    if (e.isOutside || main == null) {
      await saveOutside(
        e.date,
        note: e.outsideNote,
        wasSuggested: e.wasSuggested,
      );
    } else {
      await saveHome(
        e.date,
        main: main,
        side: previous.side,
        dayType: e.dayType,
        wasSuggested: e.wasSuggested,
      );
    }
  }
}

@Riverpod(keepAlive: true)
HistoryActions historyActions(Ref ref) => HistoryActions(
  logDinner: LogDinner(
    log: ref.watch(dinnerLogRepositoryProvider),
    pantry: ref.watch(pantryRepositoryProvider),
  ),
  settings: ref.watch(settingsRepositoryProvider),
  refresh: () => ref.invalidate(historyStateProvider),
);
