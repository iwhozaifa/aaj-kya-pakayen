import 'package:aaj_kya_pakayen/data/seed/pakistani_dishes.dart';
import 'package:aaj_kya_pakayen/domain/entities/dish.dart';
import 'package:aaj_kya_pakayen/domain/enums/cooking_style.dart';
import 'package:aaj_kya_pakayen/domain/enums/dish_type.dart';
import 'package:aaj_kya_pakayen/domain/enums/staple_pairing.dart';
import 'package:aaj_kya_pakayen/domain/usecases/dish_catalog.dart';
import 'package:aaj_kya_pakayen/features/dishes/add_dish_sheet.dart';
import 'package:aaj_kya_pakayen/features/dishes/dishes_controller.dart';
import 'package:aaj_kya_pakayen/features/dishes/dishes_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/pump_app.dart';

class _MockActions extends Mock implements DishesActions;

final Map<String, Dish> _byName = {
  for (final d in pakistaniDishes) d.nameEn: d,
};

const _mine = Dish(
  id: firstCustomDishId,
  nameEn: 'Ammi ka Qorma',
  nameUr: 'امی کا قورمہ',
  dishType: DishType.mutton,
  proteinGramsPerPerson: 200,
  staplePairing: StaplePairing.roti,
  cookingStyle: CookingStyle.curry,
  prepMinutes: 90,
  isCustom: true,
);

final List<Dish> _dishes = [
  _byName['Aloo Gobi']!.copyWith(isActive: false),
  _byName['Bhindi Masala']!,
  _byName['Chicken Karahi']!,
  _byName['Daal Chawal']!,
  _mine,
];

