import 'package:hive/hive.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProfitHelper {
  static final profitBox = Hive.box('checkout_profits');
  static final supabase = Supabase.instance.client;

  /// Save profit locally (offline-first)
  static Future<void> saveProfit(double totalProfit, List<Map<String, dynamic>> items) async {
    final now = DateTime.now();
    await profitBox.add({
      'profit': totalProfit,
      'items': items,
      'timestamp': now.toIso8601String(),
      'synced': false,
    });
    print('DEBUG: Saved local profit $totalProfit with items');
  }

  /// Fetch profits from Supabase
  static Future<List<Map<String, dynamic>>> fetchRemoteProfits(String userId) async {
    try {
      final response = await supabase
          .from('profits')
          .select()
          .eq('user_id', userId)
          .order('timestamp');
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('DEBUG: Failed fetching remote profits: $e');
      return [];
    }
  }

  /// Bidirectional Sync (Local ↔ Online) Based on Timestamp
  static Future<void> syncTwoWay() async {
    print('DEBUG: Starting two-way sync...');
    final userId = supabase.auth.currentUser!.id;
    final remoteProfits = await fetchRemoteProfits(userId);
    final localProfits = profitBox.values
        .cast<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();

    // Index local profits by timestamp
    final Map<String, Map<String, dynamic>> localProfitMap = {
      for (var profit in localProfits) profit['timestamp']: profit
    };

    // Sync remote to local
    for (var remote in remoteProfits) {
      final timestamp = remote['timestamp'];
      final local = localProfitMap[timestamp];

      if (local == null) {
        await profitBox.add({
          'profit': remote['profit'],
          'items': remote['items'] ?? [],
          'timestamp': timestamp,
          'synced': true,
        });
        print('DEBUG: Downloaded profit from remote: $timestamp');
      } else {
        print('DEBUG: Skipped existing remote profit: $timestamp');
      }
    }

    // Sync local to remote
    for (int i = 0; i < profitBox.length; i++) {
      final item = profitBox.getAt(i);
      if (item != null && (item['synced'] == false)) {
        try {
          await supabase.from('profits').insert({
            'user_id': userId,
            'profit': item['profit'],
            'items': item['items'] ?? [],
            'timestamp': item['timestamp'],
          });
          await profitBox.putAt(i, {
            'profit': item['profit'],
            'items': item['items'],
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
