import 'package:aaj_kya_pakayen/core/widgets/undo_snack_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/pump_app.dart';

void main() {
  for (final (locale, undoLabel) in [(english, 'Undo'), (urdu, 'واپس کریں')]) {
    testWidgets('shows a localized undo action ($locale)', (tester) async {
      var undone = 0;
      await tester.pumpApp(
        Builder(
          builder: (context) => TextButton(
            onPressed: () => showUndoSnackBar(
              context,
              message: 'Logged',
              onUndo: () => undone++,
            ),
            child: const Text('log'),
          ),
        ),
        locale: locale,
      );

      await tester.tap(find.text('log'));
      await tester.pumpAndSettle();
      expect(find.text('Logged'), findsOneWidget);

      await tester.tap(find.text(undoLabel));
      await tester.pumpAndSettle();
      expect(undone, 1);
    });
  }
}
