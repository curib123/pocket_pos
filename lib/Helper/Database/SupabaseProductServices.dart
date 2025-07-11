import 'package:mobile_pos_inventory/Model/product_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseProductServices {
  final _client = Supabase.instance.client;

  // Fetch all products for current user
  Future<List<Product>> fetchProductsFromServer() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      print('❌ No user logged in.');
      return [];
    }

    print('🔄 Fetching products for user: $userId');

    final res = await _client
        .from('products')
        .select()
        .eq('user_id', userId)
        .order('updated_at', ascending: false);

    print('📦 Supabase fetched: ${res.length} items');

    return (res as List)
        .map((item) => Product.fromJson(item['data'] as Map<String, dynamic>))
        .toList();
  }

  // Upsert a product into Supabase
  Future<void> upsertProductToServer(Product product) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      print('❌ Cannot upsert: No user logged in.');
      return;
    }

    final payload = {
      'id': product.id,
      'user_id': userId,
      'data': product.toJson(),
      'updated_at':
      product.updatedAt?.toIso8601String() ?? DateTime.now().toIso8601String(),
    };

    print('⬆️ Uploading product: ${product.name}');
    await _client.from('products').upsert(payload);
    print('✅ Product uploaded: ${product.id}');
  }
}
