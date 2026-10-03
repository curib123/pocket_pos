import 'package:flutter/foundation.dart';
import 'dart:async';
import 'package:hive/hive.dart';
import 'package:nextpos/Model/product_model.dart';
import 'package:nextpos/Model/stock_log.dart';
import 'package:nextpos/core/data/offline_database.dart';

class ProductProvider extends ChangeNotifier {
  final Box<Product> _productBox = Hive.box<Product>('products');
  final OfflineDatabase _offlineDatabase = OfflineDatabase.instance;
  late final Stream<BoxEvent> _hiveListener;

  ProductProvider() {
    _listenToBoxChanges();
    unawaited(_bootstrapOfflineStore());
  }

  Future<void> _bootstrapOfflineStore() async {
    try {
      for (final product in _productBox.values) {
        await _offlineDatabase.upsertProduct(product, queueSync: false);
      }
    } catch (error) {
      debugPrint('[ProductProvider] SQLite bootstrap skipped: $error');
    }
  }

  Future<void> _mirror(Product product) async {
    try {
      await _offlineDatabase.upsertProduct(product);
    } catch (error) {
      debugPrint('[ProductProvider] SQLite mirror failed: $error');
    }
  }

  void _listenToBoxChanges() {
    _hiveListener = _productBox.watch();
    _hiveListener.listen((event) {
      notifyListeners(); // Trigger UI rebuild when data in Hive changes
    });
  }

  // 🔍 CHECKERS

  bool barcodeExists(String barcode) {
    return _productBox.values.any(
      (p) =>
          (!p.isSoftDeleted && !p.isDeletedPermanent && p.barcode == barcode) ||
          p.variants.any(
            (v) =>
                !v.isSoftDeleted &&
                !v.isDeletedPermanent &&
                v.barcode == barcode,
          ),
    );
  }

  bool productExistsByName(String name) {
    final lower = name.toLowerCase();
    return _productBox.values.any(
          (p) =>
              !p.isSoftDeleted &&
              !p.isDeletedPermanent &&
              p.name.toLowerCase() == lower,
        ) ||
        _productBox.values.any(
          (p) => p.variants.any(
            (v) =>
                !v.isSoftDeleted &&
                !v.isDeletedPermanent &&
                v.name.toLowerCase() == lower,
          ),
        );
  }

  // 🔎 GETTERS

  Product? getProductOrVariantByBarcode(String barcode) {
    for (final product in _productBox.values) {
      if (!product.isSoftDeleted &&
          !product.isDeletedPermanent &&
          product.barcode == barcode)
        return product;

      for (final variant in product.variants) {
        if (!variant.isSoftDeleted &&
            !variant.isDeletedPermanent &&
            variant.barcode == barcode)
          return variant;
      }
    }
    return null;
  }

  Product? getProductById(String id) {
    for (final product in _productBox.values) {
      if (!product.isSoftDeleted &&
          !product.isDeletedPermanent &&
          product.id == id)
        return product;

      for (final variant in product.variants) {
        if (!variant.isSoftDeleted &&
            !variant.isDeletedPermanent &&
            variant.id == id)
          return variant;
      }
    }
    return null;
  }

  List<Product> getAllProductsInBox() => _productBox.values.toList();

  List<Product> getAllProductsWithVariants() {
    return _productBox.values
        .where((p) => !p.isSoftDeleted && !p.isDeletedPermanent)
        .expand((p) {
          final activeVariants = p.variants
              .where((v) => !v.isSoftDeleted && !v.isDeletedPermanent)
              .toList();
          return [p, ...activeVariants];
        })
        .toList()
      ..sort((a, b) => b.lastModified.compareTo(a.lastModified));
  }

  List<Product> getAllProductsWithVariantsByCategory(String category) {
    return _productBox.values
        .where((p) => !p.isSoftDeleted && !p.isDeletedPermanent)
        .expand((p) {
          final activeVariants = p.variants
              .where(
                (v) =>
                    !v.isSoftDeleted &&
                    !v.isDeletedPermanent &&
                    v.category == category,
              )
              .toList();
          return [if (p.category == category) p, ...activeVariants];
        })
        .toList()
      ..sort((a, b) => b.lastModified.compareTo(a.lastModified));
  }

  List<String> getAllDeletedProductNames() => _productBox.values
      .where((p) => p.isSoftDeleted)
      .map((p) => p.name)
      .toList();

  List<Product> getAllDeletedProducts() => _productBox.values
      .where((p) => p.isSoftDeleted && p.isDeletedPermanent != true)
      .toList();

  // ✍️ UPSERT / DELETE / RESTORE

  Future<void> silentUpsertProduct(Product product) async {
    try {
      await _productBox.put(product.id, product);
      await _mirror(product);
      notifyListeners();
    } catch (e) {
      debugPrint("⚠️ silentUpsertProduct error: $e");
    }
  }

