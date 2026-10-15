// freezed can't parse `new` constructors yet (docs/DECISIONS.md D-014).
// ignore_for_file: unnecessary_type_name_in_constructor

import 'package:aaj_kya_pakayen/domain/enums/protein_type.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'pantry_batch.freezed.dart';
part 'pantry_batch.g.dart';

/// One purchase of a protein. Kept per batch so the oldest is used first.
@freezed
abstract class PantryBatch with _$PantryBatch {
  const factory PantryBatch({
    required int id,
    required ProteinType proteinType,
    required int quantityGrams,
    required DateTime addedOn,
    required DateTime updatedAt,
  }) = _PantryBatch;

  factory PantryBatch.fromJson(Map<String, dynamic> json) =>
      _$PantryBatchFromJson(json);
}
