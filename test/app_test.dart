import 'package:aaj_kya_pakayen/app.dart';
import 'package:aaj_kya_pakayen/core/theme/app_theme.dart';
import 'package:aaj_kya_pakayen/core/utils/clock.dart';
import 'package:aaj_kya_pakayen/core/widgets/app_logo.dart';
import 'package:aaj_kya_pakayen/data/db/app_database.dart';
import 'package:aaj_kya_pakayen/data/providers.dart';
import 'package:aaj_kya_pakayen/data/repositories_impl/drift_settings_repository.dart';
import 'package:aaj_kya_pakayen/data/seed/dish_seeder.dart';
import 'package:aaj_kya_pakayen/domain/entities/app_settings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/test_database.dart';

void main() {
  late AppDatabase db;
  late ProviderContainer container;

  setUp(() async {
    db = newTestDatabase();
    await DishSeeder(db).seedIfNeeded();
    // Past the first-run questions; onboarding has its own tests.
    await DriftSettingsRepository(db)
        .save(const AppSettings(onboardingComplete: true));
    container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        clockProvider.overrideWithValue(() => DateTime(2026, 10, 15, 18)),
      ],
    );
  });
  tearDown(() async {
    container.dispose();
    await db.close();
  });

  Future<void> pumpApp(WidgetTester tester) async {
    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const App()),
    );
    await tester.pumpAndSettle();
  }

  // Lets drift close its stream queries before the test ends.
  Future<void> unmount(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    await tester.pump(Duration.zero);
  }

  testWidgets('boots in Urdu, right-to-left, with the brand', (tester) async {
    await pumpApp(tester);

    final context = tester.element(find.byType(AppLogo));
    expect(Directionality.of(context), TextDirection.rtl);
    expect(Theme.of(context).textTheme.bodyLarge!.fontFamily, AppFonts.urdu);
    expect(find.text('آج کیا پکائیں؟'), findsOneWidget);
    expect(find.text('رات کا کھانا، طے!'), findsOneWidget);
    expect(find.text('سبزی کا دن'), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('follows the selected locale', (tester) async {
    await pumpApp(tester);
    await tester.runAsync(
      () => container
          .read(settingsRepositoryProvider)
          .save(
            const AppSettings(languageCode: 'en', onboardingComplete: true),
          ),
    );
    await tester.pumpAndSettle();

    final context = tester.element(find.byType(AppLogo));
    expect(Directionality.of(context), TextDirection.ltr);
    expect(find.text('Aaj Kya Pakayen'), findsOneWidget);
    expect(find.text('Dinner, decided.'), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('home screen golden (ur)', (tester) async {
    tester.view
      ..physicalSize = const Size(1080, 2340)
      ..devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.runAsync(() async {
      const loader = SvgAssetLoader(AppLogo.asset);
      await svg.cache.putIfAbsent(
        loader.cacheKey(null),
        () => loader.loadBytes(null),
      );
    });

    await pumpApp(tester);

    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/home_ur.png'),
    );
    await unmount(tester);
  });
}
