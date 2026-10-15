import 'package:aaj_kya_pakayen/core/l10n/generated/app_localizations.dart';
import 'package:aaj_kya_pakayen/core/l10n/labels.dart';
import 'package:aaj_kya_pakayen/core/theme/app_colors.dart';
import 'package:aaj_kya_pakayen/core/widgets/big_button.dart';
import 'package:aaj_kya_pakayen/domain/entities/dish.dart';
import 'package:aaj_kya_pakayen/domain/enums/dish_type.dart';
import 'package:aaj_kya_pakayen/features/history/history_controller.dart';
import 'package:flutter/material.dart';

sealed class EditDinnerResult {
  const new();
}

final class SaveHome extends EditDinnerResult {
  const new(this.main, this.side);

  final Dish main;
  final Dish? side;
}

final class SaveOutside extends EditDinnerResult {
  const new(this.note);

  final String note;
}

final class DeleteDinner extends EditDinnerResult {
  const new();
}

Future<EditDinnerResult?> showEditDinnerSheet(
  BuildContext context, {
  required String dateLabel,
  required List<Dish> dishes,
  HistoryEntry? initial,
}) => showModalBottomSheet<EditDinnerResult>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  showDragHandle: true,
  builder: (_) =>
      EditDinnerSheet(dateLabel: dateLabel, dishes: dishes, initial: initial),
);

/// Add or change the dinner of one day: a home dish (and side) or outside.
class EditDinnerSheet extends StatefulWidget {
  const new({
    required this.dateLabel,
    required this.dishes,
    this.initial,
    super.key,
  });

  final String dateLabel;
  final List<Dish> dishes;
  final HistoryEntry? initial;

  @override
  State<EditDinnerSheet> createState() => _EditDinnerSheetState();
}

class _EditDinnerSheetState extends State<EditDinnerSheet> {
  late bool _outside = widget.initial?.entry.isOutside ?? false;
  late Dish? _main = widget.initial?.main;
  late Dish? _side = widget.initial?.side;
  late final _note = TextEditingController(
    text: widget.initial?.entry.outsideNote,
  );

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;
    final byName = [...widget.dishes]
      ..sort((a, b) => l10n.dishName(a).compareTo(l10n.dishName(b)));
    final sides = byName.where(
      (d) => d.dishType == DishType.vegetable && d.canBeSide,
    );
    final main = _main;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            l10n.historyEditTitle(widget.dateLabel),
            style: textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          SegmentedButton<bool>(
            segments: [
              ButtonSegment(
                value: false,
                icon: const Icon(Icons.soup_kitchen),
                label: Text(l10n.historyCookedHome),
              ),
              ButtonSegment(
                value: true,
                icon: const Icon(Icons.delivery_dining),
                label: Text(l10n.historyOrderedOutside),
              ),
            ],
            selected: {_outside},
            onSelectionChanged: (s) => setState(() => _outside = s.single),
          ),
          const SizedBox(height: 16),
          if (_outside)
            TextField(
              controller: _note,
              decoration: InputDecoration(
                labelText: l10n.outsideNoteLabel,
                hintText: l10n.outsideNoteHint,
              ),
            )
          else ...[
            DropdownMenu<Dish>(
              expandedInsets: EdgeInsets.zero,
              label: Text(l10n.historyDish),
              initialSelection: main,
              enableFilter: true,
              requestFocusOnTap: true,
              menuHeight: 320,
              onSelected: (d) => setState(() {
                _main = d;
                if (d == null || d.isVeg) _side = null;
              }),
              dropdownMenuEntries: [
                for (final d in byName)
                  DropdownMenuEntry(value: d, label: l10n.dishName(d)),
              ],
            ),
            if (main != null && !main.isVeg) ...[
              const SizedBox(height: 16),
              DropdownMenu<Dish?>(
                expandedInsets: EdgeInsets.zero,
                label: Text(l10n.historySide),
                initialSelection: _side,
                menuHeight: 320,
                onSelected: (d) => setState(() => _side = d),
                dropdownMenuEntries: [
                  DropdownMenuEntry(value: null, label: l10n.historyNoSide),
                  for (final d in sides)
                    DropdownMenuEntry(value: d, label: l10n.dishName(d)),
                ],
              ),
            ],
          ],
          const SizedBox(height: 24),
          BigButton(
            label: l10n.save,
            icon: Icons.check,
            onPressed: _outside
                ? () => Navigator.of(context).pop(SaveOutside(_note.text))
                : main == null
                ? null
                : () => Navigator.of(context).pop(SaveHome(main, _side)),
          ),
          if (widget.initial != null) ...[
            const SizedBox(height: 8),
            TextButton.icon(
              style: TextButton.styleFrom(foregroundColor: AppColors.chilli),
              onPressed: () => Navigator.of(context).pop(const DeleteDinner()),
              icon: const Icon(Icons.delete_outline),
              label: Text(l10n.historyDelete),
            ),
          ],
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
