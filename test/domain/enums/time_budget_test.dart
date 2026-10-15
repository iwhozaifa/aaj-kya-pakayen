import 'package:aaj_kya_pakayen/domain/enums/time_budget.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('quick allows up to 30 minutes', () {
    expect(TimeBudget.quick.allows(30), isTrue);
    expect(TimeBudget.quick.allows(31), isFalse);
  });

  test('normal allows up to 60 minutes', () {
    expect(TimeBudget.normal.allows(60), isTrue);
    expect(TimeBudget.normal.allows(61), isFalse);
  });

  test('elaborate allows anything', () {
    expect(TimeBudget.elaborate.allows(600), isTrue);
    expect(TimeBudget.elaborate.maxMinutes, isNull);
  });
}
