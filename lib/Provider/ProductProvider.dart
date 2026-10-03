import 'package:flutter/foundation.dart';
import 'dart:async';
import 'package:nextpos/core/data/product_store.dart';
import 'package:nextpos/Model/product_model.dart';
import 'package:nextpos/Model/stock_log.dart';

class ProductProvider extends ChangeNotifier {
  final ProductStore _productBox = ProductStore.instance;
  StreamSubscription<void>? _storeSubscription;

  ProductProvider() {
    _storeSubscription = _productBox.watch().listen((_) {
    });
  }

  @override
  void dispose() {
    _storeSubscription?.cancel();
    super.dispose();
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
    } catch (e) {
      debugPrint("⚠️ silentUpsertProduct error: $e");
    }
  }

  Future<void> upsertProduct(Product product) async {
    try {
      final exists = _productBox.containsKey(product.id);
      final now = DateTime.now();

      if (!exists) {
        final nameExists = _productBox.values.any(
          (p) =>
              p.name.trim().toLowerCase() ==
                  product.name.trim().toLowerCase() &&
              !p.isSoftDeleted,
        );
        if (nameExists) return;

        final logs = <StockLog>[
          ...product.stocks
              .where((s) => s.quantity > 0)
              .map(
                (s) => StockLog(
                  id: 'log-${s.id}',
                  productId: product.id,
                  quantity: s.quantity,
                  isPiece: false,
                  reason: StockLogReason.added,
                  remarks: 'Initial stock (pack)',
                ),
              ),
          if (product.looseStock?.remainingPieces != null &&
              product.looseStock!.remainingPieces > 0)
            StockLog(
              id: 'log-${product.id}-loose',
              productId: product.id,
              quantity: product.looseStock!.remainingPieces,
              isPiece: true,
              reason: StockLogReason.added,
              remarks: 'Initial stock (loose)',
            ),
        ];

        final newProduct = product.copyWith(
          lastModified: now,
          logs: [...product.logs, ...logs],
        );
        await _productBox.put(newProduct.id, newProduct);
      } else {
        final current = _productBox.get(product.id);
        final looseBefore = current?.looseStock?.remainingPieces ?? 0;
        final looseAfter = product.looseStock?.remainingPieces ?? 0;
        final diff = looseAfter - looseBefore;

        final logs = <StockLog>[
          StockLog(
            id: 'log-${product.id}-adjust-${now.millisecondsSinceEpoch}',
            productId: product.id,
            quantity: 0,
            isPiece: false,
            reason: StockLogReason.adjusted,
            remarks: 'Product updated manually',
          ),
          if (diff != 0)
            StockLog(
              id: 'log-${product.id}-loose-adjust-${now.millisecondsSinceEpoch}',
              productId: product.id,
              quantity: diff.abs(),
              isPiece: true,
              reason: StockLogReason.adjusted,
              remarks: diff > 0 ? 'Added loose stock' : 'Removed loose stock',
            ),
        ];

        final updated = product.copyWith(
          lastModified: now,
          logs: [...product.logs, ...logs],
        );

        await _productBox.put(updated.id, updated);
      }

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
      }
      await _productBox.clear();
    } catch (e) {
      debugPrint("❌ clearAll failed: $e");
    }
  }
}
