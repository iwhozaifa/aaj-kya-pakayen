import 'package:aaj_kya_pakayen/data/providers.dart';
import 'package:flutter/widgets.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'locale_provider.g.dart';

/// The app's display language, from the saved settings. Urdu first.
@Riverpod(keepAlive: true)
Locale appLocale(Ref ref) =>
    Locale(ref.watch(appSettingsProvider).value?.languageCode ?? 'ur');
