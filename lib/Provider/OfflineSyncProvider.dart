import 'package:flutter/foundation.dart';
import '../core/sync/offline_sync_engine.dart';

class OfflineSyncProvider extends ChangeNotifier {
  OfflineSyncProvider({OfflineSyncEngine? engine})
    : engine = engine ?? OfflineSyncEngine();

  final OfflineSyncEngine engine;
  bool isSyncing = false;
  int lastUploaded = 0;
  String? lastError;

  Future<int> sync(SyncUpload upload) async {
    if (isSyncing) return 0;
    isSyncing = true;
    lastError = null;
    notifyListeners();
    try {
      lastUploaded = await engine.flush(upload);
      return lastUploaded;
    } catch (error) {
      lastError = error.toString();
      rethrow;
    } finally {
      isSyncing = false;
      notifyListeners();
    }
  }
}
