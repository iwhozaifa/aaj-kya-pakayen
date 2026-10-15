import 'package:aaj_kya_pakayen/app.dart';
import 'package:aaj_kya_pakayen/core/utils/clock.dart';
import 'package:aaj_kya_pakayen/data/db/app_database.dart';
import 'package:aaj_kya_pakayen/data/providers.dart';
import 'package:aaj_kya_pakayen/data/repositories_impl/drift_dinner_log_repository.dart';
import 'package:aaj_kya_pakayen/data/repositories_impl/drift_pantry_repository.dart';
import 'package:aaj_kya_pakayen/data/repositories_impl/drift_settings_repository.dart';
import 'package:aaj_kya_pakayen/data/seed/dish_seeder.dart';
import 'package:aaj_kya_pakayen/domain/entities/app_settings.dart';
import 'package:aaj_kya_pakayen/domain/entities/dinner_log_entry.dart';
import 'package:aaj_kya_pakayen/domain/enums/day_type.dart';
import 'package:aaj_kya_pakayen/domain/enums/dinner_source.dart';
import 'package:aaj_kya_pakayen/domain/enums/protein_type.dart';
import 'package:aaj_kya_pakayen/features/dishes/add_dish_sheet.dart';
import 'package:aaj_kya_pakayen/features/history/edit_dinner_sheet.dart';
import 'package:aaj_kya_pakayen/features/onboarding/onboarding_screen.dart';
import 'package:aaj_kya_pakayen/features/pantry/add_purchase_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/test_database.dart';

/// Every screen and sheet at twice the normal text size on a small
/// (360 × 780 dp) phone. Any overflow fails the test.
void main() {
  late AppDatabase db;
  late ProviderContainer container;
  final now = DateTime(2026, 10, 15, 18);

  Future<void> setUpApp({required String language, bool onboarded = true}) =>
      Future(() async {
        db = newTestDatabase();
        await DishSeeder(db).seedIfNeeded();
        await DriftSettingsRepository(db).save(
          AppSettings(languageCode: language, onboardingComplete: onboarded),
        );
        await DriftPantryRepository(db).addPurchase(
          proteinType: ProteinType.chicken,
          grams: 1500,
          addedOn: DateTime(2026, 10, 10),
        );
        final log = DriftDinnerLogRepository(db);
        await log.save(
          DinnerLogEntry(
            date: DateTime(2026, 10, 14),
            dayType: DayType.nonVegDay,
            source: DinnerSource.home,
            mainDishId: 50,
            sideDishId: 2,
          ),
        );
        await log.save(
          DinnerLogEntry(
            date: DateTime(2026, 10, 13),
            dayType: DayType.vegDay,
            source: DinnerSource.outside,
            outsideNote: 'Nihari from the corner shop, extra naan',
          ),
        );
        container = ProviderContainer(
          overrides: [
            appDatabaseProvider.overrideWithValue(db),
            clockProvider.overrideWithValue(() => now),
          ],
        );
      });

  Future<void> pumpApp(WidgetTester tester) async {
    tester.view
      ..physicalSize = const Size(1080, 2340)
      ..devicePixelRatio = 3;
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(() {
      tester.view.reset();
      tester.platformDispatcher.clearTextScaleFactorTestValue();
    });
    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const App()),
    );
    await tester.pumpAndSettle();
  }

  Future<void> tearDownApp(WidgetTester tester) async {
    // Let drift close its stream queries before the database goes.
    await tester.pumpWidget(const SizedBox());
    await tester.pump(Duration.zero);
    // Closing drift needs real async, so it happens after the test body.
    addTearDown(() async {
      container.dispose();
      await db.close();
    });
  }

  /// Overflow errors are not the only way large text breaks a screen. Also
  /// fails on a single word split across lines ("Chicke / n") and on text
  /// faded out because it does not fit.
  void expectReadableText(WidgetTester tester, String where) {
    final problems = <String>[];
    for (final element in find.byType(RichText).evaluate()) {
      final paragraph = element.renderObject! as RenderParagraph;
      final text = paragraph.text.toPlainText().trim();
      if (text.isEmpty) continue;
      if (paragraph.debugHasOverflowShader) problems.add('faded: $text');
      // A lone word laid out narrower than its natural width was split.
      if (!text.contains(RegExp(r'\s')) &&
          paragraph.size.width + 0.5 <
              paragraph.getMaxIntrinsicWidth(double.infinity)) {
        problems.add('word split: $text');
      }
    }
    expect(problems, isEmpty, reason: where);
  }

  /// Scrolls the screen's main list to the end so every item is built.
  Future<void> scrollThrough(WidgetTester tester) async {
    final list = find.byType(Scrollable).first;
    for (var i = 0; i < 12; i++) {
      expectReadableText(tester, 'scrolled ${i * 500} dp');
      await tester.drag(list, const Offset(0, -500), warnIfMissed: false);
      await tester.pumpAndSettle();
    }
  }

  Future<void> openTab(WidgetTester tester, IconData icon) async {
    await tester.tap(find.byIcon(icon));
    await tester.pumpAndSettle();
  }

  Future<void> closeSheet(WidgetTester tester) async {
    await tester.tapAt(const Offset(180, 10));
    await tester.pumpAndSettle();
  }

  for (final language in ['ur', 'en']) {
    testWidgets('every tab and sheet fits at 2x text ($language)', (
      tester,
    ) async {
      await tester.runAsync(() => setUpApp(language: language));
      await pumpApp(tester);

      await scrollThrough(tester);

      await openTab(tester, Icons.kitchen_outlined);
      await scrollThrough(tester);
      await tester.tap(find.byIcon(Icons.add_shopping_cart));
      await tester.pumpAndSettle();
      expect(find.byType(AddPurchaseSheet), findsOneWidget);
      await scrollThrough(tester);
      await closeSheet(tester);

      await openTab(tester, Icons.history_outlined);
      await tester.tap(find.byIcon(Icons.set_meal).first);
      await tester.pumpAndSettle();
      expect(find.byType(EditDinnerSheet), findsOneWidget);
      await closeSheet(tester);
      await scrollThrough(tester);

      await openTab(tester, Icons.menu_book_outlined);
      await scrollThrough(tester);
      await tester.tap(find.byIcon(Icons.add).last);
      await tester.pumpAndSettle();
      expect(find.byType(AddDishSheet), findsOneWidget);
      await scrollThrough(tester);
      await closeSheet(tester);

      await openTab(tester, Icons.settings_outlined);
      await scrollThrough(tester);

      await tearDownApp(tester);
    });
  }

  testWidgets('onboarding fits at 2x text', (tester) async {
    await tester.runAsync(() => setUpApp(language: 'ur', onboarded: false));
    await pumpApp(tester);
    expect(find.byType(OnboardingScreen), findsOneWidget);

    await tester.tap(find.text('English'));
    await tester.pumpAndSettle();
    await scrollThrough(tester);
    await tester.tap(find.byIcon(Icons.arrow_forward));
    await tester.pumpAndSettle();
    await scrollThrough(tester);

    await tearDownApp(tester);
  });
}
