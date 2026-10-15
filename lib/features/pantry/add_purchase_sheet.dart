import 'package:aaj_kya_pakayen/core/l10n/generated/app_localizations.dart';
import 'package:aaj_kya_pakayen/core/l10n/labels.dart';
import 'package:aaj_kya_pakayen/core/widgets/big_button.dart';
import 'package:aaj_kya_pakayen/domain/enums/protein_type.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

typedef Purchase = ({ProteinType protein, int grams, DateTime boughtOn});

/// Bottom sheet: what was bought, how much and when. Pops a [Purchase].
Future<Purchase?> showAddPurchaseSheet(
  BuildContext context, {
  required DateTime today,
}) => showModalBottomSheet<Purchase>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  showDragHandle: true,
  builder: (_) => AddPurchaseSheet(today: today),
);

class AddPurchaseSheet extends StatefulWidget {
  const new({required this.today, super.key});

  final DateTime today;

  static const amounts = [500, 1000, 1500, 2000, 3000];

  @override
  State<AddPurchaseSheet> createState() => _AddPurchaseSheetState();
}

class _AddPurchaseSheetState extends State<AddPurchaseSheet> {
  ProteinType _protein = ProteinType.chicken;
  int _grams = 1000;
  late DateTime _boughtOn = widget.today;

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _boughtOn,
      firstDate: widget.today.subtract(const Duration(days: 90)),
      lastDate: widget.today,
    );
    if (picked != null) setState(() => _boughtOn = picked);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;
    final date = DateFormat.yMMMMd(l10n.localeName).format(_boughtOn);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(l10n.purchaseWhat, style: textTheme.titleLarge),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final p in ProteinType.values)
                ChoiceChip(
                  label: Text(l10n.protein(p)),
                  selected: p == _protein,
                  onSelected: (_) => setState(() => _protein = p),
                ),
            ],
          ),
          const SizedBox(height: 24),
          Text(l10n.purchaseHowMuch, style: textTheme.titleLarge),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final g in AddPurchaseSheet.amounts)
                ChoiceChip(
                  label: Text(l10n.grams(g)),
                  selected: g == _grams,
                  onSelected: (_) => setState(() => _grams = g),
                ),
            ],
          ),
          const SizedBox(height: 24),
          Text(l10n.purchaseWhen(date), style: textTheme.titleMedium),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: TextButton.icon(
              onPressed: _pickDate,
              icon: const Icon(Icons.calendar_today),
              label: Text(l10n.purchaseChangeDate),
            ),
          ),
          const SizedBox(height: 16),
          BigButton(
            label: l10n.save,
            icon: Icons.check,
            onPressed: () => Navigator.of(context)
                .pop((protein: _protein, grams: _grams, boughtOn: _boughtOn)),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.cancel),
          ),
        ],
      ),
    );
  }
}
