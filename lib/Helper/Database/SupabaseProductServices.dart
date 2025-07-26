import 'package:pocketpos/Model/product_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseProductServices {
  final _client = Supabase.instance.client;

  /// 📥 Fetch products from Supabase where each user has one row with a `data` list
  Future<List<Product>> fetchProductsFromServer() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      print('❌ No user logged in.');
      return [];
    }

    print('🔄 Fetching products for user: $userId');

    try {
      final res = await _client
          .from('products')
          .select()
          .eq('user_id', userId)
          .maybeSingle();

      if (res == null || res['data'] == null) {
        print('📦 Supabase fetched: 0 items');
        return [];
      }

      final rawData = res['data'];
      if (rawData is! List<dynamic>) {
        print('⚠️ Invalid data format from Supabase.');
        return [];
      }

      print('📦 Supabase fetched: ${rawData.length} item(s)');

      return rawData
          .whereType<Map<String, dynamic>>() // 👈 ensures type safety
          .map((item) => Product.fromMap(item))
          .where((product) => product.deletedAt == null)
          .toList();
    } catch (e) {
      print('❌ Error fetching products: $e');
      return [];
    }
  }

  /// ⬆️ Upload only products that are new or changed (based on `lastModified`)
  Future<void> upsertOnlyChangedProducts(List<Product> localProducts) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      print('❌ Cannot upsert: No user logged in.');
      return;
    }

    final serverProducts = await fetchProductsFromServer();
    final now = DateTime.now().toIso8601String();

    // Convert server list to map for faster lookup
    final serverMap = {
      for (var product in serverProducts) product.id: product,
    };

    // Filter products that are new or modified AND not permanently deleted
    final changedOrNew = localProducts.where((local) {
      final server = serverMap[local.id];
      final isChanged = server == null || local.lastModified.isAfter(server.lastModified);
      return isChanged && local.isDeletedPermanent != true;
    }).toList();

    if (changedOrNew.isEmpty) {
      print('✅ No changes to upload.');
      return;
    }

    final payload = {
      'user_id': userId,
      'data': changedOrNew.map((p) => p.toMap()).toList(),
      'updated_at': now,
    };

    print('⬆️ Uploading ${changedOrNew.length} changed product(s) to Supabase...');

    try {
      await _client
          .from('products')
          .upsert(payload, onConflict: 'user_id');
      print('✅ Upload complete!');
    } catch (e) {
      print('❌ Upload failed: $e');
    }
  }
}
