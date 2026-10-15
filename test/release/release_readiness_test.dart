import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Checks that keep a release honest: the version is documented, no stray
/// TODOs ship, and signing secrets can never be committed.
void main() {
  final version = RegExp(
    r'^version:\s*(\d+\.\d+\.\d+)\+(\d+)\s*$',
    multiLine: true,
  ).firstMatch(File('pubspec.yaml').readAsStringSync());

  test('pubspec has a semantic version and build number', () {
    expect(version, isNotNull);
  });

  test('the changelog has a dated entry for the current version', () {
    final changelog = File('CHANGELOG.md');
    expect(changelog.existsSync(), isTrue, reason: 'CHANGELOG.md is missing');
    expect(
      changelog.readAsStringSync(),
      matches(
        RegExp(
          '^## \\[${RegExp.escape(version!.group(1)!)}\\] - '
          r'\d{4}-\d{2}-\d{2}$',
          multiLine: true,
        ),
      ),
    );
  });

  test('no TODO or FIXME ships without an issue link', () {
    final roots = ['lib', 'test', 'android/app', 'scripts', '.github'];
    final todo = RegExp(r'\b(TODO|FIXME)\b');
    final linked = RegExp(r'(TODO|FIXME)\(#\d+\)');
    final offenders = <String>[];
    for (final root in roots) {
      final dir = Directory(root);
      if (!dir.existsSync()) continue;
      for (final file in dir.listSync(recursive: true).whereType<File>()) {
        final path = file.path;
        if (path.contains('/build/') ||
            path.contains('/generated/') ||
            path.endsWith('.g.dart') ||
            path.endsWith('.freezed.dart') ||
            !RegExp(r'\.(dart|kts|kt|xml|ya?ml|sh)$').hasMatch(path)) {
          continue;
        }
        final lines = file.readAsLinesSync();
        for (final (i, line) in lines.indexed) {
          // This file talks about TODOs; it doesn't contain any.
          if (path.endsWith('release_readiness_test.dart')) break;
          if (todo.hasMatch(line) && !linked.hasMatch(line)) {
            offenders.add('$path:${i + 1}');
          }
        }
      }
    }
    expect(offenders, isEmpty);
  });

  test('signing secrets are git-ignored', () {
    final ignored = File('.gitignore').readAsLinesSync();
    for (final pattern in ['android/key.properties', '*.jks', '*.keystore']) {
      expect(ignored, contains(pattern));
    }
  });

  test('release builds sign with the upload key when one is provided', () {
    final gradle = File('android/app/build.gradle.kts').readAsStringSync();
    expect(gradle, contains('key.properties'));
    expect(gradle, contains('signingConfigs'));
    expect(gradle, contains('create("release")'));
  });
}
