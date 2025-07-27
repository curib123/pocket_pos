import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pocketpos/Model/product_model.dart';

class SupabaseProductServices {
  final _client = Supabase.instance.client;

  /// 📥 Fetch all product rows for the current user
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

      if (res.isEmpty) {
        print('📦 Supabase fetched: 0 items');
        return [];
      }

      return res
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
    } catch (e) {
      print('❌ Error fetching products: $e');
      return [];
    }
  }

  /// ⬆️ Upsert only new or modified products
  Future<void> upsertOnlyChangedProducts(List<Product> localProducts) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      print('❌ Cannot upsert: No user logged in.');
      return;
    }

    final serverProducts = await fetchProductsFromServer();
    final serverMap = {for (final p in serverProducts) p.id: p};

    final changedOrNew = localProducts.where((local) {
      final server = serverMap[local.id];
      return (server == null || local.lastModified.isAfter(server.lastModified)) &&
          local.isDeletedPermanent != true;
    }).toList();

    final toDelete = localProducts.where((local) {
      final server = serverMap[local.id];
      return local.isDeletedPermanent == true && server != null;
    }).toList();

    if (changedOrNew.isNotEmpty) {
      final payload = changedOrNew.map((product) => {
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
        'deletedAt': product.isSoftDeleted,
        'hasVariant': product.hasVariant,
        'isVariant': product.isVariant,
        'isDeletedPermanent': product.isDeletedPermanent,
        'stocks': product.stocks.map((s) => s.toMap()).toList(),
        'logs': product.logs.map((l) => l.toMap()).toList(),
        'loans': product.loans.map((l) => l.toMap()).toList(),
        'variants': product.variants.map((v) => v.toMap()).toList(),
        'looseStock': product.looseStock?.toMap(),
      }).toList();

      print('⬆️ Uploading ${payload.length} product(s)...');
      try {
        await _client
            .from('products')
            .upsert(payload, onConflict: 'product_id'); // ✅ onConflict added here
        print('✅ Upload complete!');
      } catch (e) {
        print('❌ Upload failed: $e');
      }
    } else {
      print('✅ No products to upload.');
    }

    if (toDelete.isNotEmpty) {
      final idsToDelete = toDelete.map((p) => p.id).toList();
      print('🗑️ Deleting ${idsToDelete.length} product(s) from Supabase...');

      try {
        await _client
            .from('products')
            .delete()
            .filter('product_id', 'in', idsToDelete);
        print('✅ Permanent delete complete!');
      } catch (e) {
        print('❌ Permanent delete failed: $e');
      }
    }
  }
}
