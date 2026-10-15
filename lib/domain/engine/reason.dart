// freezed can't parse `new` constructors yet (docs/DECISIONS.md D-014).
// ignore_for_file: unnecessary_type_name_in_constructor

import 'package:aaj_kya_pakayen/domain/enums/cooking_style.dart';
import 'package:aaj_kya_pakayen/domain/enums/protein_type.dart';
import 'package:aaj_kya_pakayen/domain/enums/staple_pairing.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'reason.freezed.dart';

/// Why a dish was suggested. The UI turns each into a localized phrase,
/// e.g. "Chicken has been in stock for 4 days".
@freezed
sealed class Reason with _$Reason {
  /// Use-it-first: the oldest batch of [protein] has waited [days].
  const factory Reason.proteinInStock({
    required ProteinType protein,
    required int days,
  }) = ProteinInStockReason;

  /// Last non-veg day was [previous]; this is something else.
  const factory Reason.differentProtein({required ProteinType previous}) =
      DifferentProteinReason;

  /// No [style] dish within the repeat window ("No karahi this week").
  const factory Reason.freshStyle({required CookingStyle style}) =
      FreshStyleReason;

  /// Ready in [minutes], within tonight's time budget.
  const factory Reason.fitsTime({required int minutes}) = FitsTimeReason;

  /// Pulse dish eaten with [staple].
  const factory Reason.servedWith({required StaplePairing staple}) =
      ServedWithReason;

  /// Last cooked [days] ago.
  const factory Reason.notCookedFor({required int days}) = NotCookedForReason;

  /// No home dish has enough stock; buy one of [proteins].
  const factory Reason.restock({required Set<ProteinType> proteins}) =
      RestockReason;
}
