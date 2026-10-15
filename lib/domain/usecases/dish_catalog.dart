import 'package:aaj_kya_pakayen/domain/entities/dish.dart';
import 'package:aaj_kya_pakayen/domain/enums/cooking_style.dart';
import 'package:aaj_kya_pakayen/domain/enums/dish_type.dart';
import 'package:aaj_kya_pakayen/domain/enums/staple_pairing.dart';
import 'package:aaj_kya_pakayen/domain/repositories/dish_repository.dart';

/// Lower case with runs of whitespace collapsed, for forgiving matches.
String _normalize(String text) =>
    text.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');

/// Dishes matching [query] (either name) and [type]; hidden ones last.
List<Dish> filterDishes(
  List<Dish> dishes, {
  String query = '',
  DishType? type,
}) {
  final q = _normalize(query);
  bool matches(Dish d) =>
      (type == null || d.dishType == type) &&
      (q.isEmpty ||
          _normalize(d.nameEn).contains(q) ||
          _normalize(d.nameUr).contains(q));
  final found = dishes.where(matches);
  return [
    ...found.where((d) => d.isActive),
    ...found.where((d) => !d.isActive),
  ];
}

/// The dish already called [name] in either language, if any.
Dish? findByName(Iterable<Dish> dishes, String name) {
  final n = _normalize(name);
  return dishes
      .where((d) => _normalize(d.nameEn) == n || _normalize(d.nameUr) == n)
      .firstOrNull;
}

/// Raw meat per adult for a custom dish; null for veg dishes.
int? defaultProteinGrams(DishType type) => switch (type) {
  DishType.vegetable || DishType.pulse => null,
  DishType.mince => 150,
  DishType.chicken || DishType.beef || DishType.mutton => 200,
};

/// What the cook fills in for a dish of her own.
final class CustomDishDraft {
  const new({
    required this.name,
    required this.dishType,
    required this.staplePairing,
    required this.cookingStyle,
    required this.prepMinutes,
  });

  final String name;
  final DishType dishType;
  final StaplePairing staplePairing;
  final CookingStyle cookingStyle;
  final int prepMinutes;

  CustomDishDraft copyWith({
    String? name,
    DishType? dishType,
    StaplePairing? staplePairing,
    CookingStyle? cookingStyle,
    int? prepMinutes,
  }) => CustomDishDraft(
    name: name ?? this.name,
    dishType: dishType ?? this.dishType,
    staplePairing: staplePairing ?? this.staplePairing,
    cookingStyle: cookingStyle ?? this.cookingStyle,
    prepMinutes: prepMinutes ?? this.prepMinutes,
  );
}

/// Thrown when a custom dish would duplicate one the cook already has.
final class DuplicateDishException implements Exception {
  const new(this.existing);

  final Dish existing;

  @override
  String toString() => 'DuplicateDishException(${existing.nameEn})';
}

/// Saves a custom dish under the next free custom id.
///
/// The cook types one name in whichever script she likes; it is used for
/// both languages (docs/DECISIONS.md D-029).
class AddCustomDish {
  new(this._dishes);

  final DishRepository _dishes;

  Future<Dish> call(CustomDishDraft draft) async {
    final name = draft.name.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (name.isEmpty) {
      throw ArgumentError.value(draft.name, 'name', 'must not be blank');
    }
    final existing = await _dishes.getAll(includeInactive: true);
    final duplicate = findByName(existing, name);
    if (duplicate != null) throw DuplicateDishException(duplicate);

    final lastCustomId = existing
        .map((d) => d.id)
        .where((id) => id >= firstCustomDishId)
        .fold(firstCustomDishId - 1, (a, b) => a > b ? a : b);
    final dish = Dish(
      id: lastCustomId + 1,
      nameEn: name,
      nameUr: name,
      dishType: draft.dishType,
      proteinGramsPerPerson: defaultProteinGrams(draft.dishType),
      staplePairing: draft.staplePairing,
      cookingStyle: draft.cookingStyle,
      prepMinutes: draft.prepMinutes,
      isCustom: true,
    );
    await _dishes.upsertAll([dish]);
    return dish;
  }
}
