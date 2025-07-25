import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:pocketpos/Helper/Database/SupabaseProductServices.dart';
import 'package:pocketpos/Model/product_model.dart';
import 'package:pocketpos/Model/stock_log.dart';

class ProductProvider extends ChangeNotifier {
  final Box<Product> _productBox;
  final SupabaseProductServices _supabaseService = SupabaseProductServices();

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
    final products = _productBox.values
        .where((p) => p.deletedAt == null)
        .toList();

    products.sort((a, b) => b.lastModified.compareTo(a.lastModified));

    _products = products;
    notifyListeners();
  }



  bool barcodeExists(String barcode) {
    for (final product in _products) {
      if (product.barcode == barcode) return true;
      for (final variant in product.variants) {
        if (variant.barcode == barcode) return true;
      }
    }
    return false;
  }


  Product? getProductOrVariantByBarcode(String barcode) {
    for (final product in _products) {
      if (product.barcode == barcode) return product;

      for (final variant in product.variants) {
        if (variant.barcode == barcode) return variant;
      }
    }
    return null;
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

  List<Product> getAllProductsWithVariants() {
    final List<Product> all = [];
    for (final product in _products) {
      all.add(product);
      all.addAll(product.variants);
    }
    return all;
  }

  List<Product> getAllProductsWithVariantsByCategory(String category) {
    final List<Product> all = [];
    for (final product in _products) {
      if (product.category == category) all.add(product);
      for (final variant in product.variants) {
        if (variant.category == category) all.add(variant);
      }
    }
    return all;
  }


  List<Map<String, dynamic>> exportToJsonList() =>
      _products.map((p) => p.toMap()).toList();

  Future<void> upsertProduct(Product product) async {
    try {
      final existingIndex = _products.indexWhere((p) => p.id == product.id);
      final bool isNew = existingIndex == -1;

      if (isNew) {
        final nameExists = _products.any((p) =>
        p.name.trim().toLowerCase() == product.name.trim().toLowerCase() &&
            p.deletedAt == null);

        if (nameExists) {
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
          looseStock: product.looseStock, // 👈 ensures looseStock is persisted
        );

        await _productBox.put(newProduct.id, newProduct);
        refreshProducts();
      } else {
        // 🧠 Get current product from box for comparison
        final currentProduct = _productBox.get(product.id);

        final List<StockLog> logs = [
          StockLog(
            id: 'log-${product.id}-adjust-${DateTime.now().millisecondsSinceEpoch}',
            productId: product.id,
            quantity: 0,
            isPiece: false,
            reason: StockLogReason.adjusted,
            remarks: 'Product details manually updated',
          )
        ];

        // 🧮 Optional: log loose stock change if it changed
        final looseBefore = currentProduct?.looseStock?.remainingPieces ?? 0;
        final looseAfter = product.looseStock?.remainingPieces ?? 0;

        if (looseBefore != looseAfter) {
          final diff = looseAfter - looseBefore;
          logs.add(StockLog(
            id: 'log-${product.id}-loose-adjust-${DateTime.now().millisecondsSinceEpoch}',
            productId: product.id,
            quantity: diff.abs(),
            isPiece: true,
            reason: StockLogReason.adjusted,
            remarks: diff > 0 ? 'Added loose stock' : 'Removed loose stock',
          ));
        }

        final updatedProduct = product.copyWith(
          lastModified: DateTime.now(),
          logs: [...product.logs, ...logs],
          looseStock: product.looseStock, // 👈 update looseStock on edit
        );

        await _productBox.put(updatedProduct.id, updatedProduct);
        refreshProducts();
      }
    } catch (e) {
      print("⚠️ Error in upsertProduct: $e");
    }
  }

  Future<void> softDeleteProduct(String id) async {
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
        refreshProducts();
      }
    } catch (e) {
    }
  }

  Future<bool> hardDeleteProduct(String id) async {
    try {
      final product = _productBox.get(id);
      if (product != null) {
        // 🕒 Update lastModified before deletion (for logging/sync purposes)
        final updated = product.copyWith(lastModified: DateTime.now());
        await _productBox.put(id, updated);

        // 🗑 Actually delete the product from the box
        await _productBox.delete(id);

        refreshProducts();
        return true;
      }
      return false; // product not found
    } catch (e) {
      // Optional: log or handle the error
      return false;
    }
  }



  Future<Product?> restoreProductById(String id) async {
    try {
      final product = _productBox.get(id);

      if (product != null && product.deletedAt != null) {
        final now = DateTime.now();
        final log = StockLog(
          id: 'log-$id-restored-${now.millisecondsSinceEpoch}',
          productId: id,
          quantity: 0,
          isPiece: false,
          reason: StockLogReason.restored,
          remarks: 'Product was restored',
          dateLogged: now,
          lastModified: now,
        );

        final restored = product.copyWith(
          deletedAt: null,
          lastModified: now,
          logs: [...(product.logs ?? []), log], // safe spread
        );

        await _productBox.put(id, restored);
        refreshProducts(); // assuming this calls notifyListeners()

        debugPrint("✅ Product restored: ${restored.name} | deletedAt: ${restored.deletedAt} | lastModified: ${restored.lastModified}");
        return restored;
      } else {
        debugPrint("⚠️ Cannot restore: Product not found or not deleted.");
      }
    } catch (e, stack) {
      debugPrint("❌ Restore failed: $e");
      debugPrint("$stack");
    }

    return null;
  }


  List<String> getAllDeletedProductNames() {
    return _productBox.values
        .where((product) => product.deletedAt != null)
        .map((product) => product.name)
        .toList();
  }


  List<Product> getAllDeletedProducts() {
    return _productBox.values
        .where((product) => product.deletedAt != null)
        .toList();
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
      refreshProducts();
    } catch (e) {
    }
  }



}
