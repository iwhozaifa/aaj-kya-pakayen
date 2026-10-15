// freezed can't parse `new` constructors yet (docs/DECISIONS.md D-014).
// ignore_for_file: unnecessary_type_name_in_constructor

import 'package:freezed_annotation/freezed_annotation.dart';

part 'dish_pairing.freezed.dart';
part 'dish_pairing.g.dart';

/// A curated side for a main dish. Lower [priority] is preferred.
@freezed
abstract class DishPairing with _$DishPairing {
  const factory DishPairing({
    required int mainDishId,
    required int sideDishId,
    @Default(0) int priority,
  }) = _DishPairing;

  factory DishPairing.fromJson(Map<String, dynamic> json) =>
      _$DishPairingFromJson(json);
}
