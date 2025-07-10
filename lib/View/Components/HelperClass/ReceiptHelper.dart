import 'package:hive/hive.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ReceiptHelper {
  final _supabase = Supabase.instance.client;

  // Access the already opened Hive box
  Box<Map> get _box => Hive.box<Map>('receipts');

  /// Adds a new receipt, saves it locally, then automatically syncs it online
  Future<void> addReceipt({
    required String title,
    required double amount,
    required DateTime date,
    String? note,
  }) async {
    final receiptData = {
      'title': title,
      'amount': amount,
      'date': date.toIso8601String(),
      'note': note ?? '',
    };

    print('🧾 Adding receipt: $receiptData');
    await saveReceiptLocally(receiptData);
    await syncReceipts(); // Automatically sync after saving
  }

  /// Save a new or updated receipt locally (marked as unsynced)
  Future<void> saveReceiptLocally(Map<String, dynamic> receiptData) async {
    final id = receiptData['id'] ?? DateTime.now().millisecondsSinceEpoch.toString();
    final now = DateTime.now().toUtc().toIso8601String();

    final receipt = {
      'id': id,
      'data': receiptData,
      'lastModified': now,
      'isSynced': false,
    };

    print('💾 Saving receipt locally: $receipt');
    await _box.put(id, receipt);
  }

  /// Sync receipts: Local → Online & Online → Local
  Future<void> syncReceipts() async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      print('⚠️ No user signed in. Cannot sync receipts.');
      return;
    }

    print('🔄 Starting sync for user: ${user.id}');

    // Step 1: Upload unsynced local receipts to Supabase
    for (var receipt in _box.values) {
      final isSynced = receipt['isSynced'] ?? false;
      final id = receipt['id'];
      final lastModified = receipt['lastModified'];

      if (!isSynced && id != null && lastModified != null) {
        print('⬆️ Uploading unsynced receipt to Supabase: ID $id');
        await _supabase.from('receipts').upsert({
          'id': id,
          'user_id': user.id,
          'data': receipt['data'],
          'last_modified': lastModified,
        });

        receipt['isSynced'] = true;
        await _box.put(id, receipt);
        print('✅ Marked receipt as synced: ID $id');
      }
    }

    // Step 2: Pull latest from Supabase
    final remoteReceipts = await _supabase
        .from('receipts')
        .select()
        .eq('user_id', user.id);

    print('⬇️ Fetched ${remoteReceipts.length} receipts from Supabase');

    for (final remote in remoteReceipts) {
      final remoteId = remote['id'];
      final remoteModifiedStr = remote['last_modified'];
      final remoteModified = DateTime.tryParse(remoteModifiedStr ?? '');
      if (remoteId == null || remoteModified == null) continue;

      final local = _box.get(remoteId);

      if (local == null) {
        print('➕ Adding new remote receipt to local box: ID $remoteId');
        await _box.put(remoteId, {
          'id': remoteId,
          'data': remote['data'],
          'lastModified': remoteModifiedStr,
          'isSynced': true,
        });
      } else {
        final localModified = DateTime.tryParse(local['lastModified'] ?? '');
        if (localModified == null || remoteModified.isAfter(localModified)) {
          print('🔁 Updating local receipt with remote version: ID $remoteId');
          await _box.put(remoteId, {
            'id': remoteId,
            'data': remote['data'],
            'lastModified': remoteModifiedStr,
            'isSynced': true,
          });
        }
      }
    }

    print('✅ Sync complete.');
  }

  /// Retrieve all local receipts
  Future<List<Map<String, dynamic>>> getAllLocalReceipts() async {
    final receipts = _box.values.map((e) => e['data'] as Map<String, dynamic>).toList();
    print('📃 Retrieved ${receipts.length} local receipts.');
    return receipts;
  }
}
