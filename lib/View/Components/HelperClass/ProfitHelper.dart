import 'package:hive/hive.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProfitHelper {
  static final profitBox = Hive.box('checkout_profits');
  static final supabase = Supabase.instance.client;

  /// Save profit locally (offline-first)
  static Future<void> saveProfit(double totalProfit) async {
    final now = DateTime.now();
    await profitBox.add({
      'profit': totalProfit,
      'timestamp': now.toIso8601String(),
      'synced': false,
    });
    print('DEBUG: Saved local profit $totalProfit');
  }

  /// Fetch profits from Supabase
  static Future<List<Map<String, dynamic>>> fetchRemoteProfits(String userId) async {
    final response = await supabase
        .from('profits')
        .select()
        .eq('user_id', userId)
        .order('timestamp');

    return List<Map<String, dynamic>>.from(response);
  }

  /// Bidirectional Sync (Local ↔ Online) Based on Timestamp
  static Future<void> syncTwoWay() async {
    print('DEBUG: Starting two-way sync...');
    final remoteProfits = await fetchRemoteProfits(supabase.auth.currentUser!.id);
    final localProfits = profitBox.values
        .cast<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();

    // Index local profits by timestamp for quick lookup
    final Map<String, Map<String, dynamic>> localProfitMap = {
      for (var profit in localProfits) profit['timestamp']: profit
    };

    // Sync each remote profit
    for (var remote in remoteProfits) {
      final timestamp = remote['timestamp'];
      final local = localProfitMap[timestamp];

      if (local == null) {
        // Remote has new data → Save locally
        await profitBox.add({
          'profit': remote['profit'],
          'timestamp': timestamp,
          'synced': true,
        });
        print('DEBUG: Downloaded profit from remote: $timestamp');
      } else {
        // Both exist → Compare profit values if needed (optional)
        print('DEBUG: Skipped existing remote profit: $timestamp');
      }
    }

    // Now upload unsynced/newer local data
    for (int i = 0; i < profitBox.length; i++) {
      final item = profitBox.getAt(i);
      if (item != null && (item['synced'] == false)) {
        try {
          await supabase.from('profits').insert({
            'user_id': supabase.auth.currentUser!.id,
            'profit': item['profit'],
            'timestamp': item['timestamp'],
          });
          await profitBox.putAt(i, {
            'profit': item['profit'],
            'timestamp': item['timestamp'],
            'synced': true,
          });
          print('DEBUG: Uploaded local profit to Supabase: ${item['timestamp']}');
        } catch (e) {
          print('DEBUG: Failed uploading local profit: $e');
        }
      }
    }

    print('DEBUG: Two-way sync complete.');
  }

  /// Clear all local profits (Hive)
  static Future<void> clearLocalProfits() async {
    await profitBox.clear();
    print('DEBUG: Cleared all local profits.');
  }

}
