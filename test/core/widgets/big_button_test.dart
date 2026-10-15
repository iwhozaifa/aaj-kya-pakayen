import 'package:aaj_kya_pakayen/core/theme/app_theme.dart';
import 'package:aaj_kya_pakayen/core/widgets/big_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/pump_app.dart';

void main() {
  testWidgets('shows the label and reacts to taps', (tester) async {
    var taps = 0;
    await tester.pumpApp(
      BigButton(label: 'Cook this', icon: Icons.check, onPressed: () => taps++),
      locale: english,
    );

    await tester.tap(find.text('Cook this'));
    expect(taps, 1);
    expect(find.byIcon(Icons.check), findsOneWidget);
  });

  testWidgets('is full width and at least the minimum touch height', (
    tester,
  ) async {
    await tester.pumpApp(BigButton(label: 'Go', onPressed: () {}));

    final size = tester.getSize(find.byType(BigButton));
    expect(size.height, greaterThanOrEqualTo(AppTheme.minTouchTarget));
    expect(
      size.width,
      tester.view.physicalSize.width / tester.view.devicePixelRatio,
    );
  });

  testWidgets('is disabled without a callback', (tester) async {
    await tester.pumpApp(const BigButton(label: 'Go', onPressed: null));

    final button = tester.widget<ButtonStyleButton>(
      find.byWidgetPredicate((w) => w is ButtonStyleButton),
    );
    expect(button.enabled, isFalse);
  });

  for (final tone in BigButtonTone.values) {
    testWidgets('$tone meets tap target and contrast guidelines', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await tester.pumpApp(
        BigButton(label: 'Go', tone: tone, onPressed: () {}),
        locale: english,
      );

      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      await expectLater(tester, meetsGuideline(textContrastGuideline));
      handle.dispose();
    });
  }
}