void main() {
  late _MockActions actions;

  setUpAll(() {
    registerFallbackValue(_mine);
    registerFallbackValue(
      const CustomDishDraft(
        name: '',
        dishType: DishType.vegetable,
        staplePairing: StaplePairing.roti,
        cookingStyle: CookingStyle.curry,
        prepMinutes: 30,
      ),
    );
  });

  setUp(() {
    actions = _MockActions();
    when(() => actions.setActive(any(), active: any(named: 'active')))
        .thenAnswer((_) async {});
    when(() => actions.addCustom(any())).thenAnswer((_) async => _mine);
    when(() => actions.undoAdd(any())).thenAnswer((_) async {});
  });

  Future<void> pump(
    WidgetTester tester, {
    List<Dish>? dishes,
    Locale locale = english,
  }) async {
    tester.view
      ..physicalSize = const Size(1080, 2340)
      ..devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          allDishesProvider.overrideWithValue(AsyncData(dishes ?? _dishes)),
          dishesActionsProvider.overrideWithValue(actions),
        ],
        child: const DishesScreen(),
      ).wrapInApp(locale: locale),
    );
    await tester.pumpAndSettle();
  }

  Finder search() => find.byType(TextField);

  testWidgets('lists dishes with type and time, hidden ones last', (
    tester,
  ) async {
    await pump(tester);

    expect(find.text('Chicken Karahi'), findsOneWidget);
    expect(find.text('Chicken, 45 min'), findsOneWidget);
    expect(find.text('My dish'), findsOneWidget);
    expect(find.text('Not suggested'), findsOneWidget);
    expect(
      tester.getTopLeft(find.text('Ammi ka Qorma')).dy,
      lessThan(tester.getTopLeft(find.text('Aloo Gobi')).dy),
    );
  });

  testWidgets('search narrows the list', (tester) async {
    await pump(tester);

    await tester.enterText(search(), 'kara');
    await tester.pumpAndSettle();
    expect(find.text('Chicken Karahi'), findsOneWidget);
    expect(find.text('Bhindi Masala'), findsNothing);

    await tester.tap(find.byTooltip('Clear search'));
    await tester.pumpAndSettle();
    expect(find.text('Bhindi Masala'), findsOneWidget);
  });

  testWidgets('type chips filter the list', (tester) async {
    await pump(tester);

    await tester.tap(find.widgetWithText(ChoiceChip, 'Daal'));
    await tester.pumpAndSettle();
    expect(find.text('Daal Chawal'), findsOneWidget);
    expect(find.text('Chicken Karahi'), findsNothing);

    await tester.tap(find.widgetWithText(ChoiceChip, 'All'));
    await tester.pumpAndSettle();
    expect(find.text('Chicken Karahi'), findsOneWidget);
  });

  testWidgets('shows a friendly empty state when nothing matches', (
    tester,
  ) async {
    await pump(tester);
    await tester.enterText(search(), 'pizza');
    await tester.pumpAndSettle();
    expect(find.text('No dishes found'), findsOneWidget);
  });

  testWidgets('hiding a dish can be undone', (tester) async {
    await pump(tester);

    await tester.tap(find.text('Chicken Karahi'));
    await tester.pumpAndSettle();
    final karahi = _byName['Chicken Karahi']!;
    verify(() => actions.setActive(karahi, active: false)).called(1);
    expect(find.text("Chicken Karahi won't be suggested"), findsOneWidget);

    await tester.tap(find.text('Undo'));
    await tester.pumpAndSettle();
    verify(() => actions.setActive(karahi, active: true)).called(1);
  });

  testWidgets('a hidden dish can be suggested again', (tester) async {
    await pump(tester);

    await tester.ensureVisible(find.text('Aloo Gobi'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Aloo Gobi'));
    await tester.pumpAndSettle();
    verify(
      () => actions.setActive(
        _byName['Aloo Gobi']!.copyWith(isActive: false),
        active: true,
      ),
    ).called(1);
    expect(find.text('Aloo Gobi will be suggested again'), findsOneWidget);
  });

  testWidgets('adds a custom dish; undo removes it', (tester) async {
    await pump(tester, dishes: [..._dishes]..remove(_mine));

    await tester.tap(find.text('Add dish'));
    await tester.pumpAndSettle();
    expect(find.text('New dish'), findsOneWidget);

    Finder inSheet(String chip) => find.descendant(
      of: find.byType(AddDishSheet),
      matching: find.widgetWithText(ChoiceChip, chip),
    );
    await tester.tap(inSheet('Mutton'));
    await tester.ensureVisible(inSheet('90 min'));
    await tester.pumpAndSettle();
    await tester.tap(inSheet('90 min'));
    await tester.enterText(find.byType(TextField).last, 'Ammi ka Qorma');
    // Close the keyboard as the cook would before tapping Save.
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Save'));
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    final draft =
        verify(() => actions.addCustom(captureAny())).captured.single
            as CustomDishDraft;
    expect(draft.name, 'Ammi ka Qorma');
    expect(draft.dishType, DishType.mutton);
    expect(draft.prepMinutes, 90);
    expect(find.text('Ammi ka Qorma added'), findsOneWidget);

    await tester.tap(find.text('Undo'));
    await tester.pumpAndSettle();
    verify(() => actions.undoAdd(_mine)).called(1);
  });

  testWidgets('the add sheet refuses blank and duplicate names', (
    tester,
  ) async {
    await pump(tester);
    await tester.tap(find.text('Add dish'));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Save'));
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(find.text('Please write a name'), findsOneWidget);

    await tester.enterText(find.byType(TextField).last, 'bhindi masala');
    await tester.ensureVisible(find.text('Save'));
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(find.text('You already have Bhindi Masala'), findsOneWidget);
    verifyNever(() => actions.addCustom(any()));
  });

  testWidgets('meets tap target, label and contrast guidelines', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await pump(tester);

    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    await expectLater(tester, meetsGuideline(textContrastGuideline));
    handle.dispose();
  });

  for (final locale in [urdu, english]) {
    testWidgets('golden (${locale.languageCode})', (tester) async {
      await pump(tester, locale: locale);
      await expectLater(
        find.byType(DishesScreen),
        matchesGoldenFile('goldens/dishes_${locale.languageCode}.png'),
      );
    });
  }
}
