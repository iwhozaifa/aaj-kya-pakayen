import 'package:aaj_kya_pakayen/domain/entities/calendar_date.dart';
import 'package:aaj_kya_pakayen/domain/entities/dish.dart';
import 'package:aaj_kya_pakayen/domain/entities/pantry_batch.dart';
import 'package:aaj_kya_pakayen/domain/enums/protein_type.dart';

/// Hard rule 5: a home meat dish needs enough of its protein for the whole
/// household. Also feeds the use-it-first score.
final class PantryStock {
  new _(this._grams, this._oldestDays);

  factory fromBatches({
    required DateTime date,
    required Iterable<PantryBatch> batches,
  }) {
    final grams = <ProteinType, int>{};
    final oldestDays = <ProteinType, int>{};
    for (final b in batches.where((b) => b.quantityGrams > 0)) {
      grams.update(
        b.proteinType,
        (g) => g + b.quantityGrams,
        ifAbsent: () => b.quantityGrams,
      );
      final days = date.daysSince(b.addedOn);
      oldestDays.update(
        b.proteinType,
        (d) => d > days ? d : days,
        ifAbsent: () => days,
      );
    }
    return PantryStock._(grams, oldestDays);
  }

  final Map<ProteinType, int> _grams;
  final Map<ProteinType, int> _oldestDays;

  int gramsOf(ProteinType protein) => _grams[protein] ?? 0;

  /// Days the oldest batch with stock has been in the pantry.
  int? oldestBatchDays(ProteinType protein) => _oldestDays[protein];

  bool canCook(Dish dish, {required int householdSize}) {
    final protein = dish.proteinType;
    return protein == null ||
        gramsOf(protein) >= dish.proteinGramsFor(householdSize: householdSize);
  }
}
