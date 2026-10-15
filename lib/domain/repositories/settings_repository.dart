import 'package:aaj_kya_pakayen/domain/entities/app_settings.dart';

abstract interface class SettingsRepository {
  /// Stored settings, with defaults for anything never saved.
  Future<AppSettings> load();

  Stream<AppSettings> watch();

  Future<void> save(AppSettings settings);
}
