import 'package:aaj_kya_pakayen/data/providers.dart';
import 'package:aaj_kya_pakayen/domain/entities/dish.dart';
import 'package:aaj_kya_pakayen/domain/repositories/dish_repository.dart';
import 'package:aaj_kya_pakayen/domain/usecases/dish_catalog.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'dishes_controller.g.dart';

/// Every dish, hidden ones too, sorted by English name.
@riverpod
Stream<List<Dish>> allDishes(Ref ref) =>
    ref.watch(dishRepositoryProvider).watchAll(includeInactive: true);

/// Adding, hiding and showing dishes. Suggestions follow automatically
/// because they watch the active dish list.
class DishesActions {
  new(this._repo) : _addCustomDish = AddCustomDish(_repo);

  final DishRepository _repo;
  final AddCustomDish _addCustomDish;

  /// Throws [DuplicateDishException] when the name is already taken.
  Future<Dish> addCustom(CustomDishDraft draft) => _addCustomDish(draft);

  Future<void> undoAdd(Dish dish) => _repo.deleteCustom(dish.id);

  Future<void> setActive(Dish dish, {required bool active}) =>
      _repo.setActive(dish.id, active: active);
}

@Riverpod(keepAlive: true)
DishesActions dishesActions(Ref ref) =>
    DishesActions(ref.watch(dishRepositoryProvider));
