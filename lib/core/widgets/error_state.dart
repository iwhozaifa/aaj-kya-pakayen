import 'package:aaj_kya_pakayen/core/l10n/generated/app_localizations.dart';
import 'package:aaj_kya_pakayen/core/widgets/empty_state.dart';
import 'package:flutter/material.dart';

/// Shown when a screen's data could not load, with a way to retry.
class ErrorState extends StatelessWidget {
  const new({required this.onRetry, super.key});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Center(
      child: SingleChildScrollView(
        child: EmptyState(
          icon: Icons.error_outline,
          title: l10n.errorGeneric,
          actionLabel: l10n.tryAgain,
          onAction: onRetry,
        ),
      ),
    );
  }
}
