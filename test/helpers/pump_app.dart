import 'package:aaj_kya_pakayen/core/l10n/generated/app_localizations.dart';
import 'package:aaj_kya_pakayen/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const urdu = Locale('ur');
const english = Locale('en');

extension PumpApp on WidgetTester {
  /// Pumps [widget] inside a themed, localized [MaterialApp].
  Future<void> pumpApp(Widget widget, {Locale locale = urdu}) {
    return pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        locale: locale,
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        theme: AppTheme.light(urdu: locale.languageCode == 'ur'),
        home: Scaffold(body: widget),
      ),
    );
  }
}
