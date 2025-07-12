import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:mobile_pos_inventory/Helper/Database/SupabaseProductServices.dart';
import 'package:mobile_pos_inventory/Model/product_model.dart';
import 'package:mobile_pos_inventory/Model/batch_model.dart';
import 'package:mobile_pos_inventory/View/Components/SnackbarService.dart';

class ProductProvider extends ChangeNotifier {
  final Box<Product> _productBox;
  final SupabaseProductServices _supabaseService = SupabaseProductServices();
  List<Product> _products = [];
  List<Product> get products => _products;


  ProductProvider(this._productBox) {
    initializeProducts();
  }

  Future<void> initializeProducts() async {
    try {
      if (_productBox.isEmpty) {
        print("📦 Hive is empty. Attempting to sync from Supabase.");
        await syncFromSupabase();
      } else {
        print("📦 Loading products from Hive.");
        refreshProducts();
      }
    } catch (e) {
      print("⚠️ Failed to initialize from Supabase. Using local Hive data.");
      refreshProducts();
    }
  }

  void refreshProducts() {
    print("🟡 Hive product count: ${_productBox.length}");

    _products = _productBox.values
        .where((p) => p.deletedAt == null)
        .map((product) {
      product.batches.removeWhere((batch) => batch.quantity == 0);
      product.save(); // Persist the changes to Hive
      return product;
    })
        .toList();

    print("🟢 Active products after filter: ${_products.length}");
    notifyListeners();
  }


  List<Product> getProductsByCategory(String category) =>
      _products.where((product) => product.category == category).toList();

  Product? getProductById(String id) => _productBox.get(id);

  Product? getProductByName(String name) {
    try {
      return _products.firstWhere(
            (p) => p.name.trim().toLowerCase() == name.trim().toLowerCase(),
      );
    } catch (_) {
      return null;
    }
  }

  List<Product> search(String keyword) => _products
      .where((p) => p.name.toLowerCase().contains(keyword.toLowerCase()))
      .toList();

  List<Map<String, dynamic>> exportToJsonList() =>
      _products.map((p) => p.toMap()).toList();

  Future<void> addProduct(Product product) async {
    try {
      final nameExists = _products.any(
            (p) =>
        p.name.trim().toLowerCase() == product.name.trim().toLowerCase() &&
            p.deletedAt == null,
      );
      if (nameExists) {
        SnackbarService.showWarning('⚠️ Product already exists: ${product.name}');
        return;
      }

      product.lastModified = DateTime.now();
      await _productBox.put(product.id, product);
      if (!_products.any((p) => p.id == product.id)) {
        _products.add(product);
      }
      notifyListeners();
      SnackbarService.showSuccess('✅ Product added: ${product.name}');
      await autoSyncProducts();
    } catch (e) {
      SnackbarService.showError('❌ Failed to add product: $e');
    }
  }

  Future<void> updateProduct(Product product) async {
    try {
      product.lastModified = DateTime.now();
      await _productBox.put(product.id, product);
      final index = _products.indexWhere((p) => p.id == product.id);
      if (index != -1) {
        _products[index] = product;
        notifyListeners();
        SnackbarService.showSuccess('✅ Product updated: ${product.name}');
        await autoSyncProducts();
      }
    } catch (e) {
      SnackbarService.showError('❌ Failed to update product: $e');
    }
  }

  Future<void> deleteProduct(String id) async {
    try {
      final product = _productBox.get(id);
      if (product != null) {
        product.deletedAt = DateTime.now();
        product.lastModified = DateTime.now();
        await product.save();
        _products.removeWhere((p) => p.id == id);
        notifyListeners();
        SnackbarService.showSuccess('🗑️ Product deleted: ${product.name}');
        await autoSyncProducts();
      }
    } catch (e) {
      SnackbarService.showError('❌ Failed to delete product: $e');
    }
  }

  Future<void> restoreProduct(String id) async {
    try {
      final product = _productBox.get(id);
      if (product != null && product.deletedAt != null) {
        product.deletedAt = null;
        product.lastModified = DateTime.now();
        await product.save();
        _products.add(product);
        notifyListeners();
        SnackbarService.showSuccess('✅ Product restored: ${product.name}');
        await autoSyncProducts();
      }
    } catch (e) {
      SnackbarService.showError('❌ Failed to restore product: $e');
    }
  }

