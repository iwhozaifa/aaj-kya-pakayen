// freezed can't parse `new` constructors yet (docs/DECISIONS.md D-014).
// ignore_for_file: unnecessary_type_name_in_constructor

import 'package:aaj_kya_pakayen/domain/enums/day_type.dart';
import 'package:aaj_kya_pakayen/domain/enums/dinner_source.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'dinner_log_entry.freezed.dart';
part 'dinner_log_entry.g.dart';

/// What was eaten on one calendar date. [id] is null until saved.
@freezed
abstract class DinnerLogEntry with _$DinnerLogEntry {
  const factory DinnerLogEntry({
    required DateTime date,
    required DayType dayType,
    required DinnerSource source,
    int? id,
    int? mainDishId,
    int? sideDishId,
    String? outsideNote,
    @Default(true) bool wasSuggested,
    DateTime? createdAt,
  }) = _DinnerLogEntry;

  const DinnerLogEntry._();

  factory DinnerLogEntry.fromJson(Map<String, dynamic> json) =>
      _$DinnerLogEntryFromJson(json);

  bool get isOutside => source == DinnerSource.outside;

  /// Main and side dish ids, for the no-repeat rule.
  List<int> get dishIds => [?mainDishId, ?sideDishId];
}
