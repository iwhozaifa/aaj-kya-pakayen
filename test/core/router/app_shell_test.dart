import 'package:aaj_kya_pakayen/app.dart';
import 'package:aaj_kya_pakayen/data/db/app_database.dart';
import 'package:aaj_kya_pakayen/data/providers.dart';
import 'package:aaj_kya_pakayen/data/repositories_impl/drift_settings_repository.dart';
import 'package:aaj_kya_pakayen/domain/entities/app_settings.dart';
import 'package:aaj_kya_pakayen/features/dishes/dishes_screen.dart';
import 'package:aaj_kya_pakayen/features/history/history_screen.dart';
import 'package:aaj_kya_pakayen/features/pantry/pantry_screen.dart';
import 'package:aaj_kya_pakayen/features/settings/settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/test_database.dart';

void main() {
  late AppDatabase db;

  setUp(() async {
    db = newTestDatabase();
    await DriftSettingsRepository(db)
        .save(const AppSettings(onboardingComplete: true));
  });
  tearDown(() => db.close());

  testWidgets('bottom navigation switches between all five tabs', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [appDatabaseProvider.overrideWithValue(db)],
        child: const App(),
      ),
    );
    await tester.pumpAndSettle();

    final bar = find.byType(NavigationBar);
    expect(bar, findsOneWidget);
    expect(find.descendant(of: bar, matching: find.text('آج')), findsOneWidget);

    await tester.tap(find.descendant(of: bar, matching: find.text('اسٹاک')));
    await tester.pumpAndSettle();
    expect(find.byType(PantryScreen), findsOneWidget);
    expect(find.text('گوشت کا اسٹاک'), findsOneWidget);

    // Five tabs leave room for one short Urdu word each (D-032).
    await tester.tap(find.descendant(of: bar, matching: find.text('ریکارڈ')));
    await tester.pumpAndSettle();
    expect(find.byType(HistoryScreen), findsOneWidget);

    await tester.tap(find.descendant(of: bar, matching: find.text('پکوان')));
    await tester.pumpAndSettle();
    expect(find.byType(DishesScreen), findsOneWidget);
    expect(find.text('ڈش تلاش کریں'), findsOneWidget);

    await tester.tap(find.descendant(of: bar, matching: find.text('ترتیبات')));
    await tester.pumpAndSettle();
    expect(find.byType(SettingsScreen), findsOneWidget);

    await tester.tap(find.descendant(of: bar, matching: find.text('آج')));
    await tester.pumpAndSettle();
    expect(find.text('آج کیا پکائیں؟'), findsOneWidget);

    // Let drift close its stream queries before the test ends.
    await tester.pumpWidget(const SizedBox());
    await tester.pump(Duration.zero);
  });
}
