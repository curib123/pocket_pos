import 'package:pocketpos/Model/product_model.dart';
import 'package:pocketpos/Helper/Database/SupabaseProductServices.dart';

class ProductSync {
  final SupabaseProductServices _supabaseService = SupabaseProductServices();

  Future<void> autoSync(
      List<Product> localProducts,
      Future<void> Function(Product p) saveLocalProduct,
      ) async {
    try {
      final localMap = {for (final p in localProducts) p.id: p};
      final serverProducts = await _supabaseService.fetchProductsFromServer();
      final serverMap = {for (final p in serverProducts) p.id: p};

      final toUpload = <Product>[];
      final toSaveLocally = <Product>[];



      for (final local in localProducts) {
        final server = serverMap[local.id];

        if (server == null) {
          print('📤 New local product "${local.name}" not found on server. Will upload.');
          toUpload.add(local);
        } else if (local.lastModified.isAfter(server.lastModified)) {
          print('📤 Local product "${local.name}" is newer than server. Will upload.');
          toUpload.add(local);
        } else {
          // 🧠 Here we update even if timestamps are the same or server is newer
          print('📥 save locally');
          toSaveLocally.add(server);
        }
      }

      // 🧹 Handle products only on server (not in local map at all)
      for (final server in serverProducts) {
        if (!localMap.containsKey(server.id)) {
          print('📥 New server product "${server.name}" not found locally. Will download.');
          toSaveLocally.add(server);
        }
      }

      // 🔼 Upload changed/created products
      if (toUpload.isNotEmpty) {
        await _supabaseService.syncChangedProductsAndLogs(toUpload);
        print('✅ Synced ${toUpload.length} local → Supabase.');
      }

      // ⬇️ Save updated products locally
      for (final product in toSaveLocally) {
        await saveLocalProduct(product);
      }

      if (toSaveLocally.isNotEmpty) {
        print('✅ Synced ${toSaveLocally.length} Supabase → local.');
      }

      if (toUpload.isEmpty && toSaveLocally.isEmpty) {
        print('🟢 All products already in sync. No changes needed.');
      }

    } catch (e) {
      print('❌ Auto sync failed: $e');
    }
  }
}
