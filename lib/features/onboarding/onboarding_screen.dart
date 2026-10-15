import 'package:aaj_kya_pakayen/core/l10n/generated/app_localizations.dart';
import 'package:aaj_kya_pakayen/core/l10n/labels.dart';
import 'package:aaj_kya_pakayen/core/widgets/app_logo.dart';
import 'package:aaj_kya_pakayen/core/widgets/big_button.dart';
import 'package:aaj_kya_pakayen/core/widgets/number_stepper.dart';
import 'package:aaj_kya_pakayen/domain/entities/app_settings.dart';
import 'package:aaj_kya_pakayen/domain/enums/protein_type.dart';
import 'package:aaj_kya_pakayen/features/onboarding/onboarding_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// First run: language, then household size, then the meat at home.
class OnboardingScreen extends ConsumerStatefulWidget {
  const new({super.key});

  static const steps = 3;

  /// Amounts offered per protein on the last step, in grams.
  static const amounts = [0, 500, 1000, 2000, 3000];

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  int _step = 1;
  String _language = 'ur';
  int _household = const AppSettings().householdSize;
  final Map<ProteinType, int> _stock = {};
  bool _saving = false;

  OnboardingActions get _actions => ref.read(onboardingActionsProvider);

  Future<void> _chooseLanguage(String code) async {
    setState(() {
      _language = code;
      _step = 2;
    });
    await _actions.chooseLanguage(code);
  }

  Future<void> _finish() async {
    setState(() => _saving = true);
    await _actions.finish(
      languageCode: _language,
      householdSize: _household,
      stock: {
        for (final MapEntry(:key, :value) in _stock.entries)
          if (value > 0) key: value,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
          children: [
            const Center(child: AppLogo(size: 72)),
            const SizedBox(height: 8),
            Text(
              l10n.appTitle,
              textAlign: TextAlign.center,
              style: textTheme.headlineMedium,
            ),
            Text(
              l10n.onboardingStep(_step, OnboardingScreen.steps),
              textAlign: TextAlign.center,
              style: textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            ...switch (_step) {
              1 => _languageStep(l10n, textTheme),
              2 => _householdStep(l10n, textTheme),
              _ => _stockStep(l10n, textTheme),
            },
            if (_step > 1) ...[
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: () => setState(() => _step--),
                icon: const Icon(Icons.arrow_back),
                label: Text(l10n.back),
              ),
            ],
          ],
        ),
      ),
    );
  }

  List<Widget> _languageStep(AppLocalizations l10n, TextTheme textTheme) => [
    Text(
      l10n.onboardingLanguage,
      textAlign: TextAlign.center,
      style: textTheme.titleLarge,
    ),
    const SizedBox(height: 24),
    BigButton(label: l10n.languageUrdu, onPressed: () => _chooseLanguage('ur')),
    const SizedBox(height: 16),
    BigButton(
      label: l10n.languageEnglish,
      onPressed: () => _chooseLanguage('en'),
    ),
  ];

  List<Widget> _householdStep(AppLocalizations l10n, TextTheme textTheme) => [
    Text(
      l10n.onboardingHousehold,
      textAlign: TextAlign.center,
      style: textTheme.titleLarge,
    ),
    const SizedBox(height: 24),
    NumberStepper(
      value: _household,
      min: AppSettings.householdSizes.min,
      max: AppSettings.householdSizes.max,
      label: l10n.peopleCount(_household),
      decreaseTooltip: l10n.fewerPeople,
      increaseTooltip: l10n.morePeople,
      onChanged: (v) => setState(() => _household = v),
    ),
    const SizedBox(height: 32),
    BigButton(
      label: l10n.next,
      icon: Icons.arrow_forward,
      onPressed: () => setState(() => _step = 3),
    ),
  ];

  List<Widget> _stockStep(AppLocalizations l10n, TextTheme textTheme) => [
    Text(
      l10n.onboardingStock,
      textAlign: TextAlign.center,
      style: textTheme.titleLarge,
    ),
    Text(
      l10n.onboardingStockHint,
      textAlign: TextAlign.center,
      style: textTheme.bodyMedium,
    ),
    const SizedBox(height: 16),
    for (final protein in ProteinType.values)
      Padding(
        key: ValueKey(protein),
        padding: const EdgeInsets.only(bottom: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.protein(protein), style: textTheme.titleMedium),
            const SizedBox(height: 4),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final grams in OnboardingScreen.amounts)
                  ChoiceChip(
                    label: Text(
                      grams == 0 ? l10n.stockNone : l10n.grams(grams),
                    ),
                    selected: (_stock[protein] ?? 0) == grams,
                    onSelected: (_) => setState(() => _stock[protein] = grams),
                  ),
              ],
            ),
          ],
        ),
      ),
    const SizedBox(height: 16),
    BigButton(
      label: l10n.onboardingStart,
      icon: Icons.check,
      onPressed: _saving ? null : _finish,
    ),
  ];
}
