import 'package:aaj_kya_pakayen/core/theme/app_colors.dart';
import 'package:flutter/material.dart';

/// Friendly placeholder for lists and screens with nothing to show yet.
class EmptyState extends StatelessWidget {
  const new({
    required this.icon,
    required this.title,
    this.message,
    this.actionLabel,
    this.onAction,
    super.key,
  });

  final IconData icon;
  final String title;
  final String? message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 72, color: AppColors.cardamom),
          const SizedBox(height: 16),
          Text(title, style: textTheme.titleLarge, textAlign: TextAlign.center),
          if (message case final message?) ...[
            const SizedBox(height: 8),
            Text(
              message,
              style: textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
          ],
          if ((actionLabel, onAction) case (final label?, final onAction?)) ...[
            const SizedBox(height: 24),
            FilledButton(onPressed: onAction, child: Text(label)),
          ],
        ],
      ),
    );
  }
}
