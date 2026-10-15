import 'package:aaj_kya_pakayen/features/today/today_placeholder_screen.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'app_router.g.dart';

abstract final class AppRoutes {
  static const today = '/';
}

@riverpod
GoRouter appRouter(Ref ref) {
  final router = GoRouter(
    routes: [
      GoRoute(
        path: AppRoutes.today,
        builder: (context, state) => const TodayPlaceholderScreen(),
      ),
    ],
  );
  ref.onDispose(router.dispose);
  return router;
}
