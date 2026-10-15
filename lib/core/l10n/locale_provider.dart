import 'package:flutter/widgets.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'locale_provider.g.dart';

/// The app's display language. Urdu first; persisted via Settings later.
@Riverpod(keepAlive: true)
class AppLocale extends _$AppLocale {
  @override
  Locale build() => const Locale('ur');

  // Notifier methods are the Riverpod idiom for mutations.
  // ignore: use_setters_to_change_properties
  void set(Locale locale) => state = locale;
}
