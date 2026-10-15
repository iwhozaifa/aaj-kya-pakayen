import 'package:aaj_kya_pakayen/core/theme/app_colors.dart';
import 'package:flutter/material.dart';

/// Bundled font families (see pubspec.yaml).
abstract final class AppFonts {
  static const heading = 'Poppins';
  static const body = 'Nunito';
  static const urdu = 'NotoNastaliqUrdu';
}

/// Light Material 3 theme. Urdu swaps every style to Nastaliq with a taller
/// line height; English uses Poppins headings and Nunito body text.
abstract final class AppTheme {
  /// Smallest text size anywhere in the app.
  static const minFontSize = 18.0;

  /// Minimum height of every button.
  static const minTouchTarget = 56.0;

  static const cardRadius = 20.0;

  static ThemeData light({required bool urdu}) {
    final colorScheme =
        ColorScheme.fromSeed(
          seedColor: AppColors.turmeric,
          surface: AppColors.cream,
        ).copyWith(
          primary: AppColors.turmeric,
          onPrimary: AppColors.chaiBrown,
          primaryContainer: AppColors.saffronTint,
          onPrimaryContainer: AppColors.chaiBrown,
          secondary: AppColors.cardamom,
          onSecondary: AppColors.white,
          tertiary: AppColors.chilli,
          onTertiary: AppColors.white,
          error: AppColors.chilli,
          onError: AppColors.white,
          surface: AppColors.cream,
          onSurface: AppColors.chaiBrown,
        );

    final textTheme = _textTheme(urdu: urdu);
    const buttonMinimumSize = WidgetStatePropertyAll(Size(64, minTouchTarget));
    final buttonTextStyle = WidgetStatePropertyAll(textTheme.titleMedium);
    // Turmeric text on cream is unreadable: outlined and text buttons use
    // chai brown (turmeric stays for borders and filled buttons).
    final secondaryForeground = WidgetStateProperty.resolveWith(
      (states) => states.contains(WidgetState.disabled)
          ? AppColors.chaiBrown.withValues(alpha: 0.38)
          : AppColors.chaiBrown,
    );
    const secondaryIconSize = WidgetStatePropertyAll<double>(24);
    const buttonShape = WidgetStatePropertyAll(
      RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(16)),
      ),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.cream,
      textTheme: textTheme,
      materialTapTargetSize: MaterialTapTargetSize.padded,
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.cream,
        foregroundColor: AppColors.chaiBrown,
        centerTitle: true,
        titleTextStyle: textTheme.titleLarge,
      ),
      cardTheme: const CardThemeData(
        color: AppColors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          side: BorderSide(color: AppColors.saffronTint, width: 2),
          borderRadius: BorderRadius.all(Radius.circular(cardRadius)),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: ButtonStyle(
          minimumSize: buttonMinimumSize,
          textStyle: buttonTextStyle,
          shape: buttonShape,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: ButtonStyle(
          minimumSize: buttonMinimumSize,
          textStyle: buttonTextStyle,
          shape: buttonShape,
          foregroundColor: secondaryForeground,
          iconSize: secondaryIconSize,
          side: const WidgetStatePropertyAll(
            BorderSide(color: AppColors.turmeric, width: 2),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: ButtonStyle(
          minimumSize: buttonMinimumSize,
          textStyle: buttonTextStyle,
          foregroundColor: secondaryForeground,
          iconSize: secondaryIconSize,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.chaiBrown,
        contentTextStyle: textTheme.bodyLarge?.copyWith(color: AppColors.cream),
        actionTextColor: AppColors.turmeric,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  static TextTheme _textTheme({required bool urdu}) {
    TextStyle style(double size, FontWeight weight, {bool heading = false}) {
      return TextStyle(
        fontFamily: urdu
            ? AppFonts.urdu
            : (heading ? AppFonts.heading : AppFonts.body),
        // Notes and names can mix scripts; Nastaliq has no Latin glyphs and
        // the Latin fonts have no Urdu ones.
        fontFamilyFallback: urdu
            ? const [AppFonts.body]
            : const [AppFonts.urdu],
        fontSize: size,
        fontWeight: weight,
        height: urdu ? 1.9 : 1.3,
        color: AppColors.chaiBrown,
      );
    }

    return TextTheme(
      displayLarge: style(40, FontWeight.w700, heading: true),
      displayMedium: style(36, FontWeight.w700, heading: true),
      displaySmall: style(32, FontWeight.w700, heading: true),
      headlineLarge: style(30, FontWeight.w700, heading: true),
      headlineMedium: style(28, FontWeight.w600, heading: true),
      headlineSmall: style(24, FontWeight.w600, heading: true),
      titleLarge: style(24, FontWeight.w600, heading: true),
      titleMedium: style(22, FontWeight.w600, heading: true),
      titleSmall: style(20, FontWeight.w600, heading: true),
      bodyLarge: style(20, FontWeight.w400),
      bodyMedium: style(minFontSize, FontWeight.w400),
      bodySmall: style(minFontSize, FontWeight.w400),
      labelLarge: style(20, FontWeight.w600),
      labelMedium: style(minFontSize, FontWeight.w600),
      labelSmall: style(minFontSize, FontWeight.w600),
    );
  }
}
