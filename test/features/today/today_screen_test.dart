import 'package:aaj_kya_pakayen/data/seed/pakistani_dishes.dart';
import 'package:aaj_kya_pakayen/domain/engine/reason.dart';
import 'package:aaj_kya_pakayen/domain/engine/rules/day_type_rule.dart';
import 'package:aaj_kya_pakayen/domain/engine/suggestion_engine.dart';
import 'package:aaj_kya_pakayen/domain/entities/dinner_log_entry.dart';
import 'package:aaj_kya_pakayen/domain/enums/cooking_style.dart';
import 'package:aaj_kya_pakayen/domain/enums/day_type.dart';
import 'package:aaj_kya_pakayen/domain/enums/dinner_source.dart';
import 'package:aaj_kya_pakayen/domain/enums/protein_type.dart';
import 'package:aaj_kya_pakayen/domain/enums/staple_pairing.dart';
import 'package:aaj_kya_pakayen/features/today/today_controller.dart';
import 'package:aaj_kya_pakayen/features/today/today_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/pump_app.dart';

class _MockActions extends Mock implements TodayActions;

final _byName = {for (final d in pakistaniDishes) d.nameEn: d};

final _vegDay = TodayState(
  result: SuggestionResult(
    day: const DayTypeResolution(naturalDayType: DayType.vegDay),
    suggestions: [
      HomeSuggestion(
        main: _byName['Daal Chawal']!,
        score: 10,
        reasons: const [
          Reason.servedWith(staple: StaplePairing.rice),
          Reason.fitsTime(minutes: 40),
          Reason.notCookedFor(days: 21),
        ],
      ),
      HomeSuggestion(main: _byName['Aloo Gobi']!, score: 8, reasons: const []),
      HomeSuggestion(main: _byName['Lauki']!, score: 7, reasons: const []),
    ],
  ),
);

final _karahi = HomeSuggestion(
  main: _byName['Chicken Karahi']!,
  side: _byName['Bhindi Masala'],
  score: 20,
  reasons: const [
    Reason.proteinInStock(protein: ProteinType.chicken, days: 4),
    Reason.differentProtein(previous: ProteinType.beef),
    Reason.freshStyle(style: CookingStyle.karahi),
  ],
);

final _meatDay = TodayState(
  result: SuggestionResult(
    day: const DayTypeResolution(naturalDayType: DayType.nonVegDay),
    suggestions: [
      _karahi,
      HomeSuggestion(main: _byName['Aloo Qeema']!, score: 9, reasons: const []),
    ],
  ),
);

final _noStock = TodayState(
  result: SuggestionResult(
    day: const DayTypeResolution(naturalDayType: DayType.nonVegDay),
    suggestions: const [
      OutsideSuggestion(
        restock: {ProteinType.chicken, ProteinType.beef},
        reasons: [
          Reason.restock(proteins: {ProteinType.chicken, ProteinType.beef}),
        ],
      ),
    ],
  ),
);

final _logged = TodayState(
  result: _meatDay.result,
  tonight: DinnerLogEntry(
    id: 42,
    date: DateTime(2026, 10, 15),
    dayType: DayType.nonVegDay,
    source: DinnerSource.home,
    mainDishId: 50,
    sideDishId: 2,
  ),
  tonightMain: _byName['Chicken Karahi'],
  tonightSide: _byName['Bhindi Masala'],
);