  Future<void> syncFromSupabase() async {
    try {
      final serverProducts = await _supabaseService.fetchProductsFromServer();

      if (serverProducts.isEmpty) {
        print("⚠️ No products fetched from Supabase. Skipping update.");
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

      final localIds = _productBox.keys.cast<String>().toSet();
      final toDelete = localIds.difference(serverIds);

      for (final id in toDelete) {
        final product = _productBox.get(id);
        if (product != null && product.deletedAt == null) {
          product.deletedAt = DateTime.now();
          product.lastModified = DateTime.now();
          await product.save();
        }
      }

      refreshProducts();
      print('☁️ Synced ${serverProducts.length} product(s).');
    } catch (e) {
      print('❌ Supabase sync failed: $e');
    }
  }

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
        } else {
          mergedProducts.add(server);
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
        await _supabaseService.upsertProductsListToServer(mergedProducts);
        print('✅ Synced ${mergedProducts.length} products with Supabase.');
      }
    } catch (e) {
      print('❌ Supabase sync failed: $e');
    }
  }

  Future<void> autoSyncProducts() async {
    await syncToSupabase();
    await syncFromSupabase();
  }

  Future<void> clearAll() async {
    try {
      await _productBox.clear();
      _products.clear();
      notifyListeners();
      SnackbarService.showSuccess('🧹 All products cleared.');
      await autoSyncProducts();
    } catch (e) {
      SnackbarService.showError('❌ Clear all failed: $e');
    }
  }



  // ──────────── BATCH CRUD METHODS ────────────

  List<Batch> getBatchesByProductName(String productName) {
    final product = getProductByName(productName);
    return product?.batches ?? [];
  }

  Future<void> updateBatchQty({
    required String productName,
    required String batchId,
    required double newQuantity,
  }) async {
    try {
      final product = getProductByName(productName);
      if (product != null) {
        final index = product.batches.indexWhere((b) => b.id == batchId);
        if (index != -1) {
          final oldBatch = product.batches[index];
          final updatedBatch = oldBatch.copyWith(quantity: newQuantity);

          product.batches[index] = updatedBatch;
          product.lastModified = DateTime.now();

          await _productBox.put(product.id, product);
          refreshProducts();
          SnackbarService.showSuccess('✅ Updated quantity for batch in $productName');
          await autoSyncProducts();
        } else {
          SnackbarService.showWarning('⚠️ Batch not found in $productName');
        }
      }
    } catch (e) {
      SnackbarService.showError('❌ Failed to update batch quantity: $e');
    }
  }

  Future<void> addBatchByProductName(String productName, Batch newBatch) async {
    try {
      final product = getProductByName(productName);
      if (product != null) {
        // Find batch created on the same day
        final existing = product.batches.firstWhere(
              (b) =>
          b.createdAt.year == newBatch.createdAt.year &&
              b.createdAt.month == newBatch.createdAt.month &&
              b.createdAt.day == newBatch.createdAt.day,
          orElse: () => Batch(id: '', quantity: 0, createdAt: DateTime(2000)),
        );

        if (existing.id.isNotEmpty) {
          // Merge quantity to existing batch on same day
          existing.quantity += newBatch.quantity;
        } else {
          // No batch on the same day, add as new
          product.batches.add(newBatch);
        }

        product.lastModified = DateTime.now();
        await _productBox.put(product.id, product);
        refreshProducts();
        SnackbarService.showSuccess('✅ Batch added to $productName');
        await autoSyncProducts();
      }
    } catch (e) {
      SnackbarService.showError('❌ Failed to add batch: $e');
    }
  }

  Future<void> deleteBatchByProductName(String productName, String batchId) async {
    try {
      final product = getProductByName(productName);
      if (product != null) {
        product.batches.removeWhere((b) => b.id == batchId);
        product.lastModified = DateTime.now();
        await _productBox.put(product.id, product);
        refreshProducts();
        SnackbarService.showSuccess('🗑️ Batch deleted from $productName');
        await autoSyncProducts();
      }
    } catch (e) {
      SnackbarService.showError('❌ Failed to delete batch: $e');
    }
  }

  Future<void> incrementBatchQuantityFIFO(String productName, double quantityToAdd) async {
    try {
      final product = getProductByName(productName);
      if (product != null && product.batches.isNotEmpty) {
        product.batches.sort((a, b) => a.createdAt.compareTo(b.createdAt));
        final first = product.batches.first;
        final index = product.batches.indexOf(first);

        product.batches[index] = first.copyWith(
          quantity: first.quantity + quantityToAdd,
        );

        product.lastModified = DateTime.now();
        await _productBox.put(product.id, product);
        refreshProducts();
        SnackbarService.showSuccess('➕ Incremented $quantityToAdd to $productName');
        await autoSyncProducts();
      }
    } catch (e) {
      SnackbarService.showError('❌ Failed to increment batch: $e');
    }
  }
}
