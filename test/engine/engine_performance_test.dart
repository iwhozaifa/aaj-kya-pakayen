import 'package:aaj_kya_pakayen/domain/engine/suggestion_engine.dart';
import 'package:aaj_kya_pakayen/domain/entities/app_settings.dart';
import 'package:aaj_kya_pakayen/domain/entities/dish_pairing.dart';
import 'package:aaj_kya_pakayen/domain/enums/cooking_style.dart';
import 'package:aaj_kya_pakayen/domain/enums/day_type.dart';
import 'package:aaj_kya_pakayen/domain/enums/dish_type.dart';
import 'package:aaj_kya_pakayen/domain/enums/protein_type.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fixtures.dart';

/// Guards against accidental quadratic work in the engine. The real
/// catalogue is 78 dishes; this uses 1,000 and a year of history.
void main() {
  test('suggests from 1,000 dishes and a year of history quickly', () {
    final dishes = [
      for (var id = 1; id <= 1000; id++)
        dish(
          id,
          type: DishType.values[id % DishType.values.length],
          style: CookingStyle.values[id % CookingStyle.values.length],
          minutes: 20 + id % 90,
          side: id % 7 == 0,
        ),
    ];
    final pairings = [
      for (var id = 2; id <= 1000; id += 6)
        DishPairing(mainDishId: id, sideDishId: (id ~/ 7 + 1) * 7),
    ];
    final history = [
      for (var back = 1; back <= 365; back++)
        cooked(
          back,
          back.isEven ? DayType.vegDay : DayType.nonVegDay,
          main: back % 1000 + 1,
        ),
    ];
    final pantry = [
      for (final (i, p) in ProteinType.values.indexed)
        batch(i + 1, p, 5000, addedDaysAgo: i + 1),
    ];
    const engine = SuggestionEngine();
    final watch = Stopwatch()..start();
    const runs = 20;
    for (var another = 0; another < runs; another++) {
      final result = engine.suggest(
        SuggestionRequest(
          date: today,
          dishes: dishes,
          pairings: pairings,
          history: history,
          pantry: pantry,
          settings: const AppSettings(),
          anotherCount: another,
        ),
      );
      expect(result.suggestions, isNotEmpty);
    }
    watch.stop();
    final perRun = watch.elapsedMilliseconds / runs;
    // About 2.5 ms locally. A frame is 16 ms; the generous ceiling keeps
    // slow CI machines green while still catching quadratic slips.
    expect(perRun, lessThan(50), reason: '$perRun ms per suggestion');
  });
}
