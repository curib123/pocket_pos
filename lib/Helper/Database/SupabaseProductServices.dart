import 'package:mobile_pos_inventory/Model/product_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseProductServices {
  final _client = Supabase.instance.client;

  /// Fetch all products from Supabase (stored as a list in one row per user)
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

      final dataList = res['data'] as List;
      print('📦 Supabase fetched: ${dataList.length} items');

      return dataList
          .map((item) => Product.fromMap(item as Map<String, dynamic>))
          .where((product) => product.deletedAt == null)
          .toList();
    } catch (e) {
      print('❌ Error fetching products: $e');
      return [];
    }
  }

  /// Upsert all products as a single JSON list under one user_id row
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

    print('⬆️ Uploading full product list to Supabase...');
    try {
      await _client
          .from('products')
          .upsert(payload, onConflict: 'user_id');

      print('✅ Upload complete!');
    } catch (e) {
      print('❌ Upload failed: $e');
    }
  }



  /// Clear user’s products (soft delete all by setting data = empty list)
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

  /// Soft delete a product by marking its deletedAt timestamp
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

      if (res == null || res['data'] == null) {
        print('❌ Failed to fetch product list for soft delete.');
        return;
      }

      final dataList = (res['data'] as List)
          .map((item) => Product.fromMap(item))
          .toList();

      final updatedList = dataList.map((product) {
        if (product.id == productId) {
          product.deletedAt = DateTime.now();
          product.lastModified = DateTime.now();
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
