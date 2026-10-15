import 'package:aaj_kya_pakayen/domain/entities/dinner_log_entry.dart';
import 'package:aaj_kya_pakayen/domain/entities/pantry_movement.dart';
import 'package:aaj_kya_pakayen/domain/enums/day_type.dart';
import 'package:aaj_kya_pakayen/domain/enums/dinner_source.dart';
import 'package:aaj_kya_pakayen/domain/enums/dish_type.dart';
import 'package:aaj_kya_pakayen/domain/enums/movement_reason.dart';
import 'package:aaj_kya_pakayen/domain/enums/protein_type.dart';
import 'package:aaj_kya_pakayen/domain/repositories/dinner_log_repository.dart';
import 'package:aaj_kya_pakayen/domain/repositories/pantry_repository.dart';
import 'package:aaj_kya_pakayen/domain/usecases/log_dinner.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../engine/fixtures.dart';

class _Log extends Mock implements DinnerLogRepository;

class _Pantry extends Mock implements PantryRepository;

void main() {
  late _Log log;
  late _Pantry pantry;
  late LogDinner logDinner;

  final karahi = dish(10, type: DishType.chicken, grams: 200);
  final bhindi = dish(2, side: true);
  final evening = DateTime(2026, 10, 15, 20);

  PantryMovement movement(int id) => PantryMovement(
    id: id,
    pantryItemId: 1,
    deltaGrams: -100,
    reason: MovementReason.cooked,
    createdAt: evening,
  );

  setUpAll(() {
    registerFallbackValue(
      DinnerLogEntry(
        date: evening,
        dayType: DayType.vegDay,
        source: DinnerSource.home,
      ),
    );
    registerFallbackValue(ProteinType.chicken);
    registerFallbackValue(MovementReason.cooked);
    registerFallbackValue(<int>[]);
  });

  setUp(() {
    log = _Log();
    pantry = _Pantry();
    logDinner = LogDinner(log: log, pantry: pantry);
    when(() => log.getForDate(any())).thenAnswer((_) async => null);
    when(() => log.save(any())).thenAnswer(
      (i) async =>
          (i.positionalArguments.single as DinnerLogEntry).copyWith(id: 7),
    );
    when(() => log.delete(any())).thenAnswer((_) async {});
    when(() => pantry.getBatches(proteinType: any(named: 'proteinType')))
        .thenAnswer((_) async => [batch(1, ProteinType.chicken, 5000)]);
    when(
      () => pantry.deductFifo(
        proteinType: any(named: 'proteinType'),
        grams: any(named: 'grams'),
        reason: any(named: 'reason'),
        dinnerLogId: any(named: 'dinnerLogId'),
      ),
    ).thenAnswer((_) async => [movement(1), movement(2)]);
    when(() => pantry.getMovements(dinnerLogId: any(named: 'dinnerLogId')))
        .thenAnswer((_) async => []);
    when(() => pantry.revertMovements(any())).thenAnswer((_) async {});
  });

  test('cooking at home logs the dinner and deducts its protein', () async {
    final entry = await logDinner.cookAtHome(
      date: evening,
      dayType: DayType.nonVegDay,
      main: karahi,
      side: bhindi,
      householdSize: 4,
    );

    expect(entry.id, 7);
    final saved =
        verify(() => log.save(captureAny())).captured.single as DinnerLogEntry;
    expect(saved.date, DateTime(2026, 10, 15));
    expect(saved.source, DinnerSource.home);
    expect(saved.mainDishId, 10);
    expect(saved.sideDishId, 2);
    expect(saved.wasSuggested, isTrue);
    verify(
      () => pantry.deductFifo(
        proteinType: ProteinType.chicken,
        grams: 800,
        reason: MovementReason.cooked,
        dinnerLogId: 7,
      ),
    ).called(1);
  });

  test('veg dinners touch no stock', () async {
    await logDinner.cookAtHome(
      date: evening,
      dayType: DayType.vegDay,
      main: bhindi,
      householdSize: 4,
    );
    verifyNever(
      () => pantry.deductFifo(
        proteinType: any(named: 'proteinType'),
        grams: any(named: 'grams'),
        reason: any(named: 'reason'),
        dinnerLogId: any(named: 'dinnerLogId'),
      ),
    );
  });

  test('deducts only what is left when stock fell short', () async {
    when(() => pantry.getBatches(proteinType: any(named: 'proteinType')))
        .thenAnswer((_) async => [batch(1, ProteinType.chicken, 300)]);

    await logDinner.cookAtHome(
      date: evening,
      dayType: DayType.nonVegDay,
      main: karahi,
      householdSize: 4,
    );

    verify(
      () => pantry.deductFifo(
        proteinType: ProteinType.chicken,
        grams: 300,
        reason: MovementReason.cooked,
        dinnerLogId: 7,
      ),
    ).called(1);
  });

  test('re-logging a date first gives back the earlier deduction', () async {
    when(() => log.getForDate(any())).thenAnswer(
      (_) async => cooked(0, DayType.nonVegDay, main: 10).copyWith(id: 7),
    );
    when(() => pantry.getMovements(dinnerLogId: 7))
        .thenAnswer((_) async => [movement(4)]);

    await logDinner.orderOutside(date: evening, note: 'biryani');

    verify(() => pantry.revertMovements([4])).called(1);
    final saved =
        verify(() => log.save(captureAny())).captured.single as DinnerLogEntry;
    expect(saved.source, DinnerSource.outside);
    expect(saved.dayType, DayType.nonVegDay);
    expect(saved.outsideNote, 'biryani');
  });

  test('a blank outside note is stored as none', () async {
    await logDinner.orderOutside(date: evening, note: '  ');
    final saved =
        verify(() => log.save(captureAny())).captured.single as DinnerLogEntry;
    expect(saved.outsideNote, isNull);
  });

  test('undo gives the stock back and removes the entry', () async {
    when(() => pantry.getMovements(dinnerLogId: 7))
        .thenAnswer((_) async => [movement(1), movement(2)]);

    await logDinner.undo(7);

    verify(() => pantry.revertMovements([1, 2])).called(1);
    verify(() => log.delete(7)).called(1);
  });
}
