import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pocketpos/Model/product_model.dart';
import 'package:pocketpos/Model/stock_log.dart';

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
      // Fetch all products
      final productRes = await _client
          .from('products')
          .select()
          .eq('user_id', userId);

      if (productRes.isEmpty) {
        print('📦 Supabase fetched: 0 products');
        return [];
      }

      // Fetch all logs once
      final logRes = await _client
          .from('product_logs')
          .select();

      final allLogs = logRes
          .whereType<Map<String, dynamic>>()
          .map((e) => StockLog.fromMap(e))
          .toList();

      // Group logs by productId
      final logsByProduct = <String, List<StockLog>>{};
      for (final log in allLogs) {
        logsByProduct.putIfAbsent(log.productId, () => []).add(log);
      }

      // Map each product and attach its logs
      final List<Product> products = productRes
          .whereType<Map<String, dynamic>>()
          .where((data) => !(data['isDeletedPermanent'] ?? false))
          .map((data) {
        final productId = data['id'] as String;
        final logs = logsByProduct[productId] ?? [];

        return Product.fromMap({
          ...data,
          'stocks': data['stocks'] ?? [],
          'logs': logs.map((l) => l.toMap()).toList(),
          'loans': data['loans'] ?? [],
          'variants': data['variants'] ?? [],
          'looseStock': data['looseStock'],
        });
      }).toList();

      print('📦 Supabase fetched: ${products.length} product(s) with logs');
      return products;
    } catch (e) {
      print('❌ Error fetching products: $e');
      return [];
    }
  }

  /// ⬆️ Upsert only new or modified products (logs handled separately)
  Future<void> syncChangedProductsAndLogs(List<Product> allProducts) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      print('❌ Cannot sync: No user logged in.');
      return;
    }

    final productsToUpload =
    allProducts.where((p) => !p.isDeletedPermanent).toList();

    if (productsToUpload.isEmpty) {
      print('🟢 No products to sync — already up-to-date.');
      return;
    }

    final productPayload = productsToUpload.map((product) => {
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
      'loans': product.loans.map((l) => l.toMap()).toList(),
      'variants': product.variants.map((v) => v.toMap()).toList(),
      'looseStock': product.looseStock?.toMap(),
    }).toList();

    print('⬆️ Uploading ${productPayload.length} product(s) to Supabase...');
    try {
      await _client.from('products').upsert(productPayload, onConflict: 'id');
      print('✅ Products uploaded successfully!');
    } catch (e) {
      print('❌ Product upload failed: $e');
      return;
    }

    // 🪵 Upload logs per product
    for (final product in productsToUpload) {
      final logs = product.logs.where((log) => log.id.isNotEmpty).toList();
      if (logs.isEmpty) continue;

      final logPayload = logs.map((log) => {
        'id': log.id,
        'product_id': product.id,
        'quantity': log.quantity,
        'isPiece': log.isPiece ?? false,
        'profit': log.profit ?? 0.0,
        'reason': log.reason.name,
        'remarks': log.remarks ?? '',
        'dateLogged': log.dateLogged.toIso8601String(),
        'lastModified': log.lastModified.toIso8601String(),
        'deletedAt': log.deletedAt?.toIso8601String() ?? '',
      }).toList();

      try {
        for (final chunk in _chunkList(logPayload, 50)) {
          await _client.from('product_logs').upsert(chunk, onConflict: 'id');
        }
        print('📤 Logs uploaded for product ${product.name}');
      } catch (e) {
        print('❌ Failed to upload logs for ${product.name}: $e');
      }
    }

    print('🎉 Sync complete!');
  }

  /// 🧩 Internal helper for chunking large lists
  List<List<T>> _chunkList<T>(List<T> list, int chunkSize) {
    final chunks = <List<T>>[];
    for (var i = 0; i < list.length; i += chunkSize) {
      final end = (i + chunkSize < list.length) ? i + chunkSize : list.length;
      chunks.add(list.sublist(i, end));
    }
    return chunks;
  }
}
