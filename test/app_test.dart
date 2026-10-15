import 'package:aaj_kya_pakayen/app.dart';
import 'package:aaj_kya_pakayen/core/l10n/locale_provider.dart';
import 'package:aaj_kya_pakayen/core/theme/app_theme.dart';
import 'package:aaj_kya_pakayen/core/widgets/app_logo.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('boots in Urdu, right-to-left, with the brand', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: App()));
    await tester.pumpAndSettle();

    final context = tester.element(find.byType(AppLogo));
    expect(Directionality.of(context), TextDirection.rtl);
    expect(Theme.of(context).textTheme.bodyLarge!.fontFamily, AppFonts.urdu);
    expect(find.text('آج کیا پکائیں؟'), findsOneWidget);
    expect(find.text('رات کا کھانا، طے!'), findsOneWidget);
  });

  testWidgets('follows the selected locale', (tester) async {
    final container = ProviderContainer.test();
    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const App()),
    );
    container.read(appLocaleProvider.notifier).set(const Locale('en'));
    await tester.pumpAndSettle();

    final context = tester.element(find.byType(AppLogo));
    expect(Directionality.of(context), TextDirection.ltr);
    expect(find.text('Aaj Kya Pakayen'), findsOneWidget);
    expect(find.text('Dinner, decided.'), findsOneWidget);
  });

  testWidgets('home screen golden (ur)', (tester) async {
    tester.view
      ..physicalSize = const Size(1080, 2340)
      ..devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const ProviderScope(child: App()));
    await tester.runAsync(() async {
      const loader = SvgAssetLoader(AppLogo.asset);
      await svg.cache.putIfAbsent(
        loader.cacheKey(null),
        () => loader.loadBytes(null),
      );
    });
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/home_ur.png'),
    );
  });
}
