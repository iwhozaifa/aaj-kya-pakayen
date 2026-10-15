import 'package:aaj_kya_pakayen/domain/entities/dinner_log_entry.dart';
import 'package:aaj_kya_pakayen/domain/entities/dish.dart';
import 'package:aaj_kya_pakayen/domain/entities/pantry_batch.dart';
import 'package:aaj_kya_pakayen/domain/enums/cooking_style.dart';
import 'package:aaj_kya_pakayen/domain/enums/day_type.dart';
import 'package:aaj_kya_pakayen/domain/enums/dinner_source.dart';
import 'package:aaj_kya_pakayen/domain/enums/dish_type.dart';
import 'package:aaj_kya_pakayen/domain/enums/protein_type.dart';
import 'package:aaj_kya_pakayen/domain/enums/staple_pairing.dart';

/// "Tonight" in engine tests.
final today = DateTime(2026, 10, 15);

DateTime daysAgo(int n) => today.subtract(Duration(days: n));

Dish dish(
  int id, {
  DishType type = DishType.vegetable,
  int? grams,
  CookingStyle style = CookingStyle.curry,
  StaplePairing staple = StaplePairing.roti,
  int minutes = 30,
  bool side = false,
  String? group,
  bool active = true,
  String cuisine = 'pakistani',
}) => Dish(
  id: id,
  nameEn: 'Dish $id',
  nameUr: 'ڈش',
  dishType: type,
  proteinGramsPerPerson: grams ?? (type.isVeg ? null : 200),
  staplePairing: staple,
  cookingStyle: style,
  prepMinutes: minutes,
  canBeSide: side,
  variantGroup: group,
  isActive: active,
  cuisine: cuisine,
);

DinnerLogEntry cooked(
  int daysBack,
  DayType dayType, {
  int? main,
  int? side,
  DinnerSource source = DinnerSource.home,
}) => DinnerLogEntry(
  date: daysAgo(daysBack),
  dayType: dayType,
  source: source,
  mainDishId: main,
  sideDishId: side,
);

DinnerLogEntry orderedOutside(int daysBack) => DinnerLogEntry(
  date: daysAgo(daysBack),
  dayType: DayType.nonVegDay,
  source: DinnerSource.outside,
);

PantryBatch batch(
  int id,
  ProteinType protein,
  int grams, {
  int addedDaysAgo = 1,
}) => PantryBatch(
  id: id,
  proteinType: protein,
  quantityGrams: grams,
  addedOn: daysAgo(addedDaysAgo),
  updatedAt: daysAgo(addedDaysAgo),
);
