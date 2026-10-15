import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Enforces the Clean Architecture dependency rule from docs/ARCHITECTURE.md.
void main() {
  List<File> dartFilesIn(String dir) =>
      Directory(dir)
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.dart'))
          .toList();

  final importPattern = RegExp(r'''^\s*(?:import|export)\s+['"]([^'"]+)['"]''');

  Iterable<String> importsOf(File file) => file
      .readAsLinesSync()
      .map(importPattern.firstMatch)
      .whereType<RegExpMatch>()
      .map((m) => m.group(1)!);

  test('domain is pure Dart and does not depend on data or features', () {
    const forbidden = [
      'package:flutter/',
      'package:flutter_riverpod/',
      'package:drift/',
      'package:aaj_kya_pakayen/data/',
      'package:aaj_kya_pakayen/features/',
      'package:aaj_kya_pakayen/core/',
      'dart:ui',
    ];
    final violations = <String>[
      for (final file in dartFilesIn('lib/domain'))
        for (final uri in importsOf(file))
          if (forbidden.any(uri.startsWith) || uri.contains('../'))
            '${file.path} -> $uri',
    ];
    expect(violations, isEmpty);
  });

  test('features never import data/db directly', () {
    final violations = <String>[
      for (final file in dartFilesIn('lib/features'))
        for (final uri in importsOf(file))
          if (uri.startsWith('package:aaj_kya_pakayen/data/db/') ||
              uri.startsWith('package:drift/'))
            '${file.path} -> $uri',
    ];
    expect(violations, isEmpty);
  });
}
