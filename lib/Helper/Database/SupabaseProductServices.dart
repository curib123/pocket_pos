import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pocketpos/Model/product_model.dart';

class SupabaseProductServices {
  final _client = Supabase.instance.client;

  /// 📥 Fetch all product rows for the current user (excluding permanently deleted)
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
          .eq('user_id', userId);

      final rawList = res as List<dynamic>;

      if (rawList.isEmpty) {
        print('📦 Supabase fetched: 0 products');
        return [];
      }

      final products = rawList
          .whereType<Map<String, dynamic>>()
          .map((data) {
        return Product.fromMap({
          ...data,
          'stocks': data['stocks'] ?? [],
          'logs': data['logs'] ?? [],
          'loans': data['loans'] ?? [],
          'variants': data['variants'] ?? [],
          'looseStock': data['looseStock'],
        });
      })
          .where((product) => !product.isDeletedPermanent)
          .toList();

      print('📦 Supabase fetched: ${products.length} product(s)');
      return products;
    } catch (e) {
      print('❌ Error fetching products: $e');
      return [];
    }
  }

  /// ⬆️ Upsert only new or modified products
  Future<void> upsertOnlyChangedProducts(List<Product> productsToUpload) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      print('❌ Cannot upsert: No user logged in.');
      return;
    }

    if (productsToUpload.isEmpty) {
      print('🟢 No products to upload — already up-to-date.');
      return;
    }

    final payload = productsToUpload.map((product) => {
      'id': product.id,
      'user_id': userId,
      'name': product.name,
      'category': product.category,
      'isSoldByPack': product.isSoldByPack,
      'isSoldByPiece': product.isSoldByPiece,
      'piecesPerPack': product.piecesPerPack,
      'unit': product.unit,
      'imagePath': product.imagePath,
      'barcode': product.barcode,
      'createdAt': product.createdAt.toIso8601String(),
      'lastModified': product.lastModified.toIso8601String(),
      'isSoftDeleted': product.isSoftDeleted,
      'hasVariant': product.hasVariant,
      'isVariant': product.isVariant,
      'isDeletedPermanent': product.isDeletedPermanent,
      'stocks': product.stocks.map((s) => s.toMap()).toList(),
      'logs': product.logs.map((l) => l.toMap()).toList(),
      'loans': product.loans.map((l) => l.toMap()).toList(),
      'variants': product.variants.map((v) => v.toMap()).toList(),
      'looseStock': product.looseStock?.toMap(),
    }).toList();

    print('⬆️ Uploading ${payload.length} product(s) to Supabase...');
    try {
      await _client.from('products').upsert(payload, onConflict: 'id');
      print('✅ Upload complete!');
    } catch (e) {
      print('❌ Upload failed: $e');
    }
  }
}
