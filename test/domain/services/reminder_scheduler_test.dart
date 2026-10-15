import 'package:aaj_kya_pakayen/domain/services/reminder_scheduler.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const fourThirty = 16 * 60 + 30;

  group('nextDailyOccurrence', () {
    test('is later today when the time has not passed', () {
      expect(
        nextDailyOccurrence(DateTime(2026, 10, 15, 9), fourThirty),
        DateTime(2026, 10, 15, 16, 30),
      );
    });

    test('is tomorrow once the time has passed', () {
      expect(
        nextDailyOccurrence(DateTime(2026, 10, 15, 16, 30), fourThirty),
        DateTime(2026, 10, 16, 16, 30),
      );
      expect(
        nextDailyOccurrence(DateTime(2026, 10, 31, 22), fourThirty),
        DateTime(2026, 11, 1, 16, 30),
      );
    });
  });
}
