import 'package:aaj_kya_pakayen/core/widgets/section_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/pump_app.dart';

void main() {
  testWidgets('shows an optional title above its child', (tester) async {
    await tester.pumpApp(
      const SectionCard(title: 'Freezer', child: Text('2 kg chicken')),
      locale: english,
    );

    expect(find.text('Freezer'), findsOneWidget);
    expect(find.text('2 kg chicken'), findsOneWidget);
    expect(find.byType(Card), findsOneWidget);
    expect(
      tester.getTopLeft(find.text('Freezer')).dy,
      lessThan(tester.getTopLeft(find.text('2 kg chicken')).dy),
    );
  });

  testWidgets('works without a title', (tester) async {
    await tester.pumpApp(const SectionCard(child: Text('body')));

    expect(find.text('body'), findsOneWidget);
  });
}
