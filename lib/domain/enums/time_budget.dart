/// How long the cook wants to spend tonight.
enum TimeBudget {
  quick(30),
  normal(60),
  elaborate(null);

  new(this.maxMinutes);

  /// Longest prep time that fits, or `null` for no limit.
  final int? maxMinutes;

  bool allows(int prepMinutes) {
    final max = maxMinutes;
    return max == null || prepMinutes <= max;
  }
}
