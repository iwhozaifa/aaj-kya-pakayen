import 'package:aaj_kya_pakayen/core/l10n/generated/app_localizations.dart';
import 'package:aaj_kya_pakayen/core/l10n/locale_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppLocalizations', () {
    test('supports Urdu and English', () {
      expect(
        AppLocalizations.supportedLocales,
        containsAll(const [Locale('ur'), Locale('en')]),
      );
    });

    test('has the bilingual name and tagline', () {
      final ur = lookupAppLocalizations(const Locale('ur'));
      final en = lookupAppLocalizations(const Locale('en'));
      expect(ur.appTitle, 'آج کیا پکائیں؟');
      expect(ur.tagline, 'رات کا کھانا، طے!');
      expect(en.appTitle, 'Aaj Kya Pakayen');
      expect(en.tagline, 'Dinner, decided.');
    });
  });

  group('appLocaleProvider', () {
    test('defaults to Urdu', () {
      final container = ProviderContainer.test();
      expect(container.read(appLocaleProvider), const Locale('ur'));
    });

    test('can switch to English', () {
      final container = ProviderContainer.test();
      container.read(appLocaleProvider.notifier).set(const Locale('en'));
      expect(container.read(appLocaleProvider), const Locale('en'));
    });
  });

  testWidgets('Urdu lays the app out right-to-left', (tester) async {
    late TextDirection direction;
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ur'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        home: Builder(
          builder: (context) {
            direction = Directionality.of(context);
            return const SizedBox.shrink();
          },
        ),
      ),
    );
    expect(direction, TextDirection.rtl);
  });
}
