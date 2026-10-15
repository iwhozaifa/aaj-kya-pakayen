import 'package:aaj_kya_pakayen/data/db/app_database.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/test_database.dart';

void main() {
  late AppDatabase db;

  setUp(() => db = newTestDatabase());
  tearDown(() => db.close());

  Future<List<String>> names(String sql) async =>
      (await db.customSelect(sql).get())
          .map((r) => r.read<String>('name'))
          .toList();

  Future<void> insertDish(int id) => db.customStatement(
    'INSERT INTO dishes (id, name_en, name_ur, dish_type, is_veg, '
    'staple_pairing, cooking_style, prep_minutes) '
    "VALUES ($id, 'd$id', 'd$id', 'vegetable', 1, 'roti', 'curry', 30)",
  );

  test('schema version is 1', () {
    expect(db.schemaVersion, 1);
  });

  test('creates the six tables from the brief', () async {
    expect(
      await names(
        "SELECT name FROM sqlite_master WHERE type = 'table' "
        "AND name NOT LIKE 'sqlite_%' ORDER BY name",
      ),
      [
        'app_settings',
        'dinner_log',
        'dish_pairings',
        'dishes',
        'pantry_items',
        'pantry_movements',
      ],
    );
  });

  test('indexes dishes.dish_type and pantry_items.protein_type', () async {
    final indexes = await names(
      "SELECT name FROM sqlite_master WHERE type = 'index'",
    );
    expect(
      indexes,
      containsAll(['idx_dishes_dish_type', 'idx_pantry_items_protein_type']),
    );
  });

  test('dinner_log.date is unique (and therefore indexed)', () async {
    final rows = await db.customSelect("PRAGMA index_list('dinner_log')").get();
    final unique = rows.where((r) => r.read<int>('unique') == 1);
    expect(unique, isNotEmpty);
    final columns = await db
        .customSelect(
          "PRAGMA index_info('${unique.first.read<String>('name')}')",
        )
        .get();
    expect(columns.single.read<String>('name'), 'date');

    const insert =
        'INSERT INTO dinner_log (date, day_type, source, created_at) '
        "VALUES ('2026-10-15', 'vegDay', 'home', 0)";
    await db.customStatement(insert);
    await expectLater(db.customStatement(insert), throwsA(isA<Exception>()));
  });

  test('enforces foreign keys', () async {
    await expectLater(
      db.customStatement(
        'INSERT INTO pantry_movements '
        '(pantry_item_id, delta_grams, reason, created_at) '
        "VALUES (999, 100, 'purchase', 0)",
      ),
      throwsA(isA<Exception>()),
    );
  });

  test('deleting a dish removes its pairings', () async {
    await insertDish(1);
    await insertDish(2);
    await db.customStatement(
      'INSERT INTO dish_pairings (main_dish_id, side_dish_id, priority) '
      'VALUES (1, 2, 0)',
    );
    await db.customStatement('DELETE FROM dishes WHERE id = 2');

    final left = await db.customSelect('SELECT * FROM dish_pairings').get();
    expect(left, isEmpty);
  });

  test('stores dinner dates as yyyy-MM-dd text', () async {
    await db
        .into(db.dinnerLog)
        .insert(
          DinnerLogCompanion.insert(
            date: DateTime(2026, 3, 5, 22, 10),
            dayType: .vegDay,
            source: .home,
            createdAt: DateTime(2026, 3, 5),
          ),
        );
    final row = await db
        .customSelect('SELECT date FROM dinner_log')
        .getSingle();
    expect(row.read<String>('date'), '2026-03-05');
  });

  test('new dishes default to Pakistani, active and not custom', () async {
    await insertDish(1);
    final dish = await db.select(db.dishes).getSingle();
    expect(dish.cuisine, 'pakistani');
    expect(dish.isActive, isTrue);
    expect(dish.isCustom, isFalse);
    expect(dish.canBeSide, isFalse);
  });
}
