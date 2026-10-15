import 'package:aaj_kya_pakayen/domain/entities/app_settings.dart';
import 'package:aaj_kya_pakayen/domain/entities/cuisine_pack.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('only the Pakistani pack is available so far', () {
    expect(CuisinePack.pakistani.isAvailable, isTrue);
    expect(
      CuisinePack.values.where((p) => !p.isAvailable),
      containsAll([
        CuisinePack.indian,
        CuisinePack.afghan,
        CuisinePack.chinese,
      ]),
    );
  });

  test('pack ids match the dish cuisine field and default settings', () {
    expect(CuisinePack.pakistani.id, 'pakistani');
    expect(const AppSettings().enabledCuisines, {
      for (final p in CuisinePack.values.where((p) => p.isAvailable)) p.id,
    });
  });
}
