import 'package:flutter/cupertino.dart';
import 'package:hive/hive.dart';
import 'package:pocketpos/Model/product_model.dart';
import 'package:pocketpos/Helper/Database/SupabaseProductServices.dart';

class ProductSync {
  final Box<Product> _productBox;
  final SupabaseProductServices _supabaseService = SupabaseProductServices();

  ProductSync(this._productBox);


  /// ⬆️ Save a list of products directly to Supabase (bypasses sync logic)
  Future<bool> HardDeleteProductByID(String productId) async {
    try {
      await _supabaseService.hardDeleteProductFromServer(productId);
      return true;
    } catch (e) {
      print('❌ HardDeleteProductByID failed: $e');
      return false;
    }
  }

  /// 🡇 Pull from Supabase, push to Hive
  Future<void> syncFromSupabase(BuildContext context) async {
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
  Future<void> syncToSupabase(BuildContext context) async {
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

      for (final server in serverProducts) {
        if (!localMap.containsKey(server.id) && server.deletedAt == null) {
          mergedProducts.add(server);
        }
      }

      if (mergedProducts.isEmpty) {
        print('ℹ️ No changes to sync. All products are up to date.');
      } else {
        await _supabaseService.upsertProductsListToServer(mergedProducts, );
        print('✅ Synced ${mergedProducts.length} product(s) to Supabase.');
      }
    } catch (e) {
      print('❌ Supabase sync (upload) failed: $e');
    }
  }

  /// 🔁 Full sync (push, pull, and image sync)
  Future<void> autoSync(BuildContext context) async {
    await syncToSupabase(context);
    await syncFromSupabase(context);
  }
}
