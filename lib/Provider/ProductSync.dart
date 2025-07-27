import 'package:hive/hive.dart';
import 'package:pocketpos/Model/product_model.dart';
import 'package:pocketpos/Helper/Database/SupabaseProductServices.dart';

class ProductSync {
  final Box<Product> _productBox;
  final SupabaseProductServices _supabaseService = SupabaseProductServices();

  ProductSync(this._productBox);

  Future<void> autoSync() async {
    try {
      final serverProducts = await _supabaseService.fetchProductsFromServer();
      final localProducts = _productBox.values.toList();

      final serverMap = {for (var p in serverProducts) p.id: p};
      final localMap = {for (var p in localProducts) p.id: p};

      final updatedToServer = <Product>[];
      final updatedToLocal = <Product>{};
      final allIds = {...serverMap.keys, ...localMap.keys};

      for (final id in allIds) {
        final server = serverMap[id];
        final local = localMap[id];

        final serverTime = server?.lastModified ?? DateTime(2000);
        final localTime = local?.lastModified ?? DateTime(2000);

        if (server != null && local != null) {
          if (localTime.isAfter(serverTime)) {
            // ✅ Local is newer → upload to server
            updatedToServer.add(local);
          } else if (serverTime.isAfter(localTime)) {
            // ⬇️ Server is newer → overwrite local
            updatedToLocal.add(server);
          } else {
            // ⏸️ Both same → do nothing
            // print('⏸️ Skipping sync for $id — same timestamp');
          }
        } else if (server != null) {
          // 📥 Server-only entry
          updatedToLocal.add(server);
        } else if (local != null) {
          // 📤 Local-only entry
          updatedToServer.add(local);
        }
      }

      // ✅ Save server-updated products to Hive
      for (final product in updatedToLocal) {
        await _productBox.put(product.id, product);
      }

      // ⬆️ Push local-updated products to Supabase
      if (updatedToServer.isNotEmpty) {
        await _supabaseService.upsertOnlyChangedProducts(updatedToServer);
      }

      print('🔁 Synced: ${updatedToLocal.length} from server → local, ${updatedToServer.length} from local → server.');

      // 🚫 Skipping soft-delete of local-only products
      final serverIds = serverMap.keys.toSet();
      final localIds = _productBox.keys.cast<String>().toSet();
      final toKeepLocal = localIds.difference(serverIds);

      for (final id in toKeepLocal) {
        final product = _productBox.get(id);
        if (product != null && !product.isSoftDeleted) {
          print("🛡️ Keeping local-only product: ${product.name} (${product.id})");
        }
      }

    } catch (e) {
      print('❌ Auto sync failed: $e');
    }
  }

}
