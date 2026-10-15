import 'package:aaj_kya_pakayen/domain/engine/rules/pantry_stock.dart';
import 'package:aaj_kya_pakayen/domain/entities/pantry_batch.dart';
import 'package:aaj_kya_pakayen/domain/enums/protein_type.dart';

/// Below this many grams per person a protein is flagged as low stock:
/// not enough for one typical meat dinner for the household.
const lowStockGramsPerPerson = 200;

final class ProteinStock {
  const new({
    required this.protein,
    required this.grams,
    required this.isLow,
    this.oldestDays,
  });

  final ProteinType protein;
  final int grams;
  final bool isLow;

  /// Days the oldest batch with stock has waited; null when empty.
  final int? oldestDays;
}

/// One [ProteinStock] per protein, in [ProteinType] order (the tile order).
List<ProteinStock> summarizePantry({
  required Iterable<PantryBatch> batches,
  required DateTime date,
  required int householdSize,
}) {
  final stock = PantryStock.fromBatches(date: date, batches: batches);
  return [
    for (final protein in ProteinType.values)
      ProteinStock(
        protein: protein,
        grams: stock.gramsOf(protein),
        oldestDays: stock.oldestBatchDays(protein),
        isLow: stock.gramsOf(protein) < householdSize * lowStockGramsPerPerson,
      ),
  ];
}
