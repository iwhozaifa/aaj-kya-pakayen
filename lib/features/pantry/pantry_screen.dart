import 'package:aaj_kya_pakayen/core/l10n/generated/app_localizations.dart';
import 'package:aaj_kya_pakayen/core/l10n/labels.dart';
import 'package:aaj_kya_pakayen/core/utils/clock.dart';
import 'package:aaj_kya_pakayen/core/widgets/big_button.dart';
import 'package:aaj_kya_pakayen/core/widgets/error_state.dart';
import 'package:aaj_kya_pakayen/core/widgets/undo_snack_bar.dart';
import 'package:aaj_kya_pakayen/domain/entities/calendar_date.dart';
import 'package:aaj_kya_pakayen/domain/enums/protein_type.dart';
import 'package:aaj_kya_pakayen/features/pantry/add_purchase_sheet.dart';
import 'package:aaj_kya_pakayen/features/pantry/pantry_controller.dart';
import 'package:aaj_kya_pakayen/features/pantry/protein_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class PantryScreen extends ConsumerWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final summary = ref.watch(pantrySummaryProvider);
    final actions = ref.watch(pantryActionsProvider);

    Future<void> increase(ProteinType p) async {
      final undo = await actions.increase(p);
      if (!context.mounted) return;
      showUndoSnackBar(
        context,
        message: l10n.pantryAdded(
          l10n.grams(PantryActions.quickStepGrams),
          l10n.protein(p),
        ),
        onUndo: () => actions.undo(undo),
      );
    }

    Future<void> decrease(ProteinType p) async {
      final undo = await actions.decrease(p);
      if (undo == null || !context.mounted) return;
      showUndoSnackBar(
        context,
        message: l10n.pantryReduced(l10n.protein(p)),
        onUndo: () => actions.undo(undo),
      );
    }

    Future<void> addPurchase() async {
      final purchase = await showAddPurchaseSheet(
        context,
        today: ref.read(clockProvider)().dateOnly,
      );
      if (purchase == null) return;
      final undo = await actions.addPurchase(
        purchase.protein,
        purchase.grams,
        boughtOn: purchase.boughtOn,
      );
      if (!context.mounted) return;
      showUndoSnackBar(
        context,
        message: l10n.pantryAdded(
          l10n.grams(purchase.grams),
          l10n.protein(purchase.protein),
        ),
        onUndo: () => actions.undo(undo),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(l10n.pantryTitle)),
      body: switch (summary) {
        AsyncData(:final value) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            for (final stock in value)
              ProteinTile(
                stock: stock,
                onIncrease: () => increase(stock.protein),
                onDecrease: () => decrease(stock.protein),
              ),
            const SizedBox(height: 8),
            Text(
              l10n.pantryHint(l10n.grams(PantryActions.quickStepGrams)),
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
        AsyncError() => ErrorState(
          onRetry: () => ref.invalidate(pantrySummaryProvider),
        ),
        _ => const Center(child: CircularProgressIndicator()),
      },
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: BigButton(
            label: l10n.pantryAddPurchase,
            icon: Icons.add_shopping_cart,
            onPressed: summary.hasValue ? addPurchase : null,
          ),
        ),
      ),
    );
  }
}
