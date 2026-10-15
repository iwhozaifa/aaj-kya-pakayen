enum SyncStatus { idle, syncing, error }

/// Future cloud sync (see docs/ARCHITECTURE.md). v1 ships a no-op.
abstract interface class SyncRepository {
  /// Uploads local changes since the last sync.
  Future<void> push();

  /// Fetches remote changes and merges them.
  Future<void> pull();

  Stream<SyncStatus> watchStatus();
}
