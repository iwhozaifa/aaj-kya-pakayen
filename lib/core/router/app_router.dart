import 'package:aaj_kya_pakayen/core/widgets/app_shell.dart';
import 'package:aaj_kya_pakayen/features/dishes/dishes_screen.dart';
import 'package:aaj_kya_pakayen/features/history/history_screen.dart';
import 'package:aaj_kya_pakayen/features/pantry/pantry_screen.dart';
import 'package:aaj_kya_pakayen/features/today/today_screen.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'app_router.g.dart';

abstract final class AppRoutes {
  static const today = '/';
  static const pantry = '/pantry';
  static const history = '/history';
  static const dishes = '/dishes';
}

@riverpod
GoRouter appRouter(Ref ref) {
  final router = GoRouter(
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => AppShell(navigationShell: shell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.today,
                builder: (context, state) => const TodayScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.pantry,
                builder: (context, state) => const PantryScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.history,
                builder: (context, state) => const HistoryScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.dishes,
                builder: (context, state) => const DishesScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
  ref.onDispose(router.dispose);
  return router;
}
