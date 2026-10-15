import 'dart:math';

import 'package:aaj_kya_pakayen/core/l10n/generated/app_localizations.dart';
import 'package:aaj_kya_pakayen/core/l10n/labels.dart';
import 'package:aaj_kya_pakayen/core/theme/app_colors.dart';
import 'package:aaj_kya_pakayen/core/widgets/empty_state.dart';
import 'package:aaj_kya_pakayen/core/widgets/error_state.dart';
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
        AsyncData(:final value) => ListView(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 24),
          children: [
            Text(
              l10n.historyThisWeek,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            _WeekStrip(
              weekdays: [
                for (final day in value.week)
                  DateFormat.E(l10n.localeName).format(day.date),
              ],
              children: [
                for (final day in value.week)
                  _DayChip(
                    day: day,
                    tooltip: day.entry == null
                        ? l10n.historyAddFor(label(day.date))
                        : label(day.date),
                    onTap: () => edit(day.date, day.entry),
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
        AsyncError() => ErrorState(
          onRetry: () => ref.invalidate(historyStateProvider),
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

/// The 7 day chips in one row when the weekday names fit, otherwise in
/// balanced rows (4 + 3). Urdu names are long and large text must never
/// fade or split them (docs/DECISIONS.md D-034).
class _WeekStrip extends StatelessWidget {
  const new({required this.children, required this.weekdays});

  final List<Widget> children;
  final List<String> weekdays;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.labelSmall;
    final scaler = MediaQuery.textScalerOf(context);
    final direction = Directionality.of(context);
    var widest = 0.0;
    for (final name in weekdays) {
      final painter = TextPainter(
        text: TextSpan(text: name, style: style),
        textDirection: direction,
        textScaler: scaler,
        maxLines: 1,
      )..layout();
      widest = max(widest, painter.width);
      painter.dispose();
    }
    // A little breathing room; never under the 48 dp touch target.
    final needed = max(48, widest + 4);

    return LayoutBuilder(
      builder: (context, constraints) {
        final fit = (constraints.maxWidth ~/ needed).clamp(1, children.length);
        final rows = (children.length / fit).ceil();
        final perRow = (children.length / rows).ceil();
        final width = constraints.maxWidth / perRow;
        return Wrap(
          alignment: WrapAlignment.center,
          runSpacing: 8,
          children: [
            for (final chip in children) SizedBox(width: width, child: chip),
          ],
        );
      },
    );
  }
}

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
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                DateFormat.E(l10n.localeName).format(day.date),
                style: textTheme.labelSmall,
                maxLines: 1,
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
