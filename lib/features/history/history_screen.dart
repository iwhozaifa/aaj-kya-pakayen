import 'package:aaj_kya_pakayen/core/l10n/generated/app_localizations.dart';
import 'package:aaj_kya_pakayen/core/l10n/labels.dart';
import 'package:aaj_kya_pakayen/core/theme/app_colors.dart';
import 'package:aaj_kya_pakayen/core/widgets/empty_state.dart';
import 'package:aaj_kya_pakayen/core/widgets/undo_snack_bar.dart';
import 'package:aaj_kya_pakayen/data/providers.dart';
import 'package:aaj_kya_pakayen/domain/entities/dinner_log_entry.dart';
import 'package:aaj_kya_pakayen/domain/enums/day_type.dart';
import 'package:aaj_kya_pakayen/features/history/edit_dinner_sheet.dart';
import 'package:aaj_kya_pakayen/features/history/history_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

/// Last 7 days at a glance plus every recent dinner; tap to add or edit.
class HistoryScreen extends ConsumerWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(historyStateProvider);
    final actions = ref.watch(historyActionsProvider);
    String label(DateTime d) => DateFormat.MMMEd(l10n.localeName).format(d);

    Future<void> edit(DateTime date, HistoryEntry? existing) async {
      final dishes = ref.read(activeDishesProvider).value ?? const [];
      final result = await showEditDinnerSheet(
        context,
        dateLabel: label(date),
        dishes: dishes,
        initial: existing,
      );
      if (result == null) return;
      final newId = switch (result) {
        SaveHome(:final main, :final side) => await actions.saveHome(
          date,
          main: main,
          side: side,
        ),
        SaveOutside(:final note) => await actions.saveOutside(date, note: note),
        DeleteDinner() => null,
      };
      if (result is DeleteDinner) await actions.delete(existing!);
      if (!context.mounted) return;
      showUndoSnackBar(
        context,
        message: result is DeleteDinner
            ? l10n.historyDeleted(label(date))
            : l10n.historySaved(label(date)),
        onUndo: () => existing != null
            ? actions.restore(existing)
            : actions.removeById(newId!),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(l10n.historyTitle)),
      body: switch (state) {
        // 12dp sides leave 7 week chips at >= 48dp each on a 360dp phone.
        AsyncData(:final value) => ListView(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 24),
          children: [
            Text(
              l10n.historyThisWeek,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                for (final day in value.week)
                  Expanded(
                    child: _DayChip(
                      day: day,
                      tooltip: day.entry == null
                          ? l10n.historyAddFor(label(day.date))
                          : label(day.date),
                      onTap: () => edit(day.date, day.entry),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 24),
            if (value.entries.isEmpty)
              EmptyState(
                icon: Icons.history,
                title: l10n.historyEmpty,
                message: l10n.historyEmptyHint,
              )
            else ...[
              Text(
                l10n.historyAll,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              for (final e in value.entries)
                _EntryCard(
                  entry: e,
                  dateLabel: label(e.entry.date),
                  onTap: () => edit(e.entry.date, e),
                ),
            ],
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
}

IconData _iconFor(DinnerLogEntry e) => e.isOutside
    ? Icons.delivery_dining
    : e.dayType == DayType.vegDay
    ? Icons.eco
    : Icons.set_meal;

Color _colorFor(DinnerLogEntry e) =>
    e.dayType == DayType.vegDay ? AppColors.cardamom : AppColors.chilli;

class _DayChip extends StatelessWidget {
  const new({required this.day, required this.tooltip, required this.onTap});

  final HistoryDay day;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final entry = day.entry?.entry;
    final textTheme = Theme.of(context).textTheme;
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: const BorderRadius.all(Radius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            children: [
              Text(
                DateFormat.E(l10n.localeName).format(day.date),
                style: textTheme.labelSmall,
                maxLines: 1,
                overflow: TextOverflow.fade,
                softWrap: false,
              ),
              CircleAvatar(
                radius: 22,
                backgroundColor: entry == null
                    ? AppColors.saffronTint
                    : _colorFor(entry),
                child: Icon(
                  entry == null ? Icons.add : _iconFor(entry),
                  color: entry == null ? AppColors.chaiBrown : AppColors.white,
                ),
              ),
              Text('${day.date.day}', style: textTheme.labelMedium),
            ],
          ),
        ),
      ),
    );
  }
}

class _EntryCard extends StatelessWidget {
  const new({
    required this.entry,
    required this.dateLabel,
    required this.onTap,
  });

  final HistoryEntry entry;
  final String dateLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;
    final e = entry.entry;
    final main = entry.main;
    final side = entry.side;
    final note = e.outsideNote;
    return Card(
      margin: const EdgeInsets.only(top: 8),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: _colorFor(e),
                child: Icon(_iconFor(e), color: AppColors.white),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(dateLabel, style: textTheme.bodyMedium),
                    Text(
                      e.isOutside || main == null
                          ? l10n.outsideLogged
                          : l10n.dishName(main),
                      style: textTheme.titleMedium,
                    ),
                    if (side != null)
                      Text(l10n.todayWithSide(l10n.dishName(side))),
                    if (note != null) Text(note),
                  ],
                ),
              ),
              const Icon(Icons.edit),
            ],
          ),
        ),
      ),
    );
  }
}
