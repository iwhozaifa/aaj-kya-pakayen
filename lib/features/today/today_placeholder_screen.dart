import 'package:aaj_kya_pakayen/core/l10n/generated/app_localizations.dart';
import 'package:aaj_kya_pakayen/core/widgets/app_logo.dart';
import 'package:flutter/material.dart';

/// Temporary branded home screen until `feature/today-screen` lands.
class TodayPlaceholderScreen extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const AppLogo(size: 180),
              const SizedBox(height: 24),
              Text(
                l10n.appTitle,
                style: textTheme.displaySmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                l10n.tagline,
                style: textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
