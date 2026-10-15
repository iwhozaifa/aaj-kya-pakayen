import 'package:aaj_kya_pakayen/core/widgets/app_shell.dart';
import 'package:aaj_kya_pakayen/data/providers.dart';
import 'package:aaj_kya_pakayen/features/dishes/dishes_screen.dart';
import 'package:aaj_kya_pakayen/features/history/history_screen.dart';
import 'package:aaj_kya_pakayen/features/onboarding/onboarding_screen.dart';
import 'package:aaj_kya_pakayen/features/pantry/pantry_screen.dart';
import 'package:aaj_kya_pakayen/features/settings/settings_screen.dart';
import 'package:aaj_kya_pakayen/features/today/today_screen.dart';
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'app_router.g.dart';

abstract final class AppRoutes {
  static const today = '/';
  static const pantry = '/pantry';
  static const history = '/history';
  static const dishes = '/dishes';
  static const settings = '/settings';
  static const welcome = '/welcome';
}

@riverpod
GoRouter appRouter(Ref ref) {
  // Re-runs the redirect whenever onboarding is finished (or reset).
  final onboarded = ValueNotifier<bool?>(
    ref.read(appSettingsProvider).value?.onboardingComplete,
  );
  ref
    ..listen(
      appSettingsProvider,
      // ValueNotifier only notifies when the flag actually changes.
      (_, settings) => onboarded.value = settings.value?.onboardingComplete,
    )
    ..onDispose(onboarded.dispose);

  StatefulShellBranch tab(String path, Widget Function() screen) =>
      StatefulShellBranch(
        routes: [GoRoute(path: path, builder: (_, _) => screen())],
      );

  final router = GoRouter(
    refreshListenable: onboarded,
    redirect: (context, state) {
      final done = onboarded.value;
      // Settings are loaded at startup; stay put if they are not yet.
      if (done == null) return null;
      final atWelcome = state.matchedLocation == AppRoutes.welcome;
      if (!done && !atWelcome) return AppRoutes.welcome;
      if (done && atWelcome) return AppRoutes.today;
      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.welcome,
        builder: (_, _) => const OnboardingScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => AppShell(navigationShell: shell),
        branches: [
          tab(AppRoutes.today, () => const TodayScreen()),
          tab(AppRoutes.pantry, () => const PantryScreen()),
          tab(AppRoutes.history, () => const HistoryScreen()),
          tab(AppRoutes.dishes, () => const DishesScreen()),
          tab(AppRoutes.settings, () => const SettingsScreen()),
        ],
      ),
    ],
  );
  ref.onDispose(router.dispose);
  return router;
}
