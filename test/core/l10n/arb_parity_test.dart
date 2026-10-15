import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> _readArb(String locale) {
  final file = File('lib/core/l10n/arb/app_$locale.arb');
  return jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
}

Set<String> _messageKeys(Map<String, dynamic> arb) =>
    arb.keys.where((k) => !k.startsWith('@')).toSet();

Set<String> _placeholders(String message) =>
    RegExp(r'\{(\w+)[,}]').allMatches(message).map((m) => m.group(1)!).toSet();

void main() {
  final en = _readArb('en');
  final ur = _readArb('ur');

  test('en and ur define exactly the same messages', () {
    expect(_messageKeys(ur), _messageKeys(en));
  });

  test('no message is empty', () {
    for (final arb in [en, ur]) {
      for (final key in _messageKeys(arb)) {
        expect((arb[key] as String).trim(), isNotEmpty, reason: key);
      }
    }
  });

  test('translations keep the same placeholders', () {
    for (final key in _messageKeys(en)) {
      expect(
        _placeholders(ur[key] as String),
        _placeholders(en[key] as String),
        reason: key,
      );
    }
  });

  test('every en message is documented with a description', () {
    for (final key in _messageKeys(en)) {
      final meta = en['@$key'] as Map<String, dynamic>?;
      expect(meta?['description'], isA<String>(), reason: key);
    }
  });
}
