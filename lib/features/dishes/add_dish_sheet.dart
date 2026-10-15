import 'package:aaj_kya_pakayen/core/l10n/generated/app_localizations.dart';
import 'package:aaj_kya_pakayen/core/l10n/labels.dart';
import 'package:aaj_kya_pakayen/core/widgets/big_button.dart';
import 'package:aaj_kya_pakayen/domain/entities/dish.dart';
import 'package:aaj_kya_pakayen/domain/enums/cooking_style.dart';
import 'package:aaj_kya_pakayen/domain/enums/dish_type.dart';
import 'package:aaj_kya_pakayen/domain/enums/staple_pairing.dart';
import 'package:aaj_kya_pakayen/domain/usecases/dish_catalog.dart';
import 'package:flutter/material.dart';

/// Bottom sheet for a dish of the cook's own. Pops a [CustomDishDraft].
Future<CustomDishDraft?> showAddDishSheet(
  BuildContext context, {
  required List<Dish> existing,
}) => showModalBottomSheet<CustomDishDraft>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  showDragHandle: true,
  builder: (_) => AddDishSheet(existing: existing),
);

class AddDishSheet extends StatefulWidget {
  const new({required this.existing, super.key});

  /// Every dish, hidden ones too, to catch duplicate names early.
  final List<Dish> existing;

  static const minuteChoices = [30, 45, 60, 90, 120];

  @override
  State<AddDishSheet> createState() => _AddDishSheetState();
}

class _AddDishSheetState extends State<AddDishSheet> {
  final _name = TextEditingController();
  DishType _type = DishType.vegetable;
  StaplePairing _staple = StaplePairing.roti;
  CookingStyle _style = CookingStyle.curry;
  int _minutes = 45;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _save() {
    final l10n = AppLocalizations.of(context);
    final name = _name.text.trim();
    final duplicate = findByName(widget.existing, name);
    setState(
      () => _error = name.isEmpty
          ? l10n.addDishNameRequired
          : duplicate != null
          ? l10n.addDishDuplicate(l10n.dishName(duplicate))
          : null,
    );
    if (_error != null) return;
    Navigator.of(context).pop(
      CustomDishDraft(
        name: name,
        dishType: _type,
        staplePairing: _staple,
        cookingStyle: _style,
        prepMinutes: _minutes,
      ),
    );
  }

  Widget _choices<T>(
    String title,
    List<T> values,
    T selected,
    String Function(T) label,
    void Function(T) onSelected,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 24),
        Text(title, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final v in values)
              ChoiceChip(
                label: Text(label(v)),
                selected: v == selected,
                onSelected: (_) => setState(() => onSelected(v)),
              ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        24,
        0,
        24,
        24 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            l10n.addDishTitle,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _name,
            textCapitalization: TextCapitalization.words,
            decoration: InputDecoration(
              labelText: l10n.addDishName,
              errorText: _error,
              border: const OutlineInputBorder(),
            ),
          ),
          _choices(
            l10n.addDishType,
            DishType.values,
            _type,
            l10n.dishType,
            (v) => _type = v,
          ),
          _choices(
            l10n.addDishServedWith,
            StaplePairing.values,
            _staple,
            l10n.staple,
            (v) => _staple = v,
          ),
          _choices(
            l10n.addDishStyle,
            CookingStyle.values,
            _style,
            l10n.style,
            (v) => _style = v,
          ),
          _choices(
            l10n.addDishTime,
            AddDishSheet.minuteChoices,
            _minutes,
            l10n.durationMinutes,
            (v) => _minutes = v,
          ),
          const SizedBox(height: 32),
          BigButton(label: l10n.save, icon: Icons.check, onPressed: _save),
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
