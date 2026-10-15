import 'package:aaj_kya_pakayen/core/utils/clock.dart';
import 'package:aaj_kya_pakayen/data/providers.dart';
import 'package:aaj_kya_pakayen/domain/engine/suggestion_engine.dart';
import 'package:aaj_kya_pakayen/domain/entities/app_settings.dart';
import 'package:aaj_kya_pakayen/domain/entities/calendar_date.dart';
import 'package:aaj_kya_pakayen/domain/entities/dinner_log_entry.dart';
import 'package:aaj_kya_pakayen/domain/entities/dish.dart';
import 'package:aaj_kya_pakayen/domain/enums/day_type.dart';
import 'package:aaj_kya_pakayen/domain/repositories/settings_repository.dart';
import 'package:aaj_kya_pakayen/domain/usecases/get_tonight_suggestions.dart';
import 'package:aaj_kya_pakayen/domain/usecases/log_dinner.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'today_controller.g.dart';

final class TodayState {
  const new({
    required this.result,
    this.tonight,
    this.tonightMain,
    this.tonightSide,
  });

  final SuggestionResult result;

  /// Tonight's dinner once it is logged.
  final DinnerLogEntry? tonight;
  final Dish? tonightMain;
  final Dish? tonightSide;
}

/// Taps of "Show me another" tonight.
@Riverpod(keepAlive: true)
class AnotherCount extends _$AnotherCount {
  @override
  int build() => 0;

  void next() => state++;

  void reset() => state = 0;
}

@riverpod
Future<TodayState> todayState(Ref ref) async {
  // Refresh whenever data changes, here or on another tab.
  ref
    ..watch(appSettingsProvider)
    ..watch(recentDinnersProvider)
    ..watch(pantryBatchesProvider)
    ..watch(activeDishesProvider);
  final anotherCount = ref.watch(anotherCountProvider);
  final date = ref.watch(clockProvider)().dateOnly;

  final dishes = ref.watch(dishRepositoryProvider);
  final log = ref.watch(dinnerLogRepositoryProvider);
  final result = await GetTonightSuggestions(
    dishes: dishes,
    log: log,
    pantry: ref.watch(pantryRepositoryProvider),
    settings: ref.watch(settingsRepositoryProvider),
  )(date: date, anotherCount: anotherCount);

  final tonight = await log.getForDate(date);
  return TodayState(
    result: result,
    tonight: tonight,
    tonightMain: switch (tonight?.mainDishId) {
      final id? => await dishes.getById(id),
      null => null,
    },
    tonightSide: switch (tonight?.sideDishId) {
      final id? => await dishes.getById(id),
      null => null,
    },
  );
}

/// What the Today screen's buttons do. Logging returns the entry id, which
/// is all "Undo" needs.
class TodayActions {
  new({
    required this._logDinner,
    required this._settings,
    required this._clock,
    required this._another,
    required this._refresh,
  });

  final LogDinner _logDinner;
  final SettingsRepository _settings;
  final DateTime Function() _clock;
  final AnotherCount _another;
  final void Function() _refresh;

  Future<int> cook(HomeSuggestion suggestion, DayType dayType) async {
    final settings = await _settings.load();
    final entry = await _logDinner.cookAtHome(
      date: _clock(),
      dayType: dayType,
      main: suggestion.main,
      side: suggestion.side,
      householdSize: settings.householdSize,
    );
    _done();
    return entry.id!;
  }

  Future<int> orderOutside(String? note) async {
    final entry = await _logDinner.orderOutside(date: _clock(), note: note);
    _done();
    return entry.id!;
  }

  void showAnother() => _another.next();

  /// Swaps tonight's type; swapping an override again removes it.
  Future<void> swapDayType(SuggestionResult result) async {
    final settings = await _settings.load();
    await _settings.save(
      settings.copyWith(
        dayTypeOverride: result.isOverride
            ? null
            : DayTypeOverride(
                date: _clock().dateOnly,
                dayType: result.dayType.flipped,
              ),
      ),
    );
    _done();
  }

  Future<void> undo(int entryId) async {
    await _logDinner.undo(entryId);
    _refresh();
  }

  void _done() {
    _another.reset();
    _refresh();
  }
}

@Riverpod(keepAlive: true)
TodayActions todayActions(Ref ref) => TodayActions(
  logDinner: LogDinner(
    log: ref.watch(dinnerLogRepositoryProvider),
    pantry: ref.watch(pantryRepositoryProvider),
  ),
  settings: ref.watch(settingsRepositoryProvider),
  clock: ref.watch(clockProvider),
  another: ref.watch(anotherCountProvider.notifier),
  refresh: () => ref.invalidate(todayStateProvider),
);
