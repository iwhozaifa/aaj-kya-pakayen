import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'clock.g.dart';

/// "Now", overridable in tests.
@Riverpod(keepAlive: true)
DateTime Function() clock(Ref ref) => DateTime.now;
