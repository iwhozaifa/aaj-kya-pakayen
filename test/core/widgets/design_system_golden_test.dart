import 'package:aaj_kya_pakayen/core/widgets/big_button.dart';
import 'package:aaj_kya_pakayen/core/widgets/empty_state.dart';
import 'package:aaj_kya_pakayen/core/widgets/section_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/pump_app.dart';

class _Showcase extends StatelessWidget {
  const new({required this.urdu});

  final bool urdu;

  @override
  Widget build(BuildContext context) {
    String t(String en, String ur) => urdu ? ur : en;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        BigButton(
          label: t('Cook this', 'یہی پکائیں'),
          icon: Icons.check,
          onPressed: () {},
        ),
        const SizedBox(height: 12),
        BigButton(
          label: t('Veg day', 'سبزی کا دن'),
          icon: Icons.eco,
          tone: BigButtonTone.veg,
          onPressed: () {},
        ),
        const SizedBox(height: 12),
        BigButton(
          label: t('Meat day', 'گوشت کا دن'),
          icon: Icons.restaurant,
          tone: BigButtonTone.meat,
          onPressed: () {},
        ),
        const SizedBox(height: 12),
        SectionCard(
          title: t('Freezer', 'فریزر'),
          child: Text(t('Chicken · 2 kg', 'مرغی · ۲ کلو')),
        ),
        EmptyState(
          icon: Icons.kitchen,
          title: t('No stock yet', 'ابھی کوئی اسٹاک نہیں'),
          message: t(
            'Add the meat in your freezer.',
            'فریزر کا گوشت درج کریں۔',
          ),
        ),
      ],
    );
  }
}

void main() {
  for (final locale in [urdu, english]) {
    testWidgets('design system showcase (${locale.languageCode})', (
      tester,
    ) async {
      tester.view
        ..physicalSize = const Size(1080, 2340)
        ..devicePixelRatio = 3;
      addTearDown(tester.view.reset);

      await tester.pumpApp(_Showcase(urdu: locale == urdu), locale: locale);

      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('goldens/design_system_${locale.languageCode}.png'),
      );
    });
  }
}
