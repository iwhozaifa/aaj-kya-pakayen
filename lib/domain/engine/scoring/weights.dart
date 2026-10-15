/// Soft-scoring weights. Hard rules filter first; these only rank.
abstract final class ScoreWeights {
  /// Per day the oldest batch of the dish's protein has waited.
  static const useItFirstPerDay = 2.0;
  static const useItFirstMaxDays = 14;
  static const proteinInStockReasonMinDays = 2;

  /// Same protein as the previous non-veg day.
  static const sameProtein = -15.0;

  /// Same cooking style as yesterday.
  static const sameStyleAsYesterday = -10.0;

  /// Style not cooked within the repeat window.
  static const freshStyle = 3.0;

  static const fitsTimeBudget = 5.0;
  static const overTimeBudget = -8.0;

  /// Per day since last cooked; never-cooked dishes get the maximum.
  static const noveltyPerDay = 0.2;
  static const noveltyMaxDays = 30;
  static const notCookedReasonMinDays = 14;

  /// Seeded random spread added to each score, so equal dishes rotate
  /// day to day.
  static const jitter = 4.0;
}
