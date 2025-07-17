import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:mobile_stock_inventory/Model/product_model.dart';
import 'package:mobile_stock_inventory/Model/stock_log.dart';
import 'package:mobile_stock_inventory/View/Components/SnackbarService.dart';

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
      // Removed autoSync() ✅
    }
  }

  void refreshProducts() {
    _products = _productBox.values
        .where((p) => p.deletedAt == null)
        .toList();
    notifyListeners();
  }

  List<Product> getProductsByCategory(String category) =>
      _products.where((product) => product.category == category).toList();

  Product? getProductById(String id) {
    for (final product in _products) {
      if (product.id == id) return product;

      for (final variant in product.variants) {
        if (variant.id == id) return variant;
      }
    }
    return null;
  }

  /// Returns all products including nested variant products
  List<Product> getAllProductsWithVariants() {
    final List<Product> all = [];

    for (final product in _products) {
      all.add(product);
      all.addAll(product.variants);
    }

    return all;
  }

  /// Returns all products and variants that match the given category
  List<Product> getAllProductsWithVariantsByCategory(String category) {
    final List<Product> all = [];

    for (final product in _products) {
      if (product.category == category) {
        all.add(product);
      }

      // Include variants that match the category too
      for (final variant in product.variants) {
        if (variant.category == category) {
          all.add(variant);
        }
      }
    }

    return all;
  }


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
  Future<void> upsertProduct(Product product) async {
    try {
      final existingIndex = _products.indexWhere((p) => p.id == product.id);
      final bool isNew = existingIndex == -1;

      if (isNew) {
        // Check duplicate name for new products only
        final nameExists = _products.any((p) =>
        p.name.trim().toLowerCase() == product.name.trim().toLowerCase() &&
            p.deletedAt == null,
        );

        if (nameExists) {
          SnackbarService.showWarning('⚠️ Product already exists: ${product.name}');
          return;
        }

        final List<StockLog> logs = [];

        for (final stock in product.stocks) {
          if (stock.quantity > 0) {
            logs.add(StockLog(
              id: 'log-${stock.id}',
              productId: product.id,
              quantity: stock.quantity,
              isPiece: false,
              reason: StockLogReason.added,
              remarks: 'Initial stock (pack)',
            ));
          }
        }

        final loose = product.looseStock;
        if (loose != null && loose.remainingPieces > 0) {
          logs.add(StockLog(
            id: 'log-${product.id}-loose',
            productId: product.id,
            quantity: loose.remainingPieces,
            isPiece: true,
            reason: StockLogReason.added,
            remarks: 'Initial stock (loose)',
          ));
        }

        final newProduct = product.copyWith(
          lastModified: DateTime.now(),
          logs: [...product.logs, ...logs],
        );

        await _productBox.put(newProduct.id, newProduct);
        _products.add(newProduct);
        notifyListeners();
        SnackbarService.showSuccess('✅ Product added: ${product.name}');
      } else {
        // Update existing product

        final log = StockLog(
          id: 'log-${product.id}-adjust-${DateTime.now().millisecondsSinceEpoch}',
          productId: product.id,
          quantity: 0,
          isPiece: false,
          reason: StockLogReason.adjusted,
          remarks: 'Product details manually updated',
        );

        final updatedProduct = product.copyWith(
          lastModified: DateTime.now(),
          logs: [...product.logs, log],
        );

        await _productBox.put(updatedProduct.id, updatedProduct);
        _products[existingIndex] = updatedProduct;
        notifyListeners();
        SnackbarService.showSuccess('✅ Product updated: ${updatedProduct.name}');
      }
    } catch (e) {
      SnackbarService.showError('❌ Failed to upsert product: $e');
    }
  }


  Future<void> deleteProduct(String id) async {
    try {
      final product = _productBox.get(id);
      if (product != null) {
        final log = StockLog(
          id: 'log-${id}-deleted',
          productId: id,
          quantity: 0,
          isPiece: false,
          reason: StockLogReason.deleted,
          remarks: 'Product was deleted',
        );

        final deleted = product.copyWith(
          deletedAt: DateTime.now(),
          lastModified: DateTime.now(),
          logs: [...product.logs, log],
        );

        await _productBox.put(id, deleted);
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
        final log = StockLog(
          id: 'log-${id}-restored',
          productId: id,
          quantity: 0,
          isPiece: false,
          reason: StockLogReason.restored,
          remarks: 'Product was restored',
        );

        final restored = product.copyWith(
          deletedAt: null,
          lastModified: DateTime.now(),
          logs: [...product.logs, log],
        );

        await _productBox.put(id, restored);
        _products.add(restored);
        notifyListeners();
        SnackbarService.showSuccess('✅ Product restored: ${product.name}');
      }
    } catch (e) {
      SnackbarService.showError('❌ Failed to restore product: $e');
    }
  }

  Future<void> clearAll() async {
    try {
      for (final product in _products) {
        final log = StockLog(
          id: 'log-${product.id}-cleared',
          productId: product.id,
          quantity: 0,
          isPiece: false,
          reason: StockLogReason.cleared,
          remarks: 'Cleared from system',
        );

        final cleared = product.copyWith(
          lastModified: DateTime.now(),
          logs: [...product.logs, log],
        );

        await _productBox.put(cleared.id, cleared);
      }

      await _productBox.clear();
      _products.clear();
      notifyListeners();
      SnackbarService.showSuccess('🧹 All products cleared.');
    } catch (e) {
      SnackbarService.showError('❌ Clear all failed: $e');
    }
  }

}
