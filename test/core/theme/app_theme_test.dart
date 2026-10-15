import 'package:aaj_kya_pakayen/core/theme/app_colors.dart';
import 'package:aaj_kya_pakayen/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppColors', () {
    test('match the brand palette', () {
      expect(AppColors.turmeric, const Color(0xFFF2A900));
      expect(AppColors.cardamom, const Color(0xFF3E6B48));
      expect(AppColors.chilli, const Color(0xFFC0392B));
      expect(AppColors.cream, const Color(0xFFFFF8EC));
      expect(AppColors.chaiBrown, const Color(0xFF2B2118));
      expect(AppColors.saffronTint, const Color(0xFFFFE2A8));
    });
  });

  group('AppTheme', () {
    for (final urdu in [true, false]) {
      group(urdu ? 'urdu' : 'english', () {
        final theme = AppTheme.light(urdu: urdu);

        test('uses Material 3 with the brand colours', () {
          expect(theme.useMaterial3, isTrue);
          expect(theme.colorScheme.primary, AppColors.turmeric);
          expect(theme.colorScheme.onPrimary, AppColors.chaiBrown);
          expect(theme.colorScheme.secondary, AppColors.cardamom);
          expect(theme.colorScheme.tertiary, AppColors.chilli);
          expect(theme.colorScheme.surface, AppColors.cream);
          expect(theme.colorScheme.onSurface, AppColors.chaiBrown);
          expect(theme.scaffoldBackgroundColor, AppColors.cream);
        });

        test('never renders text smaller than 18sp', () {
          final styles = <String, TextStyle?>{
            'displayLarge': theme.textTheme.displayLarge,
            'displayMedium': theme.textTheme.displayMedium,
            'displaySmall': theme.textTheme.displaySmall,
            'headlineLarge': theme.textTheme.headlineLarge,
            'headlineMedium': theme.textTheme.headlineMedium,
            'headlineSmall': theme.textTheme.headlineSmall,
            'titleLarge': theme.textTheme.titleLarge,
            'titleMedium': theme.textTheme.titleMedium,
            'titleSmall': theme.textTheme.titleSmall,
            'bodyLarge': theme.textTheme.bodyLarge,
            'bodyMedium': theme.textTheme.bodyMedium,
            'bodySmall': theme.textTheme.bodySmall,
            'labelLarge': theme.textTheme.labelLarge,
            'labelMedium': theme.textTheme.labelMedium,
            'labelSmall': theme.textTheme.labelSmall,
          };
          for (final MapEntry(key: name, value: style) in styles.entries) {
            expect(style?.fontSize, greaterThanOrEqualTo(18), reason: name);
          }
        });

        test('keeps touch targets at least 48dp', () {
          expect(theme.materialTapTargetSize, MaterialTapTargetSize.padded);
          final buttonStyles = [
            theme.filledButtonTheme.style,
            theme.outlinedButtonTheme.style,
            theme.textButtonTheme.style,
          ];
          for (final style in buttonStyles) {
            final size = style?.minimumSize?.resolve(<WidgetState>{});
            expect(size?.height, greaterThanOrEqualTo(48));
          }
        });
      });
    }

    test('uses Nastaliq with tall line height for Urdu', () {
      final body = AppTheme.light(urdu: true).textTheme.bodyLarge!;
      expect(body.fontFamily, AppFonts.urdu);
      expect(body.height, greaterThanOrEqualTo(1.8));
    });

    test('uses Poppins headings and Nunito body for English', () {
      final theme = AppTheme.light(urdu: false);
      expect(theme.textTheme.headlineMedium!.fontFamily, AppFonts.heading);
      expect(theme.textTheme.bodyLarge!.fontFamily, AppFonts.body);
    });
  });
}
