import 'package:aaj_kya_pakayen/core/l10n/generated/app_localizations.dart';
import 'package:aaj_kya_pakayen/core/l10n/labels.dart';
import 'package:aaj_kya_pakayen/core/widgets/app_logo.dart';
import 'package:aaj_kya_pakayen/core/widgets/empty_state.dart';
import 'package:aaj_kya_pakayen/core/widgets/undo_snack_bar.dart';
import 'package:aaj_kya_pakayen/domain/engine/suggestion_engine.dart';
import 'package:aaj_kya_pakayen/features/today/outside_note_dialog.dart';
import 'package:aaj_kya_pakayen/features/today/today_controller.dart';
import 'package:aaj_kya_pakayen/features/today/today_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Home: tonight's type, the best suggestion and what to do about it.
class TodayScreen extends ConsumerWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(todayStateProvider);
    final actions = ref.watch(todayActionsProvider);

    Future<void> cook(HomeSuggestion s, SuggestionResult result) async {
      final id = await actions.cook(s, result.dayType);
      if (!context.mounted) return;
      showUndoSnackBar(
        context,
        message: l10n.todayLogged(l10n.dishName(s.main)),
        onUndo: () => actions.undo(id),
      );
    }

    Future<void> orderOutside() async {
      final note = await showOutsideNoteDialog(context);
      if (note == null) return;
      final id = await actions.orderOutside(note);
      if (!context.mounted) return;
      showUndoSnackBar(
        context,
        message: l10n.todayOutsideLogged,
        onUndo: () => actions.undo(id),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const AppLogo(size: 36),
            const SizedBox(width: 8),
            Flexible(child: Text(l10n.appTitle)),
          ],
        ),
      ),
      body: switch (state) {
        AsyncData(:final value) => ListView(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          children: [
            Text(
              l10n.tagline,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 8),
            DayBadge(
              dayType: value.result.dayType,
              swapped: value.result.isOverride,
            ),
            const SizedBox(height: 12),
            ..._content(
              context,
              value,
              cook: (s) => cook(s, value.result),
              orderOutside: orderOutside,
              actions: actions,
            ),
          ],
        ),
        AsyncError() => Center(
          child: EmptyState(
            icon: Icons.error_outline,
            title: l10n.errorGeneric,
          ),
        ),
        _ => const Center(child: CircularProgressIndicator()),
      },
    );
  }

  List<Widget> _content(
    BuildContext context,
    TodayState state, {
    required void Function(HomeSuggestion) cook,
    required VoidCallback orderOutside,
    required TodayActions actions,
  }) {
    final l10n = AppLocalizations.of(context);
    final result = state.result;
    final tonight = state.tonight;
    if (tonight != null) {
      return [
        LoggedCard(state: state, onChange: () => actions.undo(tonight.id!)),
      ];
    }

    final homes = result.suggestions.whereType<HomeSuggestion>().toList();
    final outside = result.suggestions.whereType<OutsideSuggestion>();
    final swap = OutlinedButton.icon(
      onPressed: () => actions.swapDayType(result),
      icon: const Icon(Icons.swap_horiz),
      label: Text(l10n.todaySwap),
    );

    return [
      if (homes.isNotEmpty)
        SuggestionCard(suggestion: homes.first, onCook: () => cook(homes.first))
      else if (outside.isNotEmpty)
        OutsideCard(suggestion: outside.first, onOrder: orderOutside)
      else
        EmptyState(
          icon: Icons.no_meals,
          title: l10n.todayNoIdeas,
          message: l10n.todayNoIdeasHint,
        ),
      const SizedBox(height: 12),
      if (homes.isNotEmpty) ...[
        OutlinedButton.icon(
          onPressed: actions.showAnother,
          icon: const Icon(Icons.refresh),
          label: Text(l10n.todayAnother),
        ),
        const SizedBox(height: 8),
        if (result.canOrderOutside) ...[
          OutlinedButton.icon(
            onPressed: orderOutside,
            icon: const Icon(Icons.delivery_dining),
            label: Text(l10n.todayOutside),
          ),
          const SizedBox(height: 8),
        ],
      ],
      swap,
      if (homes.length > 1) ...[
        const SizedBox(height: 24),
        Text(
          l10n.todayOtherIdeas,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        for (final s in homes.skip(1))
          OtherIdeaTile(suggestion: s, onCook: () => cook(s)),
      ],
    ];
  }
}
