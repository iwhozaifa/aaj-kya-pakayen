import 'package:aaj_kya_pakayen/domain/enums/protein_type.dart';
import 'package:aaj_kya_pakayen/domain/usecases/summarize_pantry.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../engine/fixtures.dart';

void main() {
  test('one entry per protein, in tile order, even with no stock', () {
    final summary = summarizePantry(
      batches: const [],
      date: today,
      householdSize: 4,
    );
    expect(summary.map((s) => s.protein), ProteinType.values);
    expect(summary.every((s) => s.grams == 0 && s.oldestDays == null), isTrue);
  });

  test('totals batches and reports the oldest one', () {
    final chicken = summarizePantry(
      batches: [
        batch(1, ProteinType.chicken, 500, addedDaysAgo: 2),
        batch(2, ProteinType.chicken, 700, addedDaysAgo: 5),
      ],
      date: today,
      householdSize: 4,
    ).first;
    expect(chicken.grams, 1200);
    expect(chicken.oldestDays, 5);
  });

  test('stock is low when it cannot feed the household one meal', () {
    ProteinStock beef(int grams) => summarizePantry(
      batches: [batch(1, ProteinType.beef, grams)],
      date: today,
      householdSize: 4,
    )[1];
    expect(beef(799).isLow, isTrue);
    expect(beef(800).isLow, isFalse);
    expect(lowStockGramsPerPerson, 200);
  });
}
