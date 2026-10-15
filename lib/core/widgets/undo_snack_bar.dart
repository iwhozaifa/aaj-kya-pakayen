import 'package:aaj_kya_pakayen/core/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';

/// Confirms a change and offers to reverse it. Shown after every log action.
void showUndoSnackBar(
  BuildContext context, {
  required String message,
  required VoidCallback onUndo,
}) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 6),
        action: SnackBarAction(
          label: AppLocalizations.of(context).undo,
          onPressed: onUndo,
        ),
      ),
    );
}
