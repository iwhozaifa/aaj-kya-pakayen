import 'package:aaj_kya_pakayen/core/l10n/generated/app_localizations.dart';
import 'package:aaj_kya_pakayen/domain/enums/protein_type.dart';
import 'package:intl/intl.dart';

/// Localized names for domain enums and quantities.
extension Labels on AppLocalizations {
  String protein(ProteinType p) => switch (p) {
    ProteinType.chicken => proteinChicken,
    ProteinType.beef => proteinBeef,
    ProteinType.mutton => proteinMutton,
    ProteinType.mince => proteinMince,
  };

  /// "750 g" below a kilo, otherwise "1.5 kg".
  String grams(int grams) {
    if (grams < 1000) return amountGrams(grams);
    return amountKg(NumberFormat('0.##', localeName).format(grams / 1000));
  }
}
