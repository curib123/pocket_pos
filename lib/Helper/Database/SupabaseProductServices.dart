import 'package:mobile_pos_inventory/Model/product_model.dart';
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
      if (rawData is! List) {
        print('⚠️ Invalid data format from Supabase.');
        return [];
      }

      print('📦 Supabase fetched: ${rawData.length} item(s)');

      return rawData
          .map((item) => Product.fromMap(item as Map<String, dynamic>))
          .where((product) => product.deletedAt == null)
          .toList();
    } catch (e) {
      print('❌ Error fetching products: $e');
      return [];
    }
  }

  /// ⬆️ Upsert full list of products into a single row for this user
  Future<void> upsertProductsListToServer(List<Product> products) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      print('❌ Cannot upsert: No user logged in.');
      return;
    }

    final now = DateTime.now().toIso8601String();

    final payload = {
      'user_id': userId,
      'data': products.map((p) => p.toMap()).toList(),
      'updated_at': now,
    };

    print('⬆️ Uploading ${products.length} product(s) to Supabase...');

    try {
      await _client
          .from('products')
          .upsert(payload, onConflict: 'user_id');

      print('✅ Upload complete!');
    } catch (e) {
      print('❌ Upload failed: $e');
    }
  }

  /// 🗑 Soft delete all products (clear product list on server)
  Future<void> deleteAllProductsFromServer() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      print('❌ Cannot delete: No user logged in.');
      return;
    }

    try {
      await _client.from('products').upsert({
        'user_id': userId,
        'data': [],
        'updated_at': DateTime.now().toIso8601String(),
      });

      print('🗑 All products cleared for user $userId');
    } catch (e) {
      print('❌ Failed to clear products: $e');
    }
  }

  /// ❌ Soft delete a single product by setting its `deletedAt` and `lastModified`
  Future<void> softDeleteProductFromServer(String productId) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      print('❌ Cannot soft delete: No user logged in.');
      return;
    }

    try {
      final res = await _client
          .from('products')
          .select()
          .eq('user_id', userId)
          .maybeSingle();

      final rawData = res?['data'];
      if (rawData == null || rawData is! List) {
        print('❌ No product list found for user.');
        return;
      }

      final productList = rawData
          .map((item) => Product.fromMap(item as Map<String, dynamic>))
          .toList();

      final updatedList = productList.map((product) {
        if (product.id == productId) {
          return product.copyWith(
            deletedAt: DateTime.now(),
            lastModified: DateTime.now(),
          );
        }
        return product;
      }).toList();

      await upsertProductsListToServer(updatedList);
      print('🗑 Soft-deleted product $productId for user $userId');
    } catch (e) {
      print('❌ Soft delete failed: $e');
    }
  }
}