void main() {
  late _MockActions actions;

  setUpAll(() {
    registerFallbackValue(_karahi);
    registerFallbackValue(DayType.vegDay);
    registerFallbackValue(_meatDay.result);
  });

  setUp(() {
    actions = _MockActions();
    when(() => actions.cook(any(), any())).thenAnswer((_) async => 42);
    when(() => actions.orderOutside(any())).thenAnswer((_) async => 43);
    when(() => actions.undo(any())).thenAnswer((_) async {});
    when(() => actions.swapDayType(any())).thenAnswer((_) async {});
  });

  Future<void> pump(
    WidgetTester tester,
    TodayState state, {
    Locale locale = english,
  }) async {
    tester.view
      ..physicalSize = const Size(1080, 2340)
      ..devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          todayStateProvider.overrideWithValue(AsyncData(state)),
          todayActionsProvider.overrideWithValue(actions),
        ],
        child: const TodayScreen(),
      ).wrapInApp(locale: locale),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('veg day shows the top dish with its reasons', (tester) async {
    await pump(tester, _vegDay);

    expect(find.text('Sabzi day'), findsOneWidget);
    expect(find.text('Daal Chawal'), findsOneWidget);
    expect(find.text('Goes with rice'), findsOneWidget);
    expect(find.text('Ready in 40 min'), findsOneWidget);
    expect(find.text('Not cooked for 21 days'), findsOneWidget);
    expect(find.text('Cooking this'), findsOneWidget);
    expect(find.text('Ordering outside'), findsNothing);
  });

  testWidgets('meat day shows the side, reasons and outside option', (
    tester,
  ) async {
    await pump(tester, _meatDay);

    expect(find.text('Gosht day'), findsOneWidget);
    expect(find.text('Chicken Karahi'), findsOneWidget);
    expect(find.text('with Bhindi Masala'), findsOneWidget);
    expect(find.text('Chicken in stock for 4 days'), findsOneWidget);
    expect(find.text('Not beef again'), findsOneWidget);
    expect(find.text('No karahi this week'), findsOneWidget);
    expect(find.text('Ordering outside'), findsOneWidget);
  });

  testWidgets('cooking this logs it and offers undo', (tester) async {
    await pump(tester, _meatDay);

    await tester.tap(find.text('Cooking this'));
    await tester.pumpAndSettle();
    verify(() => actions.cook(_karahi, DayType.nonVegDay)).called(1);
    expect(find.text('Chicken Karahi logged for tonight'), findsOneWidget);

    await tester.tap(find.text('Undo'));
    await tester.pumpAndSettle();
    verify(() => actions.undo(42)).called(1);
  });

  testWidgets('another idea can be cooked instead', (tester) async {
    await pump(tester, _meatDay);

    await tester.tap(find.widgetWithText(TextButton, 'Cook'));
    await tester.pumpAndSettle();
    final cooked =
        verify(() => actions.cook(captureAny(), DayType.nonVegDay))
                .captured
                .single
            as HomeSuggestion;
    expect(cooked.main.nameEn, 'Aloo Qeema');
  });

  testWidgets('show another and swap call their actions', (tester) async {
    await pump(tester, _vegDay);

    await tester.tap(find.text('Show another'));
    verify(() => actions.showAnother()).called(1);
    await tester.tap(find.text('Swap day type'));
    await tester.pumpAndSettle();
    verify(() => actions.swapDayType(_vegDay.result)).called(1);
  });

  testWidgets('ordering outside asks for an optional note', (tester) async {
    await pump(tester, _meatDay);

    await tester.tap(find.text('Ordering outside'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'biryani from Student');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    verify(() => actions.orderOutside('biryani from Student')).called(1);
    expect(find.text('Outside dinner logged'), findsOneWidget);
  });

  testWidgets('no stock: outside is the suggestion, with a restock hint', (
    tester,
  ) async {
    await pump(tester, _noStock);

    expect(find.text('Order from outside tonight'), findsOneWidget);
    expect(find.text('Buy chicken or beef to cook at home'), findsOneWidget);
    expect(find.text('Cooking this'), findsNothing);
    expect(find.text('Show another'), findsNothing);
  });

  testWidgets('once logged, shows tonight with a way to change it', (
    tester,
  ) async {
    await pump(tester, _logged);

    expect(find.text("Tonight's dinner"), findsOneWidget);
    expect(find.text('Chicken Karahi'), findsOneWidget);
    expect(find.text('with Bhindi Masala'), findsOneWidget);
    expect(find.text('Cooking this'), findsNothing);

    await tester.tap(find.text('Change'));
    await tester.pumpAndSettle();
    verify(() => actions.undo(42)).called(1);
  });

  testWidgets('Urdu shows Urdu dish names', (tester) async {
    await pump(tester, _meatDay, locale: urdu);

    expect(find.text('گوشت کا دن'), findsOneWidget);
    expect(find.text('چکن کڑاہی'), findsOneWidget);
  });

  testWidgets('meets tap target and label guidelines', (tester) async {
    final handle = tester.ensureSemantics();
    await pump(tester, _meatDay);

    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    handle.dispose();
  });

  for (final (name, state) in [
    ('veg', _vegDay),
    ('meat', _meatDay),
    ('outside', _noStock),
    ('logged', _logged),
  ]) {
    for (final locale in [urdu, english]) {
      testWidgets('golden $name (${locale.languageCode})', (tester) async {
        await pump(tester, state, locale: locale);
        await expectLater(
          find.byType(TodayScreen),
          matchesGoldenFile('goldens/today_${name}_${locale.languageCode}.png'),
        );
      });
    }
  }
}
