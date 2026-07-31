import '../data/offline_database.dart';

typedef SyncUpload = Future<void> Function(Map<String, Object?> item);

/// Uploads the durable outbox when a future cloud adapter is available.
/// The callback keeps SQLite independent of Supabase, REST, or another backend.
class OfflineSyncEngine {
  OfflineSyncEngine({OfflineDatabase? database})
    : database = database ?? OfflineDatabase.instance;

  final OfflineDatabase database;

  Future<int> flush(SyncUpload upload, {int limit = 100}) async {
    var uploaded = 0;
    final items = await database.pendingSync(limit: limit);
    for (final item in items) {
      final id = item['id'] as int;
      try {
        await upload(item);
        await database.removeSyncItem(id);
        uploaded++;
      } catch (error) {
        await database.markSyncAttempt(id, error: error.toString());
      }
    }
    return uploaded;
  }
}
