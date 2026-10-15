import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Loads the bundled fonts so golden files show real glyphs instead of the
/// Ahem test font.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  TestWidgetsFlutterBinding.ensureInitialized();
  const families = {
    'Poppins': [
      'assets/fonts/Poppins-Regular.ttf',
      'assets/fonts/Poppins-SemiBold.ttf',
      'assets/fonts/Poppins-Bold.ttf',
    ],
    'Nunito': ['assets/fonts/Nunito-Variable.ttf'],
    'NotoNastaliqUrdu': [
      'assets/fonts/NotoNastaliqUrdu-Regular.ttf',
      'assets/fonts/NotoNastaliqUrdu-Bold.ttf',
    ],
    'MaterialIcons': ['fonts/MaterialIcons-Regular.otf'],
  };
  for (final MapEntry(key: family, value: assets) in families.entries) {
    final loader = FontLoader(family);
    for (final asset in assets) {
      loader.addFont(rootBundle.load(asset));
    }
    await loader.load();
  }
  await testMain();
}