  Future<void> upsertProduct(Product product) async {
    try {
      final now = DateTime.now();

      if (_productBox.containsKey(product.id)) {
        final current = _productBox.get(product.id);
        if (current == null) return;

        final updated = product.copyWith(
          stocks: current.stocks,
          looseStock: current.looseStock,
          logs: current.logs,
          loans: current.loans,
          variants: current.variants,
          lastModified: now,
        );

        await _productBox.put(updated.id, updated);
        await _mirror(updated);
        notifyListeners();
        return;
      }

      for (final key in _productBox.keys) {
        final parent = _productBox.get(key);
        if (parent == null) continue;

        final variantIndex =
            parent.variants.indexWhere((variant) => variant.id == product.id);
        if (variantIndex == -1) continue;

        final currentVariant = parent.variants[variantIndex];
        final updatedVariant = product.copyWith(
          stocks: currentVariant.stocks,
          looseStock: currentVariant.looseStock,
          logs: currentVariant.logs,
          loans: currentVariant.loans,
          variants: currentVariant.variants,
          lastModified: now,
        );

        final variants = [...parent.variants];
        variants[variantIndex] = updatedVariant;
        final updatedParent = parent.copyWith(
          variants: variants,
          lastModified: now,
        );

        await _productBox.put(key, updatedParent);
        await _mirror(updatedParent);
        notifyListeners();
        return;
      }

      final nameExists = _productBox.values.any(
        (existing) =>
            existing.name.trim().toLowerCase() ==
                product.name.trim().toLowerCase() &&
            !existing.isSoftDeleted &&
            !existing.isDeletedPermanent,
      );
      if (nameExists) return;

      final newProduct = product.copyWith(
        stocks: const [],
        logs: const [],
        loans: const [],
        lastModified: now,
      );

      await _productBox.put(newProduct.id, newProduct);
      await _mirror(newProduct);
      notifyListeners();
    } catch (e) {
      debugPrint("❌ upsertProduct error: $e");
    }
  }

  Future<void> softDeleteProduct(String id) async {
    try {
      final product = _productBox.get(id);
      if (product != null) {
        final updated = product.copyWith(
          isSoftDeleted: true,
          lastModified: DateTime.now(),
          logs: [
            ...product.logs,
            StockLog(
              id: 'log-$id-deleted',
              productId: id,
              quantity: 0,
              isPiece: false,
              reason: StockLogReason.deleted,
              remarks: 'Product was deleted',
            ),
          ],
        );
        await _productBox.put(id, updated);
        await _mirror(updated);
        notifyListeners();
      }
    } catch (e) {
      debugPrint("❌ softDeleteProduct failed: $e");
    }
  }

  Future<bool> hardDeleteProduct(String id) async {
    try {
      final product = _productBox.get(id);
      if (product != null) {
        final updated = product.copyWith(
          isDeletedPermanent: true,
          lastModified: DateTime.now(),
        );
        await _productBox.put(id, updated);
        await _mirror(updated);
        notifyListeners();
        return true;
      }
    } catch (e) {
      debugPrint("❌ hardDeleteProduct failed: $e");
    }
    return false;
  }

  Future<Product?> restoreProductById(String id) async {
    try {
      final product = _productBox.get(id);
      if (product?.isSoftDeleted == true) {
        final now = DateTime.now();
        final restored = product!.copyWith(
          isSoftDeleted: false,
          lastModified: now,
          logs: [
            ...product.logs,
            StockLog(
              id: 'log-$id-restored-${now.millisecondsSinceEpoch}',
              productId: id,
              quantity: 0,
              isPiece: false,
              reason: StockLogReason.restored,
              remarks: 'Product was restored',
              dateLogged: now,
              lastModified: now,
            ),
          ],
        );
        await _productBox.put(id, restored);
        await _mirror(restored);
        notifyListeners();
        return restored;
      }
    } catch (e) {
      debugPrint("❌ restoreProductById failed: $e");
    }
    return null;
  }

  Future<void> clearAll() async {
    try {
      for (final product in _productBox.values) {
        final cleared = product.copyWith(
          lastModified: DateTime.now(),
          logs: [
            ...product.logs,
            StockLog(
              id: 'log-${product.id}-cleared',
              productId: product.id,
              quantity: 0,
              isPiece: false,
              reason: StockLogReason.cleared,
              remarks: 'Cleared from system',
            ),
          ],
        );
        await _productBox.put(cleared.id, cleared);
        await _mirror(cleared);
      }
      await _productBox.clear();
      notifyListeners();
    } catch (e) {
      debugPrint("❌ clearAll failed: $e");
    }
  }
}
