import 'package:hive/hive.dart';
import 'package:mobile_stock_inventory/Model/product_model.dart';
import 'package:mobile_stock_inventory/Helper/Database/SupabaseProductServices.dart';

class ProductSync {
  final Box<Product> _productBox;
  final SupabaseProductServices _supabaseService = SupabaseProductServices();

  ProductSync(this._productBox);

  /// 🡇 Pull from Supabase, push to Hive
  Future<void> syncFromSupabase() async {
    try {
      final serverProducts = await _supabaseService.fetchProductsFromServer();

      if (serverProducts.isEmpty) {
        print("⚠️ No products fetched from Supabase.");
        return;
      }

      final serverIds = <String>{};

      for (var serverProduct in serverProducts) {
        final localProduct = _productBox.get(serverProduct.id);
        final serverTime = serverProduct.lastModified;
        final localTime = localProduct?.lastModified ?? DateTime(2000);

        if (localProduct == null || serverTime.isAfter(localTime)) {
          await _productBox.put(serverProduct.id, serverProduct);
        }

        serverIds.add(serverProduct.id);
      }

      // 🧠 Handle soft-deleting local items not found on server
      final localIds = _productBox.keys.cast<String>().toSet();
      final toDelete = localIds.difference(serverIds);

      for (final id in toDelete) {
        final product = _productBox.get(id);

        // 🛡️ Skip deleting local products that have never been synced
        final isUnsyncedLocalOnly = product?.lastModified != null &&
            (product!.createdAt == product.lastModified ||
                product.lastModified.difference(product.createdAt).inSeconds <= 5);

        if (product != null && product.deletedAt == null && !isUnsyncedLocalOnly) {
          final updated = product.copyWith(
            deletedAt: DateTime.now(),
            lastModified: DateTime.now(),
          );
          await _productBox.put(id, updated);
        }
      }

      print('☁️ Synced ${serverProducts.length} product(s) from Supabase.');
    } catch (e) {
      print('❌ Supabase sync (download) failed: $e');
    }
  }

  /// 🡅 Push from Hive to Supabase
  Future<void> syncToSupabase() async {
    try {
      final serverProducts = await _supabaseService.fetchProductsFromServer();
      final serverMap = {for (var p in serverProducts) p.id: p};

      final localProducts = _productBox.values.toList();
      final localMap = {for (var p in localProducts) p.id: p};

      final mergedProducts = <Product>[];

      for (final local in localProducts) {
        final server = serverMap[local.id];
        final localTime = local.lastModified;
        final serverTime = server?.lastModified ?? DateTime(2000);

        if (server == null || localTime.isAfter(serverTime)) {
          mergedProducts.add(local);
        }
      }

      // Add new server entries that don't exist locally and aren't deleted
      for (final server in serverProducts) {
        if (!localMap.containsKey(server.id) && server.deletedAt == null) {
          mergedProducts.add(server);
        }
      }

      if (mergedProducts.isEmpty) {
        print('ℹ️ No changes to sync. All products are up to date.');
      } else {
        await _supabaseService.upsertProductsListToServer(mergedProducts);
        print('✅ Synced ${mergedProducts.length} product(s) to Supabase.');
      }
    } catch (e) {
      print('❌ Supabase sync (upload) failed: $e');
    }
  }

  /// 🔁 Sync both ways (recommended for initial launch or manual sync)
  Future<void> autoSync() async {
    await syncToSupabase();
    await syncFromSupabase();
  }
}
