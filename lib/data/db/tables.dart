import 'package:aaj_kya_pakayen/data/db/converters.dart';
import 'package:aaj_kya_pakayen/domain/enums/cooking_style.dart';
import 'package:aaj_kya_pakayen/domain/enums/day_type.dart';
import 'package:aaj_kya_pakayen/domain/enums/dinner_source.dart';
import 'package:aaj_kya_pakayen/domain/enums/dish_type.dart';
import 'package:aaj_kya_pakayen/domain/enums/movement_reason.dart';
import 'package:aaj_kya_pakayen/domain/enums/protein_type.dart';
import 'package:aaj_kya_pakayen/domain/enums/staple_pairing.dart';
import 'package:drift/drift.dart';

// Row classes are suffixed with `Row` to keep them apart from domain
// entities. Enums are stored by name (see docs/DATABASE.md).

@DataClassName('DishRow')
@TableIndex(name: 'idx_dishes_dish_type', columns: {#dishType})
class Dishes extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get nameEn => text()();
  TextColumn get nameUr => text()();
  TextColumn get cuisine => text().withDefault(const Constant('pakistani'))();
  TextColumn get dishType => textEnum<DishType>()();
  BoolColumn get isVeg => boolean()();
  TextColumn get proteinType => textEnum<ProteinType>().nullable()();
  IntColumn get proteinGramsPerPerson => integer().nullable()();
  TextColumn get staplePairing => textEnum<StaplePairing>()();
  TextColumn get cookingStyle => textEnum<CookingStyle>()();
  IntColumn get prepMinutes => integer()();
  BoolColumn get canBeSide => boolean().withDefault(const Constant(false))();
  BoolColumn get isCustom => boolean().withDefault(const Constant(false))();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  TextColumn get variantGroup => text().nullable()();
  TextColumn get notes => text().nullable()();
}

@DataClassName('DishPairingRow')
class DishPairings extends Table {
  IntColumn get mainDishId =>
      integer().references(Dishes, #id, onDelete: KeyAction.cascade)();
  IntColumn get sideDishId =>
      integer().references(Dishes, #id, onDelete: KeyAction.cascade)();
  IntColumn get priority => integer().withDefault(const Constant(0))();

  @override
  Set<Column<Object>> get primaryKey => {mainDishId, sideDishId};
}

@DataClassName('PantryItemRow')
@TableIndex(name: 'idx_pantry_items_protein_type', columns: {#proteinType})
class PantryItems extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get proteinType => textEnum<ProteinType>()();
  IntColumn get quantityGrams => integer()();
  DateTimeColumn get addedOn => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
}

@DataClassName('PantryMovementRow')
@TableIndex(name: 'idx_pantry_movements_dinner_log', columns: {#dinnerLogId})
class PantryMovements extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get pantryItemId => integer().references(PantryItems, #id)();
  IntColumn get deltaGrams => integer()();
  TextColumn get reason => textEnum<MovementReason>()();
  IntColumn get dinnerLogId => integer().nullable().references(
    DinnerLog,
    #id,
    onDelete: KeyAction.setNull,
  )();
  DateTimeColumn get createdAt => dateTime()();
}

@DataClassName('DinnerLogRow')
class DinnerLog extends Table {
  @override
  String get tableName => 'dinner_log';

  IntColumn get id => integer().autoIncrement()();
  TextColumn get date => text().map(const DateOnlyConverter()).unique()();
  TextColumn get dayType => textEnum<DayType>()();
  TextColumn get source => textEnum<DinnerSource>()();
  IntColumn get mainDishId => integer().nullable().references(Dishes, #id)();
  IntColumn get sideDishId => integer().nullable().references(Dishes, #id)();
  TextColumn get outsideNote => text().nullable()();
  BoolColumn get wasSuggested => boolean().withDefault(const Constant(true))();
  DateTimeColumn get createdAt => dateTime()();
}

@DataClassName('SettingRow')
class AppSettingsEntries extends Table {
  @override
  String get tableName => 'app_settings';

  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column<Object>> get primaryKey => {key};
}
