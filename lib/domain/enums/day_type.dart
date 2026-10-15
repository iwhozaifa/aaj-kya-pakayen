/// Whether tonight is a vegetable/pulse night or a meat/chicken/outside night.
enum DayType {
  vegDay,
  nonVegDay;

  /// Days alternate: tonight is the opposite of the last logged dinner.
  DayType get flipped => switch (this) {
    DayType.vegDay => DayType.nonVegDay,
    DayType.nonVegDay => DayType.vegDay,
  };
}
