import 'package:aaj_kya_pakayen/core/l10n/generated/app_localizations.dart';
import 'package:aaj_kya_pakayen/core/l10n/labels.dart';
import 'package:aaj_kya_pakayen/core/theme/app_colors.dart';
import 'package:aaj_kya_pakayen/domain/usecases/summarize_pantry.dart';
import 'package:aaj_kya_pakayen/features/pantry/pantry_controller.dart';
import 'package:flutter/material.dart';

/// One protein: amount, age of the oldest batch, low-stock badge, − and +.
class ProteinTile extends StatelessWidget {
  const new({
    required this.stock,
    required this.onIncrease,
    required this.onDecrease,
    super.key,
  });

  final ProteinStock stock;
  final VoidCallback onIncrease;
  final VoidCallback onDecrease;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;
    final name = l10n.protein(stock.protein);
    final step = l10n.grams(PantryActions.quickStepGrams);
    final oldestDays = stock.oldestDays;
    const buttonSize = Size.square(56);

    final info = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(name, style: textTheme.titleLarge),
            if (stock.isLow) _LowBadge(label: l10n.pantryLow),
          ],
        ),
        Text(
          stock.grams == 0 ? l10n.pantryNone : l10n.grams(stock.grams),
          style: stock.grams == 0
              ? textTheme.titleMedium
              : textTheme.headlineMedium,
        ),
        if (oldestDays != null)
          Text(l10n.pantryOldest(oldestDays), style: textTheme.bodyMedium),
      ],
    );
    final buttons = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton.filledTonal(
          tooltip: l10n.pantryDecrease(step, name),
          style: IconButton.styleFrom(minimumSize: buttonSize),
          onPressed: stock.grams == 0 ? null : onDecrease,
          icon: const Icon(Icons.remove, size: 28),
        ),
        const SizedBox(width: 8),
        IconButton.filled(
          tooltip: l10n.pantryIncrease(step, name),
          style: IconButton.styleFrom(minimumSize: buttonSize),
          onPressed: onIncrease,
          icon: const Icon(Icons.add, size: 28),
        ),
      ],
    );
    // With large text the buttons move below, so names keep their width.
    final largeText = MediaQuery.textScalerOf(context).scale(10) > 13;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: largeText
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  info,
                  const SizedBox(height: 8),
                  Align(
                    alignment: AlignmentDirectional.centerEnd,
                    child: buttons,
                  ),
                ],
              )
            : Row(
                children: [
                  Expanded(child: info),
                  buttons,
                ],
              ),
      ),
    );
  }
}

class _LowBadge extends StatelessWidget {
  const new({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.chilli,
        borderRadius: BorderRadius.all(Radius.circular(12)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelMedium
              ?.copyWith(color: AppColors.white),
        ),
      ),
    );
  }
}
