import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:mobile_pos_inventory/Model/product_model.dart';
import 'package:mobile_pos_inventory/View/Components/SnackbarService.dart';

class ProductProvider extends ChangeNotifier {
  final Box<Product> _productBox;
  List<Product> _products = [];
  List<Product> get products => _products;

  ProductProvider(this._productBox) {
    initializeProducts();
  }

  Future<void> initializeProducts() async {
    if (_productBox.isEmpty) {
      print("📦 Hive is empty.");
    } else {
      print("📦 Loading products from Hive.");
      refreshProducts();
    }
  }

  void refreshProducts() {
    _products = _productBox.values
        .where((p) => p.deletedAt == null)
        .map((product) {
      product.batches.removeWhere((batch) => batch.quantity == 0);
      product.save();
      return product;
    })
        .toList();
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
            (p) => p.name.trim().toLowerCase() == product.name.trim().toLowerCase() && p.deletedAt == null,
      );
      if (nameExists) {
        SnackbarService.showWarning('⚠️ Product already exists: ${product.name}');
        return;
      }

      product.lastModified = DateTime.now();
      await _productBox.put(product.id, product);
      _products.add(product);
      notifyListeners();
      SnackbarService.showSuccess('✅ Product added: ${product.name}');
    } catch (e) {
      SnackbarService.showError('❌ Failed to add product: $e');
    }
  }

  Future<void> updateProduct(Product product) async {
    try {
      product.lastModified = DateTime.now();
      await _productBox.put(product.id, product);
      final index = _products.indexWhere((p) => p.id == product.id);
      if (index != -1) _products[index] = product;
      notifyListeners();
      SnackbarService.showSuccess('✅ Product updated: ${product.name}');
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
      }
    } catch (e) {
      SnackbarService.showError('❌ Failed to restore product: $e');
    }
  }

  Future<void> clearAll() async {
    try {
      await _productBox.clear();
      _products.clear();
      notifyListeners();
      SnackbarService.showSuccess('🧹 All products cleared.');
    } catch (e) {
      SnackbarService.showError('❌ Clear all failed: $e');
    }
  }
}
