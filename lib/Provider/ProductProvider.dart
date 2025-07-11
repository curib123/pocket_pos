import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:mobile_pos_inventory/Helper/Database/SupabaseProductServices.dart';
import 'package:mobile_pos_inventory/Model/product_model.dart';

class ProductProvider extends ChangeNotifier {
  final Box<Product> _productBox;
  final SupabaseProductServices _supabaseService = SupabaseProductServices();
  List<Product> _products = [];

  List<Product> get products => _products;

  ProductProvider(this._productBox) {
    loadProducts();
  }

  // ─────────────────────────────────────────────
  // Load active products
  // ─────────────────────────────────────────────
  void loadProducts() {
    _products = _productBox.values.where((p) => !p.isDeleted).toList();
    notifyListeners();
  }

  // ─────────────────────────────────────────────
  // Add Product
  // ─────────────────────────────────────────────
  Future<void> addProduct(Product product) async {
    product.updatedAt = DateTime.now();
    await _productBox.put(product.id, product);
    _products.add(product);
    notifyListeners();
  }

  // ─────────────────────────────────────────────
  // Get by ID
  // ─────────────────────────────────────────────
  Product? getProductById(String id) => _productBox.get(id);

  // ─────────────────────────────────────────────
  // Update Product
  // ─────────────────────────────────────────────
  Future<void> updateProduct(Product product) async {
    product.updatedAt = DateTime.now();
    await _productBox.put(product.id, product);
    final index = _products.indexWhere((p) => p.id == product.id);
    if (index != -1) {
      _products[index] = product;
      notifyListeners();
    }
  }

  // ─────────────────────────────────────────────
  // Soft Delete
  // ─────────────────────────────────────────────
  Future<void> deleteProduct(String id) async {
    final product = _productBox.get(id);
    if (product != null) {
      product.isDeleted = true;
      product.updatedAt = DateTime.now();
      await product.save();
      _products.removeWhere((p) => p.id == id);
      notifyListeners();
    }
  }

  // ─────────────────────────────────────────────
  // Restore Deleted
  // ─────────────────────────────────────────────
  Future<void> restoreProduct(String id) async {
    final product = _productBox.get(id);
    if (product != null && product.isDeleted) {
      product.isDeleted = false;
      product.updatedAt = DateTime.now();
      await product.save();
      _products.add(product);
      notifyListeners();
    }
  }

  // ─────────────────────────────────────────────
  // Search
  // ─────────────────────────────────────────────
  List<Product> search(String keyword) {
    return _products
        .where((p) => p.name.toLowerCase().contains(keyword.toLowerCase()))
        .toList();
  }

  // ─────────────────────────────────────────────
  // Export
  // ─────────────────────────────────────────────
  List<Map<String, dynamic>> exportToJsonList() =>
      _products.map((p) => p.toJson()).toList();

  // ─────────────────────────────────────────────
  // Import
  // ─────────────────────────────────────────────
  Future<void> importFromJsonList(List<Map<String, dynamic>> data) async {
    for (var item in data) {
      final product = Product.fromJson(item);
      await _productBox.put(product.id, product);
    }
    loadProducts();
  }

  // ─────────────────────────────────────────────
  // Batch Update
  // ─────────────────────────────────────────────
  Future<void> batchUpdate({
    required List<String> ids,
    double? price,
    String? category,
  }) async {
    for (var id in ids) {
      final product = _productBox.get(id);
      if (product != null) {
        if (price != null) product.defaultPrice = price;
        if (category != null) product.category = category;
        product.updatedAt = DateTime.now();
        await product.save();
      }
    }
    loadProducts();
  }

  // ─────────────────────────────────────────────
  // SYNC: Supabase → Local
  // ─────────────────────────────────────────────
  Future<void> syncFromSupabase() async {
    final serverProducts = await _supabaseService.fetchProductsFromServer();

    for (var serverProduct in serverProducts) {
      final localProduct = _productBox.get(serverProduct.id);
      final serverTime = serverProduct.updatedAt ?? DateTime.now();
      final localTime = localProduct?.updatedAt ?? DateTime(2000);

      if (localProduct == null || serverTime.isAfter(localTime)) {
        await _productBox.put(serverProduct.id, serverProduct);
      }
    }

    loadProducts();
  }

  // ─────────────────────────────────────────────
  // SYNC: Local → Supabase
  // ─────────────────────────────────────────────
  Future<void> syncToSupabase() async {
    final serverProducts = await _supabaseService.fetchProductsFromServer();
    final serverMap = {for (var p in serverProducts) p.id: p};

    for (var local in _products) {
      final localTime = local.updatedAt ?? DateTime.now();
      final server = serverMap[local.id];
      final serverTime = server?.updatedAt ?? DateTime(2000);

      if (server == null || localTime.isAfter(serverTime)) {
        await _supabaseService.upsertProductToServer(local);
      }
    }
  }

  // ─────────────────────────────────────────────
  // AUTO SYNC: Both Directions
  // ─────────────────────────────────────────────
  Future<void> autoSyncProducts() async {
    await syncFromSupabase();
    await syncToSupabase();
  }

  // ─────────────────────────────────────────────
  // Clear All (USE WITH CAUTION)
  // ─────────────────────────────────────────────
  Future<void> clearAll() async {
    await _productBox.clear();
    _products.clear();
    notifyListeners();
  }
}
