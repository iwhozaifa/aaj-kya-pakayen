import 'package:aaj_kya_pakayen/core/utils/clock.dart';
import 'package:aaj_kya_pakayen/domain/enums/protein_type.dart';
import 'package:aaj_kya_pakayen/domain/usecases/summarize_pantry.dart';
import 'package:aaj_kya_pakayen/features/pantry/pantry_controller.dart';
import 'package:aaj_kya_pakayen/features/pantry/pantry_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/pump_app.dart';

class _MockActions extends Mock implements PantryActions;

const _summary = [
  ProteinStock(
    protein: ProteinType.chicken,
    grams: 1500,
    oldestDays: 4,
    isLow: false,
  ),
  ProteinStock(
    protein: ProteinType.beef,
    grams: 750,
    oldestDays: 0,
    isLow: true,
  ),
  ProteinStock(protein: ProteinType.mutton, grams: 0, isLow: true),
  ProteinStock(
    protein: ProteinType.mince,
    grams: 1000,
    oldestDays: 1,
    isLow: false,
  ),
];

void main() {
  late _MockActions actions;
  const undoToken = PantryUndo([1]);
  final today = DateTime(2026, 10, 15);

  setUpAll(() {
    registerFallbackValue(ProteinType.chicken);
    registerFallbackValue(undoToken);
    registerFallbackValue(DateTime(2026));
  });

  setUp(() {
    actions = _MockActions();
    when(() => actions.increase(any())).thenAnswer((_) async => undoToken);
    when(() => actions.decrease(any())).thenAnswer((_) async => undoToken);
    when(
      () => actions.addPurchase(any(), any(), boughtOn: any(named: 'boughtOn')),
    ).thenAnswer((_) async => undoToken);
    when(() => actions.undo(any())).thenAnswer((_) async {});
  });

  Future<void> pump(WidgetTester tester, {Locale locale = english}) async {
    tester.view
      ..physicalSize = const Size(1080, 2340)
      ..devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          pantrySummaryProvider.overrideWithValue(const AsyncData(_summary)),
          pantryActionsProvider.overrideWithValue(actions),
          clockProvider.overrideWithValue(() => today),
        ],
        child: const PantryScreen(),
      ).wrapInApp(locale: locale),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('shows a tile per protein with amounts and low stock', (
    tester,
  ) async {
    await pump(tester);

    for (final name in ['Chicken', 'Beef', 'Mutton', 'Mince']) {
      expect(find.text(name), findsOneWidget);
    }
    expect(find.text('1.5 kg'), findsOneWidget);
    expect(find.text('750 g'), findsOneWidget);
    expect(find.text('1 kg'), findsOneWidget);
    expect(find.text('None in stock'), findsOneWidget);
    expect(find.text('Low'), findsNWidgets(2));
    expect(find.text('Oldest: 4 days'), findsOneWidget);
    expect(find.text('Oldest: bought today'), findsOneWidget);
  });

  testWidgets('+ adds stock and offers undo', (tester) async {
    await pump(tester);

    await tester.tap(find.byTooltip('Add 250 g of Chicken'));
    await tester.pumpAndSettle();
    verify(() => actions.increase(ProteinType.chicken)).called(1);
    expect(find.text('250 g Chicken added'), findsOneWidget);

    await tester.tap(find.text('Undo'));
    await tester.pumpAndSettle();
    verify(() => actions.undo(undoToken)).called(1);
  });

  testWidgets('− removes stock and offers undo', (tester) async {
    await pump(tester);

    await tester.tap(find.byTooltip('Remove 250 g of Beef'));
    await tester.pumpAndSettle();
    verify(() => actions.decrease(ProteinType.beef)).called(1);
    expect(find.text('Beef reduced'), findsOneWidget);
  });

  testWidgets('− is disabled when there is nothing to remove', (tester) async {
    await pump(tester);

    await tester.tap(find.byTooltip('Remove 250 g of Mutton'));
    await tester.pumpAndSettle();
    verifyNever(() => actions.decrease(any()));
  });

  testWidgets('add purchase records protein, amount and date', (tester) async {
    await pump(tester);

    await tester.tap(find.text('Add purchase'));
    await tester.pumpAndSettle();
    expect(find.text('What did you buy?'), findsOneWidget);

    await tester.tap(find.widgetWithText(ChoiceChip, 'Beef'));
    await tester.tap(find.widgetWithText(ChoiceChip, '1.5 kg'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    verify(() => actions.addPurchase(ProteinType.beef, 1500, boughtOn: today))
        .called(1);
    expect(find.text('1.5 kg Beef added'), findsOneWidget);
  });

  testWidgets('the purchase sheet closes with a visible Cancel button', (
    tester,
  ) async {
    await pump(tester);

    await tester.tap(find.text('Add purchase'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Cancel'));
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(find.text('What did you buy?'), findsNothing);
    verifyNever(
      () => actions.addPurchase(any(), any(), boughtOn: any(named: 'boughtOn')),
    );
  });

  testWidgets('meets tap target and label guidelines', (tester) async {
    final handle = tester.ensureSemantics();
    await pump(tester);

    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    handle.dispose();
  });

  for (final locale in [urdu, english]) {
    testWidgets('golden (${locale.languageCode})', (tester) async {
      await pump(tester, locale: locale);
      await expectLater(
        find.byType(PantryScreen),
        matchesGoldenFile('goldens/pantry_${locale.languageCode}.png'),
      );
    });
  }
}
