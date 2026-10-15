import 'package:aaj_kya_pakayen/data/db/app_database.dart';
import 'package:aaj_kya_pakayen/data/db/daos/dishes_dao.dart';
import 'package:aaj_kya_pakayen/domain/entities/dish.dart';
import 'package:aaj_kya_pakayen/domain/entities/dish_pairing.dart';
import 'package:aaj_kya_pakayen/domain/repositories/dish_repository.dart';
import 'package:drift/drift.dart';

class DriftDishRepository implements DishRepository {
  new(AppDatabase db) : _dao = db.dishesDao;

  final DishesDao _dao;

  @override
  Future<List<Dish>> getAll({bool includeInactive = false}) async =>
      (await _dao.all(includeInactive: includeInactive)).map(_toDish).toList();

  @override
  Stream<List<Dish>> watchAll({bool includeInactive = false}) => _dao
      .watchAll(includeInactive: includeInactive)
      .map((rows) => rows.map(_toDish).toList());

  @override
  Future<Dish?> getById(int id) async {
    final row = await _dao.byId(id);
    return row == null ? null : _toDish(row);
  }

  @override
  Future<List<DishPairing>> getPairings() async => [
    for (final row in await _dao.allPairings())
      DishPairing(
        mainDishId: row.mainDishId,
        sideDishId: row.sideDishId,
        priority: row.priority,
      ),
  ];

  @override
  Future<void> upsertAll(
    List<Dish> dishes, {
    List<DishPairing> pairings = const [],
  }) => _dao.upsert(dishes.map(_toCompanion).toList(), [
    for (final p in pairings)
      DishPairingsCompanion.insert(
        mainDishId: p.mainDishId,
        sideDishId: p.sideDishId,
        priority: Value(p.priority),
      ),
  ]);

  @override
  Future<void> setActive(int dishId, {required bool active}) =>
      _dao.setActive(dishId, active: active);

  static Dish _toDish(DishRow r) => Dish(
    id: r.id,
    nameEn: r.nameEn,
    nameUr: r.nameUr,
    cuisine: r.cuisine,
    dishType: r.dishType,
    proteinGramsPerPerson: r.proteinGramsPerPerson,
    staplePairing: r.staplePairing,
    cookingStyle: r.cookingStyle,
    prepMinutes: r.prepMinutes,
    canBeSide: r.canBeSide,
    isCustom: r.isCustom,
    isActive: r.isActive,
    variantGroup: r.variantGroup,
    notes: r.notes,
  );

  static DishesCompanion _toCompanion(Dish d) => DishesCompanion.insert(
    id: Value(d.id),
    nameEn: d.nameEn,
    nameUr: d.nameUr,
    cuisine: Value(d.cuisine),
    dishType: d.dishType,
    isVeg: d.isVeg,
    proteinType: Value(d.proteinType),
    proteinGramsPerPerson: Value(d.proteinGramsPerPerson),
    staplePairing: d.staplePairing,
    cookingStyle: d.cookingStyle,
    prepMinutes: d.prepMinutes,
    canBeSide: Value(d.canBeSide),
    isCustom: Value(d.isCustom),
    isActive: Value(d.isActive),
    variantGroup: Value(d.variantGroup),
    notes: Value(d.notes),
  );
}
