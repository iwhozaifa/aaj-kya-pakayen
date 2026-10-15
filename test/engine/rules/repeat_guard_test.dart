import 'package:aaj_kya_pakayen/domain/engine/rules/repeat_guard.dart';
import 'package:aaj_kya_pakayen/domain/enums/day_type.dart';
import 'package:aaj_kya_pakayen/domain/enums/dish_type.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fixtures.dart';

void main() {
  final karahi = dish(1, type: DishType.chicken, group: 'chicken_karahi');
  final whiteKarahi = dish(2, type: DishType.chicken, group: 'chicken_karahi');
  final bhindi = dish(3, side: true);
  final daal = dish(4, type: DishType.pulse);
  final dishes = {
    for (final d in [karahi, whiteKarahi, bhindi, daal]) d.id: d,
  };

  RepeatGuard guard(List<Object> history, {int window = 7}) =>
      RepeatGuard.fromHistory(
        date: today,
        history: history.cast(),
        dishesById: dishes,
        windowDays: window,
      );

  test('blocks a dish cooked within the window', () {
    final g = guard([cooked(6, DayType.nonVegDay, main: 1)]);
    expect(g.allows(karahi), isFalse);
    expect(g.allows(daal), isTrue);
  });

  test('allows it again once the full window has passed', () {
    expect(
      guard([cooked(7, DayType.nonVegDay, main: 1)]).allows(karahi),
      isTrue,
    );
  });

  test('blocks other dishes in the same variant group', () {
    expect(
      guard([cooked(2, DayType.nonVegDay, main: 1)]).allows(whiteKarahi),
      isFalse,
    );
  });

  test('a dish served as a side is blocked too', () {
    expect(
      guard([cooked(2, DayType.nonVegDay, main: 1, side: 3)]).allows(bhindi),
      isFalse,
    );
  });

  test('the window is configurable', () {
    final history = [cooked(3, DayType.vegDay, main: 4)];
    expect(guard(history).allows(daal), isFalse);
    expect(guard(history, window: 3).allows(daal), isTrue);
  });

  test("ignores tonight's own entry and outside dinners", () {
    final g = guard([cooked(0, DayType.vegDay, main: 4), orderedOutside(1)]);
    expect(g.allows(daal), isTrue);
  });

  test('history pointing at an unknown dish blocks only that id', () {
    final g = guard([cooked(1, DayType.vegDay, main: 99)]);
    expect(g.allows(daal), isTrue);
    expect(g.allows(dish(99)), isFalse);
  });

  test('reports days since the dish or its group was last cooked', () {
    final g = guard([
      cooked(20, DayType.nonVegDay, main: 2),
      cooked(30, DayType.nonVegDay, main: 1),
    ]);
    expect(g.daysSinceCooked(karahi), 20);
    expect(g.daysSinceCooked(daal), isNull);
  });
}
