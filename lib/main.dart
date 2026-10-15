import 'package:aaj_kya_pakayen/app.dart';
import 'package:aaj_kya_pakayen/core/startup/app_startup.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

Future<void> main() async {
  // The native splash stays up while the database opens and seeds.
  WidgetsFlutterBinding.ensureInitialized();
  final container = ProviderContainer();
  await container.read(appStartupProvider.future);
  runApp(UncontrolledProviderScope(container: container, child: const App()));
}
