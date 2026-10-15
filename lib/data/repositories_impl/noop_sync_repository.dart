import 'package:aaj_kya_pakayen/domain/repositories/sync_repository.dart';

/// v1 is local-only; a cloud adapter replaces this (docs/ARCHITECTURE.md).
class NoopSyncRepository implements SyncRepository {
  const new();

  @override
  Future<void> push() async {}

  @override
  Future<void> pull() async {}

  @override
  Stream<SyncStatus> watchStatus() => Stream.value(SyncStatus.idle);
}
