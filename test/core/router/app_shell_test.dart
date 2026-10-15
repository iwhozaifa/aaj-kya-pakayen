import 'package:aaj_kya_pakayen/app.dart';
import 'package:aaj_kya_pakayen/data/db/app_database.dart';
import 'package:aaj_kya_pakayen/data/providers.dart';
import 'package:aaj_kya_pakayen/features/dishes/dishes_screen.dart';
import 'package:aaj_kya_pakayen/features/history/history_screen.dart';
import 'package:aaj_kya_pakayen/features/pantry/pantry_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/test_database.dart';

void main() {
  late AppDatabase db;

  setUp(() => db = newTestDatabase());
  tearDown(() => db.close());

  testWidgets(
    'bottom navigation switches between Today, Stock, History and Dishes',
    (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [appDatabaseProvider.overrideWithValue(db)],
          child: const App(),
        ),
      );
      await tester.pumpAndSettle();

      final bar = find.byType(NavigationBar);
      expect(bar, findsOneWidget);
      expect(
        find.descendant(of: bar, matching: find.text('آج')),
        findsOneWidget,
      );

      await tester.tap(find.descendant(of: bar, matching: find.text('اسٹاک')));
      await tester.pumpAndSettle();
      expect(find.byType(PantryScreen), findsOneWidget);
      expect(find.text('گوشت کا اسٹاک'), findsOneWidget);

      await tester.tap(
        find.descendant(of: bar, matching: find.text('پچھلے کھانے')),
      );
      await tester.pumpAndSettle();
      expect(find.byType(HistoryScreen), findsOneWidget);

      await tester.tap(find.descendant(of: bar, matching: find.text('پکوان')));
      await tester.pumpAndSettle();
      expect(find.byType(DishesScreen), findsOneWidget);
      expect(find.text('چکن کڑاہی'), findsOneWidget);

      await tester.tap(find.descendant(of: bar, matching: find.text('آج')));
      await tester.pumpAndSettle();
      expect(find.text('آج کیا پکائیں؟'), findsOneWidget);

      // Let drift close its stream queries before the test ends.
      await tester.pumpWidget(const SizedBox());
      await tester.pump(Duration.zero);
    },
  );
}
