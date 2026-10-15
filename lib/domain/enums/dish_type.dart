import 'package:aaj_kya_pakayen/domain/enums/protein_type.dart';

enum DishType {
  vegetable,
  pulse,
  chicken,
  beef,
  mutton,
  mince;

  /// Vegetable and pulse dishes are cooked on veg days.
  bool get isVeg => this == vegetable || this == pulse;

  ProteinType? get proteinType => switch (this) {
    vegetable || pulse => null,
    chicken => ProteinType.chicken,
    beef => ProteinType.beef,
    mutton => ProteinType.mutton,
    mince => ProteinType.mince,
  };
}
