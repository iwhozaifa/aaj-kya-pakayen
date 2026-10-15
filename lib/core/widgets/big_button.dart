import 'package:aaj_kya_pakayen/core/theme/app_colors.dart';
import 'package:flutter/material.dart';

enum BigButtonTone { primary, veg, meat }

/// Full-width, extra-tall button for the main action on a screen.
class BigButton extends StatelessWidget {
  const new({
    required this.label,
    required this.onPressed,
    this.icon,
    this.tone = BigButtonTone.primary,
    super.key,
  });

  static const height = 64.0;

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final BigButtonTone tone;

  @override
  Widget build(BuildContext context) {
    final (background, foreground) = switch (tone) {
      BigButtonTone.primary => (AppColors.turmeric, AppColors.chaiBrown),
      BigButtonTone.veg => (AppColors.cardamom, AppColors.white),
      BigButtonTone.meat => (AppColors.chilli, AppColors.white),
    };
    final style = FilledButton.styleFrom(
      backgroundColor: background,
      foregroundColor: foreground,
      minimumSize: const Size.fromHeight(height),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
    );
    final text = Text(label, textAlign: TextAlign.center);
    return SizedBox(
      width: double.infinity,
      child: icon == null
          ? FilledButton(onPressed: onPressed, style: style, child: text)
          : FilledButton.icon(
              onPressed: onPressed,
              style: style,
              icon: Icon(icon, size: 28),
              label: text,
            ),
    );
  }
}
