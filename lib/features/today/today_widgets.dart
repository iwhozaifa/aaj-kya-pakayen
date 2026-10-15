import 'package:aaj_kya_pakayen/core/l10n/generated/app_localizations.dart';
import 'package:aaj_kya_pakayen/core/l10n/labels.dart';
import 'package:aaj_kya_pakayen/core/theme/app_colors.dart';
import 'package:aaj_kya_pakayen/core/widgets/big_button.dart';
import 'package:aaj_kya_pakayen/core/widgets/section_card.dart';
import 'package:aaj_kya_pakayen/domain/engine/reason.dart';
import 'package:aaj_kya_pakayen/domain/engine/suggestion_engine.dart';
import 'package:aaj_kya_pakayen/domain/enums/day_type.dart';
import 'package:aaj_kya_pakayen/features/today/today_controller.dart';
import 'package:flutter/material.dart';

/// "Sabzi day" (cardamom) or "Gosht day" (chilli).
class DayBadge extends StatelessWidget {
  const new({required this.dayType, required this.swapped, super.key});

  final DayType dayType;
  final bool swapped;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final veg = dayType == DayType.vegDay;
    final textTheme = Theme.of(context).textTheme;
    return Column(
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            color: veg ? AppColors.cardamom : AppColors.chilli,
            borderRadius: const BorderRadius.all(Radius.circular(24)),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  veg ? Icons.eco : Icons.set_meal,
                  color: AppColors.white,
                  size: 28,
                ),
                const SizedBox(width: 8),
                Text(
                  l10n.dayType(dayType),
                  style: textTheme.titleLarge?.copyWith(color: AppColors.white),
                ),
              ],
            ),
          ),
        ),
        if (swapped)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(l10n.todaySwapped, style: textTheme.bodyMedium),
          ),
      ],
    );
  }
}

class _Reasons extends StatelessWidget {
  const new({required this.reasons});

  final List<Reason> reasons;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final r in reasons.take(3))
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsetsDirectional.only(end: 8, top: 4),
                  child: Icon(Icons.check_circle, color: AppColors.cardamom),
                ),
                Expanded(
                  child: Text(
                    l10n.reason(r),
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// The top suggestion: big name, side, reasons and "Cooking this".
class SuggestionCard extends StatelessWidget {
  const new({required this.suggestion, required this.onCook, super.key});

  final HomeSuggestion suggestion;
  final VoidCallback onCook;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;
    final side = suggestion.side;
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l10n.dishName(suggestion.main), style: textTheme.displaySmall),
          if (side != null)
            Text(
              l10n.todayWithSide(l10n.dishName(side)),
              style: textTheme.titleMedium,
            ),
          const SizedBox(height: 8),
          _Reasons(reasons: suggestion.reasons),
          const SizedBox(height: 16),
          BigButton(
            label: l10n.todayCookThis,
            icon: Icons.check,
            onPressed: onCook,
          ),
        ],
      ),
    );
  }
}

/// No home dish is possible: order outside, with a restock hint.
class OutsideCard extends StatelessWidget {
  const new({required this.suggestion, required this.onOrder, super.key});

  final OutsideSuggestion suggestion;
  final VoidCallback onOrder;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Icon(Icons.delivery_dining, size: 56, color: AppColors.chilli),
          Text(
            l10n.outsideTitle,
            style: Theme.of(context).textTheme.headlineSmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          _Reasons(reasons: suggestion.reasons),
          const SizedBox(height: 16),
          BigButton(
            label: l10n.todayOutside,
            icon: Icons.delivery_dining,
            tone: BigButtonTone.meat,
            onPressed: onOrder,
          ),
        ],
      ),
    );
  }
}

/// Tonight is already logged.
class LoggedCard extends StatelessWidget {
  const new({required this.state, required this.onChange, super.key});

  final TodayState state;
  final VoidCallback onChange;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;
    final tonight = state.tonight!;
    final main = state.tonightMain;
    final side = state.tonightSide;
    final note = tonight.outsideNote;
    return SectionCard(
      title: l10n.todayLoggedTitle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            tonight.isOutside || main == null
                ? l10n.outsideLogged
                : l10n.dishName(main),
            style: textTheme.displaySmall,
          ),
          if (side != null)
            Text(
              l10n.todayWithSide(l10n.dishName(side)),
              style: textTheme.titleMedium,
            ),
          if (note != null) Text(note, style: textTheme.titleMedium),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: onChange,
            icon: const Icon(Icons.edit),
            label: Text(l10n.todayChange),
          ),
        ],
      ),
    );
  }
}

/// One of the runner-up suggestions.
class OtherIdeaTile extends StatelessWidget {
  const new({required this.suggestion, required this.onCook, super.key});

  final HomeSuggestion suggestion;
  final VoidCallback onCook;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final side = suggestion.side;
    return Card(
      margin: const EdgeInsets.only(top: 8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.dishName(suggestion.main),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  if (side != null)
                    Text(l10n.todayWithSide(l10n.dishName(side))),
                ],
              ),
            ),
            TextButton(onPressed: onCook, child: Text(l10n.todayCook)),
          ],
        ),
      ),
    );
  }
}
