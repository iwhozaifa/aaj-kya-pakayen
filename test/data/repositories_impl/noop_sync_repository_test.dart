import 'package:aaj_kya_pakayen/data/repositories_impl/noop_sync_repository.dart';
import 'package:aaj_kya_pakayen/domain/repositories/sync_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('does nothing and stays idle', () async {
    const repo = NoopSyncRepository();
    await repo.push();
    await repo.pull();
    expect(await repo.watchStatus().toList(), [SyncStatus.idle]);
  });
}
