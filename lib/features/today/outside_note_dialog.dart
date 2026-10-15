import 'package:aaj_kya_pakayen/core/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';

/// Asks for an optional note ("biryani from …"). Null when cancelled.
Future<String?> showOutsideNoteDialog(BuildContext context) =>
    showDialog<String>(
      context: context,
      builder: (_) => const _OutsideNoteDialog(),
    );

class _OutsideNoteDialog extends StatefulWidget {
  const new();

  @override
  State<_OutsideNoteDialog> createState() => _OutsideNoteDialogState();
}

class _OutsideNoteDialogState extends State<_OutsideNoteDialog> {
  final _note = TextEditingController();

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(l10n.todayOutside),
      content: TextField(
        controller: _note,
        autofocus: true,
        textCapitalization: TextCapitalization.sentences,
        decoration: InputDecoration(
          labelText: l10n.outsideNoteLabel,
          hintText: l10n.outsideNoteHint,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_note.text),
          child: Text(l10n.save),
        ),
      ],
    );
  }
}
