import 'package:aaj_kya_pakayen/core/l10n/generated/app_localizations.dart';
import 'package:aaj_kya_pakayen/domain/engine/reason.dart';
import 'package:aaj_kya_pakayen/domain/entities/dish.dart';
import 'package:aaj_kya_pakayen/domain/enums/cooking_style.dart';
import 'package:aaj_kya_pakayen/domain/enums/day_type.dart';
import 'package:aaj_kya_pakayen/domain/enums/dish_type.dart';
import 'package:aaj_kya_pakayen/domain/enums/protein_type.dart';
import 'package:aaj_kya_pakayen/domain/enums/staple_pairing.dart';
import 'package:intl/intl.dart';

/// Localized names for domain values. The domain holds no UI strings.
extension Labels on AppLocalizations {
  String protein(ProteinType p) => switch (p) {
    ProteinType.chicken => proteinChicken,
    ProteinType.beef => proteinBeef,
    ProteinType.mutton => proteinMutton,
    ProteinType.mince => proteinMince,
  };

  /// Protein name inside a sentence ("Not beef again").
  String proteinInline(ProteinType p) => protein(p).toLowerCase();

  /// "750 g" below a kilo, otherwise "1.5 kg".
  String grams(int grams) {
    if (grams < 1000) return amountGrams(grams);
    return amountKg(NumberFormat('0.##', localeName).format(grams / 1000));
  }

  String dishName(Dish dish) => localeName == 'ur' ? dish.nameUr : dish.nameEn;

  String dayType(DayType type) => switch (type) {
    DayType.vegDay => vegDay,
    DayType.nonVegDay => nonVegDay,
  };

  String dishType(DishType type) => switch (type) {
    DishType.vegetable => dishTypeVegetable,
    DishType.pulse => dishTypePulse,
    _ => protein(type.proteinType!),
  };

  String staple(StaplePairing staple) => switch (staple) {
    StaplePairing.rice => stapleRice,
    StaplePairing.roti => stapleRoti,
    StaplePairing.either => stapleEither,
    StaplePairing.none => stapleNone,
  };

  String style(CookingStyle style) => switch (style) {
    CookingStyle.karahi => styleKarahi,
    CookingStyle.curry => styleCurry,
    CookingStyle.bbq => styleBbq,
    CookingStyle.roast => styleRoast,
    CookingStyle.fry => styleFry,
    CookingStyle.stew => styleStew,
    CookingStyle.riceDish => styleRiceDish,
    CookingStyle.other => styleOther,
  };

  /// "a", "a or b", "a, b or c".
  String orList(List<String> items) => switch (items) {
    [] => '',
    [final only] => only,
    [...final rest, final last] => listOr(rest.join(listSeparator), last),
  };

  String reason(Reason reason) => switch (reason) {
    ProteinInStockReason(:final protein, :final days) => reasonProteinInStock(
      this.protein(protein),
      days,
    ),
    DifferentProteinReason(:final previous) => reasonDifferentProtein(
      proteinInline(previous),
    ),
    FreshStyleReason(:final style) => reasonFreshStyle(this.style(style)),
    FitsTimeReason(:final minutes) => reasonFitsTime(minutes),
    ServedWithReason(:final staple) => switch (staple) {
      StaplePairing.rice => reasonServedRice,
      StaplePairing.roti => reasonServedRoti,
      StaplePairing.either || StaplePairing.none => reasonServedEither,
    },
    NotCookedForReason(:final days) => reasonNotCookedFor(days),
    RestockReason(:final proteins) =>
      proteins.isEmpty
          ? reasonRestockAny
          : reasonRestock(
              orList([
                for (final p in ProteinType.values)
                  if (proteins.contains(p)) proteinInline(p),
              ]),
            ),
  };
}
