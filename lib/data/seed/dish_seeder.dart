import 'package:aaj_kya_pakayen/data/db/app_database.dart';
import 'package:aaj_kya_pakayen/data/repositories_impl/drift_dish_repository.dart';
import 'package:aaj_kya_pakayen/data/seed/pakistani_dishes.dart';
import 'package:aaj_kya_pakayen/domain/entities/dish.dart';
import 'package:aaj_kya_pakayen/domain/entities/dish_pairing.dart';

/// Loads the built-in dishes once per [seedVersion].
///
/// Re-seeding (after a version bump) refreshes built-in dishes but keeps
/// the family's choices: deactivated dishes stay deactivated and custom
/// dishes are never touched.
class DishSeeder {
  new(this._db) : _dishes = DriftDishRepository(_db);

  static const versionKey = 'seed_version';

  final AppDatabase _db;
  final DriftDishRepository _dishes;

  Future<int> installedVersion() async =>
      int.tryParse(await _db.settingsDao.value(versionKey) ?? '') ?? 0;

  /// Returns whether anything was written.
  Future<bool> seedIfNeeded({
    int version = seedVersion,
    List<Dish>? dishes,
    List<DishPairing> pairings = pakistaniPairings,
  }) => _db.transaction(() async {
    if (await installedVersion() >= version) return false;

    final existing = {
      for (final d in await _dishes.getAll(includeInactive: true)) d.id: d,
    };
    await _dishes.upsertAll([
      for (final d in dishes ?? pakistaniDishes)
        d.copyWith(isActive: existing[d.id]?.isActive ?? d.isActive),
    ], pairings: pairings);
    await _db.settingsDao.setValue(versionKey, '$version');
    return true;
  });
}
