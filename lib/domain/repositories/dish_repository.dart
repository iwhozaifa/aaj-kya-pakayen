import 'package:aaj_kya_pakayen/domain/entities/dish.dart';
import 'package:aaj_kya_pakayen/domain/entities/dish_pairing.dart';

abstract interface class DishRepository {
  /// Dishes sorted by English name; inactive ones only when asked.
  Future<List<Dish>> getAll({bool includeInactive = false});

  Stream<List<Dish>> watchAll({bool includeInactive = false});

  Future<Dish?> getById(int id);

  Future<List<DishPairing>> getPairings();

  /// Inserts or replaces dishes and pairings in one transaction.
  Future<void> upsertAll(
    List<Dish> dishes, {
    List<DishPairing> pairings = const [],
  });

  Future<void> setActive(int dishId, {required bool active});
}
