// freezed can't parse `new` constructors yet (docs/DECISIONS.md D-014).
// ignore_for_file: unnecessary_type_name_in_constructor

import 'package:aaj_kya_pakayen/domain/enums/cooking_style.dart';
import 'package:aaj_kya_pakayen/domain/enums/dish_type.dart';
import 'package:aaj_kya_pakayen/domain/enums/protein_type.dart';
import 'package:aaj_kya_pakayen/domain/enums/staple_pairing.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'dish.freezed.dart';
part 'dish.g.dart';

/// Ids below this are built-in dishes; custom dishes count up from here.
const firstCustomDishId = 10000;

@freezed
abstract class Dish with _$Dish {
  const factory Dish({
    required int id,
    required String nameEn,
    required String nameUr,
    required DishType dishType,
    required StaplePairing staplePairing,
    required CookingStyle cookingStyle,
    required int prepMinutes,
    @Default('pakistani') String cuisine,
    int? proteinGramsPerPerson,
    @Default(false) bool canBeSide,
    @Default(false) bool isCustom,
    @Default(true) bool isActive,

    /// Dishes sharing a group count as one for the no-repeat rule
    /// (e.g. chicken karahi and white karahi).
    String? variantGroup,
    String? notes,
  }) = _Dish;

  const Dish._();

  factory Dish.fromJson(Map<String, dynamic> json) => _$DishFromJson(json);

  bool get isVeg => dishType.isVeg;

  ProteinType? get proteinType => dishType.proteinType;

  int proteinGramsFor({required int householdSize}) =>
      (proteinGramsPerPerson ?? 0) * householdSize;

  /// Key used by the no-repeat rule.
  String get variantKey => variantGroup ?? 'dish:$id';
}
