import 'package:aaj_kya_pakayen/domain/entities/dish.dart';
import 'package:aaj_kya_pakayen/domain/entities/dish_pairing.dart';
import 'package:aaj_kya_pakayen/domain/enums/dish_type.dart';

/// Hard rule 3: a meat main may get one vegetable side from its curated
/// pairings, best priority first, skipping sides that [allowed] rejects.
Dish? pickSide({
  required Dish main,
  required Iterable<DishPairing> pairings,
  required Map<int, Dish> dishesById,
  required bool Function(Dish side) allowed,
}) {
  if (main.isVeg) return null;
  final candidates = pairings.where((p) => p.mainDishId == main.id).toList()
    ..sort(
      (a, b) => a.priority != b.priority
          ? a.priority.compareTo(b.priority)
          : a.sideDishId.compareTo(b.sideDishId),
    );
  for (final pairing in candidates) {
    final side = dishesById[pairing.sideDishId];
    if (side != null &&
        side.dishType == DishType.vegetable &&
        side.canBeSide &&
        side.isActive &&
        allowed(side)) {
      return side;
    }
  }
  return null;
}
