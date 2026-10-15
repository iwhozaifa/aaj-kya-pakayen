import 'package:aaj_kya_pakayen/core/l10n/generated/app_localizations.dart';
import 'package:aaj_kya_pakayen/core/l10n/labels.dart';
import 'package:aaj_kya_pakayen/core/theme/app_colors.dart';
import 'package:aaj_kya_pakayen/core/widgets/empty_state.dart';
import 'package:aaj_kya_pakayen/core/widgets/number_stepper.dart';
import 'package:aaj_kya_pakayen/core/widgets/section_card.dart';
import 'package:aaj_kya_pakayen/data/providers.dart';
import 'package:aaj_kya_pakayen/domain/entities/app_settings.dart';
import 'package:aaj_kya_pakayen/domain/entities/cuisine_pack.dart';
import 'package:aaj_kya_pakayen/domain/enums/time_budget.dart';
import 'package:aaj_kya_pakayen/features/settings/settings_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Language, household, repeat window, time budget, cuisines, reminder.
/// Every change saves straight away.
class SettingsScreen extends ConsumerWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final settings = ref.watch(appSettingsProvider);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsTitle)),
      body: switch (settings) {
        AsyncData(:final value) => _SettingsList(settings: value),
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

class _SettingsList extends ConsumerWidget {
  const new({required this.settings});

  final AppSettings settings;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final actions = ref.watch(settingsActionsProvider);

    Future<void> toggleReminder({required bool enabled}) async {
      final allowed = await actions.setReminderEnabled(enabled: enabled);
      if (allowed || !context.mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(l10n.settingsReminderDenied)));
    }

    Future<void> pickTime() async {
      final minutes = settings.reminderMinutes;
      final picked = await showTimePicker(
        context: context,
        initialTime: TimeOfDay(hour: minutes ~/ 60, minute: minutes % 60),
      );
      if (picked == null) return;
      await actions.setReminderTime(picked.hour * 60 + picked.minute);
    }

    final reminderTime = TimeOfDay(
      hour: settings.reminderMinutes ~/ 60,
      minute: settings.reminderMinutes % 60,
    ).format(context);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      children: [
        SectionCard(
          title: l10n.settingsLanguage,
          child: _Options(
            values: const ['ur', 'en'],
            selected: settings.languageCode,
            label: (code) =>
                code == 'ur' ? l10n.languageUrdu : l10n.languageEnglish,
            onSelected: actions.setLanguage,
          ),
        ),
        SectionCard(
          title: l10n.settingsHousehold,
          child: NumberStepper(
            value: settings.householdSize,
            min: AppSettings.householdSizes.min,
            max: AppSettings.householdSizes.max,
            label: l10n.peopleCount(settings.householdSize),
            decreaseTooltip: l10n.fewerPeople,
            increaseTooltip: l10n.morePeople,
            onChanged: actions.setHouseholdSize,
          ),
        ),
        SectionCard(
          title: l10n.settingsRepeatWindow,
          child: NumberStepper(
            value: settings.repeatWindowDays,
            min: AppSettings.repeatWindows.min,
            max: AppSettings.repeatWindows.max,
            label: l10n.daysCount(settings.repeatWindowDays),
            decreaseTooltip: l10n.fewerDays,
            increaseTooltip: l10n.moreDays,
            onChanged: actions.setRepeatWindow,
          ),
        ),
        SectionCard(
          title: l10n.settingsTimeBudget,
          child: _Options(
            values: TimeBudget.values,
            selected: settings.timeBudget,
            label: l10n.timeBudget,
            onSelected: actions.setTimeBudget,
          ),
        ),
        SectionCard(
          title: l10n.settingsReminderSection,
          child: Column(
            children: [
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: settings.reminderEnabled,
                onChanged: (on) => toggleReminder(enabled: on),
                activeTrackColor: AppColors.cardamom,
                activeThumbColor: AppColors.white,
                title: Text(l10n.settingsReminder),
                subtitle: Text(l10n.settingsReminderHint),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.schedule),
                title: Text(l10n.settingsReminderTime),
                trailing: Text(
                  reminderTime,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                onTap: pickTime,
              ),
            ],
          ),
        ),
        SectionCard(
          title: l10n.settingsCuisines,
          child: Column(
            children: [
              for (final pack in CuisinePack.values)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    pack.isAvailable
                        ? Icons.check_circle
                        : Icons.hourglass_empty,
                    color: pack.isAvailable
                        ? AppColors.cardamom
                        : AppColors.chaiBrown,
                  ),
                  title: Text(l10n.cuisine(pack)),
                  subtitle: Text(
                    pack.isAvailable ? l10n.cuisineIncluded : l10n.comingSoon,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

/// One full-width row per option. Unlike chips, long labels can wrap at
/// large text sizes.
class _Options<T> extends StatelessWidget {
  const new({
    required this.values,
    required this.selected,
    required this.label,
    required this.onSelected,
  });

  final List<T> values;
  final T selected;
  final String Function(T) label;
  final ValueChanged<T> onSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final v in values)
          Semantics(
            inMutuallyExclusiveGroup: true,
            checked: v == selected,
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              selected: v == selected,
              selectedColor: AppColors.chaiBrown,
              selectedTileColor: AppColors.saffronTint,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(12)),
              ),
              leading: Icon(
                v == selected
                    ? Icons.radio_button_checked
                    : Icons.radio_button_unchecked,
                color: AppColors.chaiBrown,
              ),
              title: Text(label(v)),
              onTap: () => onSelected(v),
            ),
          ),
      ],
    );
  }
}
