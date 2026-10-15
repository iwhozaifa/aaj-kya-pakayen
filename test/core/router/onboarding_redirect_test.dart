import 'package:aaj_kya_pakayen/app.dart';
import 'package:aaj_kya_pakayen/core/startup/app_startup.dart';
import 'package:aaj_kya_pakayen/data/db/app_database.dart';
import 'package:aaj_kya_pakayen/data/providers.dart';
import 'package:aaj_kya_pakayen/domain/entities/app_settings.dart';
import 'package:aaj_kya_pakayen/features/onboarding/onboarding_screen.dart';
import 'package:aaj_kya_pakayen/features/today/today_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/test_database.dart';

void main() {
  late AppDatabase db;
  late ProviderContainer container;

  setUp(() {
    db = newTestDatabase();
    container = ProviderContainer(
      overrides: [appDatabaseProvider.overrideWithValue(db)],
    );
  });
  tearDown(() async {
    container.dispose();
    await db.close();
  });

  testWidgets('first run shows onboarding, then Today once it is done', (
    tester,
  ) async {
    await tester.runAsync(() => container.read(appStartupProvider.future));
    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const App()),
    );
    await tester.pumpAndSettle();

    expect(find.byType(OnboardingScreen), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);

    await tester.runAsync(
      () => container
          .read(settingsRepositoryProvider)
          .save(const AppSettings(onboardingComplete: true)),
    );
    await tester.pumpAndSettle();

    expect(find.byType(OnboardingScreen), findsNothing);
    expect(find.byType(TodayScreen), findsOneWidget);

    // Let drift close its stream queries before the test ends.
    await tester.pumpWidget(const SizedBox());
    await tester.pump(Duration.zero);
  });
}
