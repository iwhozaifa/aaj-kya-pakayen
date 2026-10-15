// freezed can't parse `new` constructors yet (docs/DECISIONS.md D-014).
// ignore_for_file: unnecessary_type_name_in_constructor

import 'package:aaj_kya_pakayen/domain/enums/movement_reason.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'pantry_movement.freezed.dart';
part 'pantry_movement.g.dart';

/// Ledger entry: a change of [deltaGrams] to one pantry batch.
@freezed
abstract class PantryMovement with _$PantryMovement {
  const factory PantryMovement({
    required int id,
    required int pantryItemId,
    required int deltaGrams,
    required MovementReason reason,
    required DateTime createdAt,
    int? dinnerLogId,
  }) = _PantryMovement;

  factory PantryMovement.fromJson(Map<String, dynamic> json) =>
      _$PantryMovementFromJson(json);
}
