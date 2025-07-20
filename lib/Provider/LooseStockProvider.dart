import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';
import 'package:mobile_stock_inventory/Model/loose_stock.dart';
import 'package:mobile_stock_inventory/Model/product_model.dart';
import 'package:mobile_stock_inventory/Model/stock_log.dart';

class LooseStockProvider extends ChangeNotifier {
  final Box<Product> _productBox;

  LooseStockProvider(this._productBox);

  final uuid = const Uuid();

  Product? _getProduct(String idOrName) {
    final normalized = idOrName.trim().toLowerCase();

    for (final product in _productBox.values) {
      if (product.deletedAt != null) continue;

      // 🔍 Match main product
      if (product.id.toLowerCase() == normalized ||
          product.name.trim().toLowerCase() == normalized) {
        return product;
      }

      // 🔍 Match from variants
      if (product.hasVariant && product.variants.isNotEmpty) {
        for (final variant in product.variants.whereType<Product>()) {
          if (variant.deletedAt != null) continue;

          if (variant.id.toLowerCase() == normalized ||
              variant.name.trim().toLowerCase() == normalized) {
            return variant;
          }
        }
      }
    }

    return null;
  }


  LooseStock? getLooseStock(String idOrName) {
    final product = _getProduct(idOrName);
    return product?.looseStock;
  }

  /// 🪵 CREATE / UPDATE Loose Stock
  Future<void> upsertLooseStock(String idOrName, int quantity) async {
    print('🟡 [upsertLooseStock] Called with idOrName: $idOrName | Quantity: $quantity');

    Product? product = _getProduct(idOrName);
    Product? parent;

    // 🔁 Try finding in variants manually (no orElse!)
    if (product == null) {
      print('🔍 Not found in main products. Searching variants...');
      for (final p in _productBox.values) {
        for (final v in p.variants) {
          if (v.id == idOrName || v.name.toLowerCase() == idOrName.toLowerCase()) {
            product = v;
            parent = p;
            print('🧬 Variant found: ${v.name} (Parent: ${parent.name})');
            break;
          }
        }
        if (product != null) break;
      }

      if (product == null) {
        print('❌ Product or variant not found: $idOrName');
        return;
      }
    }

    final now = DateTime.now();
    final isNew = product.looseStock == null;
    final previousQty = product.looseStock?.remainingPieces ?? 0;

    print('🔍 Product matched: ${product.name} (${product.id})');
    print('📦 Previous loose stock: $previousQty');
    print('🆕 Is new loose stock? $isNew');

    final newLoose = LooseStock(
      productId: product.id,
      remainingPieces: quantity,
      lastModified: now,
    );

    final updatedProduct = product.copyWith(
      looseStock: newLoose,
      lastModified: now,
      logs: [
        ...product.logs,
        StockLog(
          id: uuid.v4(),
          productId: product.id,
          quantity: quantity,
          isPiece: true,
          reason: isNew ? StockLogReason.added : StockLogReason.adjusted,
          remarks: isNew
              ? "Initial loose stock created"
              : "Loose stock adjusted from $previousQty to $quantity",
        ),
      ],
    );

    if (parent != null) {
      final updatedVariants = parent.variants.map((v) {
        return v.id == updatedProduct.id ? updatedProduct : v;
      }).toList();

      final updatedParent = parent.copyWith(
        variants: updatedVariants,
        lastModified: now,
      );

      await _productBox.put(updatedParent.id, updatedParent);
      print('✅ Variant loose stock updated in parent: ${parent.name}');
    } else {
      await _productBox.put(product.id, updatedProduct);
      print('✅ Main product loose stock ${isNew ? "created" : "updated"} successfully');
    }

    print('🧾 Log added: ${isNew ? "Initial loose stock created" : "Adjusted from $previousQty to $quantity"}');
    print("🧮 Final Loose Stock: ${updatedProduct.looseStock?.remainingPieces}");

    notifyListeners();
    print('📣 Listeners notified.');
  }

  /// ➖ Deduct Loose Pieces

  /// ✏️ Manually Set Loose Piece Quantity
  Future<void> setLoosePieces(String idOrName, int newQty) async {
    final product = _getProduct(idOrName);
    if (product == null || product.looseStock == null) return;

    final prevQty = product.looseStock!.remainingPieces;
    final now = DateTime.now();

    final updated = product.looseStock!.copyWith(
      remainingPieces: newQty,
      lastModified: now,
    );

    final updatedProduct = product.copyWith(
      looseStock: updated,
      lastModified: now,
      logs: [
        ...product.logs,
        StockLog(
          id: uuid.v4(),
          productId: product.id,
          quantity: newQty,
          isPiece: true,
          reason: StockLogReason.adjusted,
          remarks: "Manually updated from $prevQty to $newQty piece(s)",
        ),
      ],
    );

    await _productBox.put(product.id, updatedProduct);
    notifyListeners();
  }

  /// 🗑️ Delete loose stock
  Future<void> deleteLooseStock(String idOrName) async {
    final product = _getProduct(idOrName);
    if (product == null || product.looseStock == null) return;

    final qty = product.looseStock!.remainingPieces;
    final now = DateTime.now();

    final updatedProduct = product.copyWith(
      looseStock: null,
      lastModified: now,
      logs: [
        ...product.logs,
        StockLog(
          id: uuid.v4(),
          productId: product.id,
          quantity: qty,
          isPiece: true,
          reason: StockLogReason.cleared,
          remarks: "Loose stock deleted with $qty remaining piece(s)",
        ),
      ],
    );

    await _productBox.put(product.id, updatedProduct);
    notifyListeners();
  }

  int getRemainingPieces(String idOrName) {
    final loose = getLooseStock(idOrName);
    return loose?.remainingPieces ?? 0;
  }

  /// 🧼 Reset to 0 and log
  Future<void> resetLoose(String idOrName) => setLoosePieces(idOrName, 0);
}
