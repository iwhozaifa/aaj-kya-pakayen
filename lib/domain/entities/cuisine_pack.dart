/// A set of dishes from one cuisine. Ids match `Dish.cuisine`.
enum CuisinePack {
  pakistani(isAvailable: true),
  indian,
  afghan,
  chinese;

  new({this.isAvailable = false});

  /// False for packs that are "coming soon".
  final bool isAvailable;

  String get id => name;
}
