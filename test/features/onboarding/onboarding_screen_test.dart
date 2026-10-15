import 'package:aaj_kya_pakayen/domain/enums/protein_type.dart';
import 'package:aaj_kya_pakayen/features/onboarding/onboarding_controller.dart';
import 'package:aaj_kya_pakayen/features/onboarding/onboarding_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/pump_app.dart';

class _MockActions extends Mock implements OnboardingActions;

void main() {
  late _MockActions actions;

  setUp(() {
    actions = _MockActions();
    when(() => actions.chooseLanguage(any())).thenAnswer((_) async {});
    when(
      () => actions.finish(
        languageCode: any(named: 'languageCode'),
        householdSize: any(named: 'householdSize'),
        stock: any(named: 'stock'),
      ),
    ).thenAnswer((_) async {});
  });

  Future<void> pump(WidgetTester tester, {Locale locale = english}) async {
    tester.view
      ..physicalSize = const Size(1080, 2340)
      ..devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [onboardingActionsProvider.overrideWithValue(actions)],
        child: const OnboardingScreen(),
      ).wrapInApp(locale: locale),
    );
    await tester.pumpAndSettle();
  }

  Future<void> tapVisible(WidgetTester tester, Finder finder) async {
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  Finder chip(ProteinType protein, String label) => find.descendant(
    of: find.byKey(ValueKey(protein)),
    matching: find.widgetWithText(ChoiceChip, label),
  );

  testWidgets('walks through language, household and meat stock', (
    tester,
  ) async {
    await pump(tester);
    expect(find.text('Step 1 of 3'), findsOneWidget);

    await tapVisible(tester, find.text('English'));
    verify(() => actions.chooseLanguage('en')).called(1);
    expect(find.text('Step 2 of 3'), findsOneWidget);
    expect(find.text('4 people'), findsOneWidget);

    await tapVisible(tester, find.byTooltip('More people'));
    expect(find.text('5 people'), findsOneWidget);
    await tapVisible(tester, find.text('Next'));

    expect(find.text('Step 3 of 3'), findsOneWidget);
    await tapVisible(tester, chip(ProteinType.chicken, '1 kg'));
    await tapVisible(tester, chip(ProteinType.mince, '500 g'));
    await tapVisible(tester, find.text('Start'));

    verify(
      () => actions.finish(
        languageCode: 'en',
        householdSize: 5,
        stock: {ProteinType.chicken: 1000, ProteinType.mince: 500},
      ),
    ).called(1);
  });

  testWidgets('can go back a step', (tester) async {
    await pump(tester);
    await tapVisible(tester, find.text('اردو'));
    expect(find.text('Step 2 of 3'), findsOneWidget);

    await tapVisible(tester, find.text('Back'));
    expect(find.text('Step 1 of 3'), findsOneWidget);
  });

  testWidgets('meat step meets tap target, label and contrast guidelines', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await pump(tester);
    await tapVisible(tester, find.text('English'));
    await tapVisible(tester, find.text('Next'));

    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    await expectLater(tester, meetsGuideline(textContrastGuideline));
    handle.dispose();
  });

  testWidgets('golden: language step (ur)', (tester) async {
    await pump(tester, locale: urdu);
    await expectLater(
      find.byType(OnboardingScreen),
      matchesGoldenFile('goldens/onboarding_language_ur.png'),
    );
  });

  testWidgets('golden: meat step (en)', (tester) async {
    await pump(tester);
    await tapVisible(tester, find.text('English'));
    await tapVisible(tester, find.text('Next'));
    await expectLater(
      find.byType(OnboardingScreen),
      matchesGoldenFile('goldens/onboarding_stock_en.png'),
    );
  });
}
