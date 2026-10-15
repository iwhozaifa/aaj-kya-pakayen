import 'package:aaj_kya_pakayen/data/providers.dart';
import 'package:aaj_kya_pakayen/domain/entities/app_settings.dart';
import 'package:aaj_kya_pakayen/domain/entities/dish.dart';
import 'package:aaj_kya_pakayen/domain/usecases/summarize_pantry.dart';
import 'package:aaj_kya_pakayen/features/dishes/dishes_controller.dart';
import 'package:aaj_kya_pakayen/features/dishes/dishes_screen.dart';
import 'package:aaj_kya_pakayen/features/history/history_controller.dart';
import 'package:aaj_kya_pakayen/features/history/history_screen.dart';
import 'package:aaj_kya_pakayen/features/pantry/pantry_controller.dart';
import 'package:aaj_kya_pakayen/features/pantry/pantry_screen.dart';
import 'package:aaj_kya_pakayen/features/settings/settings_screen.dart';
import 'package:aaj_kya_pakayen/features/today/today_controller.dart';
import 'package:aaj_kya_pakayen/features/today/today_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/pump_app.dart';

/// Every screen that loads data says so plainly when loading fails and
/// offers to try again, which really reloads.
void main() {
  final failure = Exception('disk unavailable');

  Future<void> expectRetry(
    WidgetTester tester, {
    required Widget screen,
    required Override Function(void Function() onLoad) failingOverride,
  }) async {
    var loads = 0;
    await tester.pumpWidget(
      ProviderScope(
        // No automatic retries, so each load is the user's doing.
        retry: (_, _) => null,
        overrides: [failingOverride(() => loads++)],
        child: screen,
      ).wrapInApp(locale: english),
    );
    await tester.pumpAndSettle();

    expect(
      find.text('Something went wrong. Please try again.'),
      findsOneWidget,
    );
    expect(loads, 1);
    await tester.tap(find.text('Try again'));
    await tester.pumpAndSettle();
    expect(loads, 2);
  }

  testWidgets('Today', (tester) async {
    await expectRetry(
      tester,
      screen: const TodayScreen(),
      failingOverride: (onLoad) => todayStateProvider.overrideWith((ref) {
        onLoad();
        return Future<TodayState>.error(failure);
      }),
    );
  });

  testWidgets('Pantry', (tester) async {
    await expectRetry(
      tester,
      screen: const PantryScreen(),
      failingOverride: (onLoad) => pantrySummaryProvider.overrideWith((ref) {
        onLoad();
        return Stream<List<ProteinStock>>.error(failure);
      }),
    );
  });

  testWidgets('History', (tester) async {
    await expectRetry(
      tester,
      screen: const HistoryScreen(),
      failingOverride: (onLoad) => historyStateProvider.overrideWith((ref) {
        onLoad();
        return Future<HistoryState>.error(failure);
      }),
    );
  });

  testWidgets('Dishes', (tester) async {
    await expectRetry(
      tester,
      screen: const DishesScreen(),
      failingOverride: (onLoad) => allDishesProvider.overrideWith((ref) {
        onLoad();
        return Stream<List<Dish>>.error(failure);
      }),
    );
  });

  testWidgets('Settings', (tester) async {
    await expectRetry(
      tester,
      screen: const SettingsScreen(),
      failingOverride: (onLoad) => appSettingsProvider.overrideWith((ref) {
        onLoad();
        return Stream<AppSettings>.error(failure);
      }),
    );
  });
}
