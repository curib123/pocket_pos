import 'package:pocketpos/Helper/Database/ProductImageHelper.dart';
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

      final updatedProducts = <Product>[];

      for (final product in products) {
        final imagePath = product.imagePath;

        if (imagePath == null) {
          updatedProducts.add(product);
          continue;
        }
        try {
          final resolvedPath = await ProductImageHelper.downloadImage(
            url: ProductImageHelper.getAccessibleImageUrl(ProductImageHelper.getStoragePath(userId, product.name)),
          );

          if (resolvedPath != null) {
            final updatedProduct = product.copyWith(imagePath: resolvedPath);
            updatedProducts.add(updatedProduct);
            print("📥 Downloaded image for ${product.name}");
            continue;
          }
        } catch (e) {
          print("❌ Error downloading image for ${product.name}: $e");
        }

        updatedProducts.add(product); // fallback if download fails
      }


      print('📦 Supabase fetched: ${products.length} product(s) with logs');
      return products;
    } catch (e) {
      print('❌ Error fetching products: $e');
      return [];
    }
  }

  Future<List<String>> fetchAllProductAndVariantNames() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      print('❌ No user logged in.');
      return [];
    }

    try {
      print('🔍 Fetching product and variant names for $userId');

      final productRes = await _client
          .from('products')
          .select('name, variants')
          .eq('user_id', userId)
          .eq('isDeletedPermanent', false);

      final names = <String>{};

      for (final item in productRes) {
        final productName = item['name'] as String?;
        final variantList = item['variants'] as List<dynamic>?;

        if (productName != null) {
          names.add(productName);
        }

        if (variantList != null) {
          for (final variant in variantList) {
            final variantName = variant['name'];
            if (variantName is String && variantName.isNotEmpty) {
              names.add(variantName);
            }
          }
        }
      }

      print('📦 Fetched ${names.length} names (products + variants)');
      return names.toList();
    } catch (e) {
      print('❌ Failed to fetch names: $e');
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

    final productsToUpload = allProducts.where((p) => !p.isDeletedPermanent).toList();

    if (productsToUpload.isEmpty) {
      print('🟢 No products to sync — already up-to-date.');
      return;
    }

    // 📦 Map to store updated image paths
    final updatedImagePaths = <String, String>{};

// 📸 Upload and inject image paths
    for (final product in productsToUpload) {
      final localImagePath = product.imagePath;

      // Upload only if local image path exists and it's not already a Supabase URL
      final isLocal = localImagePath != null && !localImagePath.startsWith('https://');

      if (isLocal) {
        final uploadedStoragePath = await ProductImageHelper.uploadCompressedImageFromPath(
          imagePath: localImagePath,
          userId: userId,
          productName: product.name,
        );

        if (uploadedStoragePath != null) {
          final publicUrl = await ProductImageHelper.downloadImage(url: ProductImageHelper.getAccessibleImageUrl(uploadedStoragePath));
          updatedImagePaths[product.id] = publicUrl ?? product.imagePath.toString();
          print("🖼️ Uploaded and linked image for ${product.name}");
        } else {
          print("⚠️ Failed to upload image for ${product.name}, keeping local path.");
        }

      }
    }

// 🛠️ Build the payload for upload (or sync)
    final productPayload = productsToUpload.map((product) => {
      'id': product.id,
      'user_id': userId,
      'name': product.name,
      'category': product.category,
      'isSoldByPack': product.isSoldByPack,
      'isSoldByPiece': product.isSoldByPiece,
      'piecesPerPack': product.piecesPerPack,
      'unit': product.unit,
      'imagePath': updatedImagePaths[product.id] ?? product.imagePath,
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


    // ⬆️ Upload
    print('⬆️ Uploading ${productPayload.length} product(s) to Supabase...');
    try {
      await _client.from('products').upsert(productPayload, onConflict: 'id');
      print('✅ Products uploaded successfully!');
    } catch (e) {
      print('❌ Product upload failed: $e');
      return;
    }

    try {
      final productNames = await fetchAllProductAndVariantNames();
      final deletedImages = await ProductImageHelper.deleteOrphanedProductImages(
        userId: userId,
        productNames: productNames,
      );
      if (deletedImages.isNotEmpty) {
        print("✅ Cleanup complete. Deleted: ${deletedImages.length} image(s).");
      }
    } catch (e, stack) {
      print("⚠️ Failed to delete orphaned images: $e\n$stack");
    }

    // 🪵 Sync logs
    for (final product in productsToUpload) {
      final logs = product.logs.where((log) => log.id.isNotEmpty).toList();
      if (logs.isEmpty) continue;

      try {
        final existingLogRes = await _client
            .from('product_logs')
            .select('id, dateLogged')
            .eq('product_id', product.id);

        final existingLogIds = <String>{};
        final existingLogDates = <DateTime>[];

        for (final entry in existingLogRes) {
          final logId = entry['id'] as String?;
          final dateLogged = DateTime.tryParse(entry['dateLogged'] ?? '');
          if (logId != null) existingLogIds.add(logId);
          if (dateLogged != null) existingLogDates.add(dateLogged);
        }

        final latestDateLogged = existingLogDates.isEmpty
            ? DateTime.fromMillisecondsSinceEpoch(0)
            : existingLogDates.reduce((a, b) => a.isAfter(b) ? a : b);

        final newLogs = logs.where((log) =>
        !existingLogIds.contains(log.id) && log.dateLogged.isAfter(latestDateLogged)
        ).toList();

        if (newLogs.isEmpty) continue;

        final newLogPayload = newLogs.map((log) => {
          'id': log.id,
          'product_id': product.id,
          'quantity': log.quantity,
          'isPiece': log.isPiece,
          'profit': log.profit ?? 0.0,
          'reason': log.reason.name,
          'remarks': log.remarks ?? '',
          'dateLogged': log.dateLogged.toIso8601String(),
          'lastModified': log.lastModified.toIso8601String(),
          'deletedAt': log.deletedAt?.toIso8601String() ?? '',
        }).toList();

        for (final chunk in _chunkList(newLogPayload, 50)) {
          await _client.from('product_logs').insert(chunk);
        }

        print('📤 ${newLogs.length} new logs added for ${product.name}');
      } catch (e) {
        print('❌ Log sync failed for ${product.name}: $e');
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
