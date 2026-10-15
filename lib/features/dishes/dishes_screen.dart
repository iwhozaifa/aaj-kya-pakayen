import 'package:aaj_kya_pakayen/core/l10n/generated/app_localizations.dart';
import 'package:aaj_kya_pakayen/core/l10n/labels.dart';
import 'package:aaj_kya_pakayen/core/theme/app_colors.dart';
import 'package:aaj_kya_pakayen/core/widgets/big_button.dart';
import 'package:aaj_kya_pakayen/core/widgets/empty_state.dart';
import 'package:aaj_kya_pakayen/core/widgets/undo_snack_bar.dart';
import 'package:aaj_kya_pakayen/domain/entities/dish.dart';
import 'package:aaj_kya_pakayen/domain/enums/dish_type.dart';
import 'package:aaj_kya_pakayen/domain/usecases/dish_catalog.dart';
import 'package:aaj_kya_pakayen/features/dishes/add_dish_sheet.dart';
import 'package:aaj_kya_pakayen/features/dishes/dishes_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Every dish the app can suggest: search, filter, switch off, add more.
class DishesScreen extends ConsumerStatefulWidget {
  const new({super.key});

  @override
  ConsumerState<DishesScreen> createState() => _DishesScreenState();
}

class _DishesScreenState extends ConsumerState<DishesScreen> {
  final _search = TextEditingController();
  DishType? _type;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _toggle(Dish dish) async {
    final l10n = AppLocalizations.of(context);
    final actions = ref.read(dishesActionsProvider);
    final active = !dish.isActive;
    await actions.setActive(dish, active: active);
    if (!mounted) return;
    final name = l10n.dishName(dish);
    showUndoSnackBar(
      context,
      message: active
          ? l10n.dishesShownSnack(name)
          : l10n.dishesHiddenSnack(name),
      onUndo: () => actions.setActive(dish, active: !active),
    );
  }

  Future<void> _add(List<Dish> existing) async {
    final draft = await showAddDishSheet(context, existing: existing);
    if (draft == null || !mounted) return;
    final l10n = AppLocalizations.of(context);
    final actions = ref.read(dishesActionsProvider);
    final added = await actions.addCustom(draft);
    if (!mounted) return;
    showUndoSnackBar(
      context,
      message: l10n.dishesAdded(l10n.dishName(added)),
      onUndo: () => actions.undoAdd(added),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final dishes = ref.watch(allDishesProvider);
    final all = dishes.value ?? const <Dish>[];

    return Scaffold(
      appBar: AppBar(title: Text(l10n.dishesTitle)),
      // A fixed footer rather than a floating button, so nothing in the
      // list is ever covered.
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: BigButton(
            label: l10n.dishesAdd,
            icon: Icons.add,
            onPressed: dishes.hasValue ? () => _add(all) : null,
          ),
        ),
      ),
      body: switch (dishes) {
        AsyncData() => ListView(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          children: [
            _SearchField(controller: _search, onChanged: () => setState(() {})),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ChoiceChip(
                  label: Text(l10n.dishesAll),
                  selected: _type == null,
                  onSelected: (_) => setState(() => _type = null),
                ),
                for (final t in DishType.values)
                  ChoiceChip(
                    label: Text(l10n.dishType(t)),
                    selected: _type == t,
                    onSelected: (_) => setState(() => _type = t),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            ..._results(l10n, all),
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

  List<Widget> _results(AppLocalizations l10n, List<Dish> all) {
    final found = filterDishes(all, query: _search.text, type: _type);
    if (found.isEmpty) {
      return [
        EmptyState(
          icon: Icons.search_off,
          title: l10n.dishesNone,
          message: l10n.dishesNoneHint,
        ),
      ];
    }
    return [
      for (final dish in found)
        _DishTile(dish: dish, onToggle: () => _toggle(dish)),
    ];
  }
}

class _SearchField extends StatelessWidget {
  const new({required this.controller, required this.onChanged});

  final TextEditingController controller;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return TextField(
      controller: controller,
      onChanged: (_) => onChanged(),
      decoration: InputDecoration(
        labelText: l10n.dishesSearch,
        prefixIcon: const Icon(Icons.search),
        border: const OutlineInputBorder(),
        suffixIcon: controller.text.isEmpty
            ? null
            : IconButton(
                tooltip: l10n.dishesClearSearch,
                icon: const Icon(Icons.clear),
                onPressed: () {
                  controller.clear();
                  onChanged();
                },
              ),
      ),
    );
  }
}

class _DishTile extends StatelessWidget {
  const new({required this.dish, required this.onToggle});

  final Dish dish;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;
    final details = [
      l10n.dishesSubtitle(l10n.dishType(dish.dishType), dish.prepMinutes),
      if (dish.isCustom) l10n.dishesMine,
      if (!dish.isActive) l10n.dishesHidden,
    ];
    return Card(
      margin: const EdgeInsets.only(top: 8),
      clipBehavior: Clip.antiAlias,
      child: SwitchListTile(
        value: dish.isActive,
        onChanged: (_) => onToggle(),
        activeTrackColor: AppColors.cardamom,
        activeThumbColor: AppColors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        secondary: Icon(
          dish.isVeg ? Icons.eco : Icons.set_meal,
          color: dish.isVeg ? AppColors.cardamom : AppColors.chilli,
        ),
        title: Text(l10n.dishName(dish), style: textTheme.titleMedium),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [for (final d in details) Text(d)],
        ),
      ),
    );
  }
}
