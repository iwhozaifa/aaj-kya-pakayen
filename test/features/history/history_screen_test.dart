import 'package:aaj_kya_pakayen/core/utils/clock.dart';
import 'package:aaj_kya_pakayen/data/providers.dart';
import 'package:aaj_kya_pakayen/data/seed/pakistani_dishes.dart';
import 'package:aaj_kya_pakayen/domain/entities/dinner_log_entry.dart';
import 'package:aaj_kya_pakayen/domain/entities/dish.dart';
import 'package:aaj_kya_pakayen/domain/enums/day_type.dart';
import 'package:aaj_kya_pakayen/domain/enums/dinner_source.dart';
import 'package:aaj_kya_pakayen/features/history/history_controller.dart';
import 'package:aaj_kya_pakayen/features/history/history_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/pump_app.dart';

class _MockActions extends Mock implements HistoryActions;

final Map<String, Dish> _byName = {
  for (final d in pakistaniDishes) d.nameEn: d,
};
final _today = DateTime(2026, 10, 15);
DateTime _day(int d) => DateTime(2026, 10, d);
String _label(DateTime d) => DateFormat.MMMEd('en').format(d);

final _karahiNight = HistoryEntry(
  entry: DinnerLogEntry(
    id: 3,
    date: _day(14),
    dayType: DayType.nonVegDay,
    source: DinnerSource.home,
    mainDishId: 50,
    sideDishId: 2,
  ),
  main: _byName['Chicken Karahi'],
  side: _byName['Bhindi Masala'],
);

final _outsideNight = HistoryEntry(
  entry: DinnerLogEntry(
    id: 2,
    date: _day(12),
    dayType: DayType.nonVegDay,
    source: DinnerSource.outside,
    outsideNote: 'nihari from Javed',
  ),
);

final _daalNight = HistoryEntry(
  entry: DinnerLogEntry(
    id: 1,
    date: _day(11),
    dayType: DayType.vegDay,
    source: DinnerSource.home,
    mainDishId: 30,
  ),
  main: _byName['Daal Chawal'],
);

HistoryState _state(List<HistoryEntry> entries) => HistoryState(
  week: [
    for (var d = 9; d <= 15; d++)
      HistoryDay(
        date: _day(d),
        entry: entries.where((e) => e.entry.date == _day(d)).firstOrNull,
      ),
  ],
  entries: entries,
);

void main() {
  late _MockActions actions;
  final full = _state([_karahiNight, _outsideNight, _daalNight]);

  setUpAll(() {
    registerFallbackValue(_karahiNight);
    registerFallbackValue(_byName['Daal Chawal']);
    registerFallbackValue(DateTime(2026));
  });

  setUp(() {
    actions = _MockActions();
    when(
      () => actions.saveHome(
        any(),
        main: any(named: 'main'),
        side: any(named: 'side'),
      ),
    ).thenAnswer((_) async => 9);
    when(() => actions.saveOutside(any(), note: any(named: 'note')))
        .thenAnswer((_) async => 9);
    when(() => actions.delete(any())).thenAnswer((_) async {});
    when(() => actions.restore(any())).thenAnswer((_) async {});
    when(() => actions.removeById(any())).thenAnswer((_) async {});
  });

  Future<void> pump(
    WidgetTester tester,
    HistoryState state, {
    Locale locale = english,
  }) async {
    tester.view
      ..physicalSize = const Size(1080, 2340)
      ..devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          historyStateProvider.overrideWithValue(AsyncData(state)),
          historyActionsProvider.overrideWithValue(actions),
          activeDishesProvider.overrideWithValue(AsyncData(pakistaniDishes)),
          clockProvider.overrideWithValue(() => _today),
        ],
        child: const HistoryScreen(),
      ).wrapInApp(locale: locale),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('lists dinners newest first with dishes and notes', (
    tester,
  ) async {
    await pump(tester, full);

    expect(find.text('Last 7 days'), findsOneWidget);
    expect(find.text('Chicken Karahi'), findsOneWidget);
    expect(find.text('with Bhindi Masala'), findsOneWidget);
    expect(find.text('Ordered from outside'), findsOneWidget);
    expect(find.text('nihari from Javed'), findsOneWidget);
    expect(find.text('Daal Chawal'), findsOneWidget);
    expect(
      tester.getTopLeft(find.text('Chicken Karahi')).dy,
      lessThan(tester.getTopLeft(find.text('Daal Chawal')).dy),
    );
  });

  testWidgets('the week strip has a tappable chip per day', (tester) async {
    await pump(tester, full);

    for (var d = 9; d <= 15; d++) {
      expect(find.text('$d'), findsOneWidget);
    }
    await tester.tap(find.byTooltip('Add dinner for ${_label(_day(13))}'));
    await tester.pumpAndSettle();
    expect(find.text('Dinner on ${_label(_day(13))}'), findsOneWidget);
  });

  testWidgets('logging a missed day as outside', (tester) async {
    await pump(tester, full);

    await tester.tap(find.byTooltip('Add dinner for ${_label(_day(13))}'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ordered outside'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'pizza');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    verify(() => actions.saveOutside(_day(13), note: 'pizza')).called(1);
    expect(find.text('Dinner on ${_label(_day(13))} saved'), findsOneWidget);

    await tester.tap(find.text('Undo'));
    await tester.pumpAndSettle();
    verify(() => actions.removeById(9)).called(1);
  });

  testWidgets('editing a dinner changes the dish; undo restores it', (
    tester,
  ) async {
    await pump(tester, full);

    await tester.tap(find.text('Chicken Karahi'));
    await tester.pumpAndSettle();
    expect(find.text('Dinner on ${_label(_day(14))}'), findsOneWidget);

    final field = find.descendant(
      of: find.byType(DropdownMenu<Dish>),
      matching: find.byType(TextField),
    );
    await tester.tap(field);
    await tester.pumpAndSettle();
    await tester.enterText(field, 'Aloo Q');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Aloo Qeema').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    final main =
        verify(
              () => actions.saveHome(
                _day(14),
                main: captureAny(named: 'main'),
                side: any(named: 'side'),
              ),
            ).captured.single
            as Dish;
    expect(main.nameEn, 'Aloo Qeema');

    await tester.tap(find.text('Undo'));
    await tester.pumpAndSettle();
    verify(() => actions.restore(_karahiNight)).called(1);
  });

  testWidgets('deleting a dinner can be undone', (tester) async {
    await pump(tester, full);

    await tester.tap(find.text('Daal Chawal'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();

    verify(() => actions.delete(_daalNight)).called(1);
    expect(find.text('Dinner on ${_label(_day(11))} deleted'), findsOneWidget);
    await tester.tap(find.text('Undo'));
    await tester.pumpAndSettle();
    verify(() => actions.restore(_daalNight)).called(1);
  });

  testWidgets('shows a friendly empty state', (tester) async {
    await pump(tester, _state(const []));
    expect(find.text('No dinners logged yet'), findsOneWidget);
  });

  testWidgets('meets tap target, label and contrast guidelines', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await pump(tester, full);

    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    await expectLater(tester, meetsGuideline(textContrastGuideline));
    handle.dispose();
  });

  for (final locale in [urdu, english]) {
    testWidgets('golden (${locale.languageCode})', (tester) async {
      await pump(tester, full, locale: locale);
      await expectLater(
        find.byType(HistoryScreen),
        matchesGoldenFile('goldens/history_${locale.languageCode}.png'),
      );
    });
  }
}
