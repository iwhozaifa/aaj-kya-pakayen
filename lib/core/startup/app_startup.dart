import 'package:aaj_kya_pakayen/data/providers.dart';
import 'package:aaj_kya_pakayen/data/seed/dish_seeder.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'app_startup.g.dart';

/// One-time work before the first frame: open the database, seed dishes
/// and load settings, so the router knows whether to show onboarding.
@Riverpod(keepAlive: true)
Future<void> appStartup(Ref ref) async {
  await DishSeeder(ref.watch(appDatabaseProvider)).seedIfNeeded();
  await ref.watch(appSettingsProvider.future);
}
