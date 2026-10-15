import 'package:aaj_kya_pakayen/data/db/app_database.dart';
import 'package:aaj_kya_pakayen/data/repositories_impl/drift_dinner_log_repository.dart';
import 'package:aaj_kya_pakayen/domain/entities/dinner_log_entry.dart';
import 'package:aaj_kya_pakayen/domain/enums/day_type.dart';
import 'package:aaj_kya_pakayen/domain/enums/dinner_source.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/test_database.dart';

void main() {
  late AppDatabase db;
  late DriftDinnerLogRepository repo;
  final now = DateTime(2026, 10, 15, 20, 30);

  DinnerLogEntry outsideOn(int day, {String? note}) => DinnerLogEntry(
    date: DateTime(2026, 10, day),
    dayType: DayType.nonVegDay,
    source: DinnerSource.outside,
    outsideNote: note,
  );

  setUp(() {
    db = newTestDatabase();
    repo = DriftDinnerLogRepository(db, clock: () => now);
  });
  tearDown(() => db.close());

  test('saving assigns an id and creation time', () async {
    final saved = await repo.save(outsideOn(15, note: 'biryani'));

    expect(saved.id, isNotNull);
    expect(saved.createdAt, now);
    expect(await repo.getForDate(DateTime(2026, 10, 15, 23)), saved);
    expect(await repo.getForDate(DateTime(2026, 10, 14)), isNull);
  });

  test(
    'saving the same date again replaces that day, keeping its id',
    () async {
      final first = await repo.save(outsideOn(15));
      final second = await repo.save(
        outsideOn(15).copyWith(
          dayType: DayType.vegDay,
          source: DinnerSource.home,
          wasSuggested: false,
        ),
      );

      expect(second.id, first.id);
      expect(await repo.getSince(DateTime(2026)), [second]);
    },
  );

  test('stores the date without time of day', () async {
    final saved = await repo.save(
      outsideOn(15).copyWith(date: DateTime(2026, 10, 15, 21, 45)),
    );
    expect(saved.date, DateTime(2026, 10, 15));
  });

  test('getSince is inclusive and newest first', () async {
    for (final day in [10, 12, 14, 15]) {
      await repo.save(outsideOn(day));
    }

    final since = await repo.getSince(DateTime(2026, 10, 12));
    expect(since.map((e) => e.date.day), [15, 14, 12]);
    expect((await repo.getLatest())!.date.day, 15);
  });

  test('getLatest is null with no history', () async {
    expect(await repo.getLatest(), isNull);
  });

  test('deletes entries', () async {
    final saved = await repo.save(outsideOn(15));
    await repo.delete(saved.id!);
    expect(await repo.getLatest(), isNull);
  });

  test('watchRecent emits the newest entries', () async {
    await repo.save(outsideOn(14));
    await repo.save(outsideOn(15));

    final recent = await repo.watchRecent(limit: 1).first;
    expect(recent.single.date.day, 15);
  });
}
