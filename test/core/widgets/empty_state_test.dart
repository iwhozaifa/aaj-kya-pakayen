import 'package:aaj_kya_pakayen/core/widgets/empty_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/pump_app.dart';

void main() {
  testWidgets('shows icon, title, message and action', (tester) async {
    var tapped = false;
    await tester.pumpApp(
      EmptyState(
        icon: Icons.kitchen,
        title: 'No stock yet',
        message: 'Add the meat in your freezer.',
        actionLabel: 'Add stock',
        onAction: () => tapped = true,
      ),
      locale: english,
    );

    expect(find.byIcon(Icons.kitchen), findsOneWidget);
    expect(find.text('No stock yet'), findsOneWidget);
    expect(find.text('Add the meat in your freezer.'), findsOneWidget);
    await tester.tap(find.text('Add stock'));
    expect(tapped, isTrue);
  });

  testWidgets('hides the action when none is given', (tester) async {
    await tester.pumpApp(
      const EmptyState(icon: Icons.history, title: 'Nothing yet'),
    );

    expect(find.byType(FilledButton), findsNothing);
  });
}
