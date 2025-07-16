import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:mobile_stock_inventory/Model/loose_stock.dart';
import 'package:mobile_stock_inventory/Model/product_model.dart';
import 'package:mobile_stock_inventory/View/Components/SnackbarService.dart';

class LooseStockProvider extends ChangeNotifier {
  final Box<Product> _productBox;

  LooseStockProvider(this._productBox);

  /// 🔍 Get product by ID or name
  Product? _getProduct(String idOrName) {
    try {
      return _productBox.values.firstWhere(
            (p) =>
        p.deletedAt == null &&
            (p.id == idOrName ||
                p.name.trim().toLowerCase() == idOrName.trim().toLowerCase()),
      );
    } catch (_) {
      return null;
    }
  }

  /// 🧾 Get loose stock
  LooseStock? getLooseStock(String idOrName) {
    final product = _getProduct(idOrName);
    return product?.looseStock;
  }

  /// 🔄 Add or update loose stock
  Future<void> upsertLooseStock(String idOrName, int quantity) async {
    final product = _getProduct(idOrName);
    if (product == null) return;

    final now = DateTime.now();

    final newLoose = LooseStock(
      productId: product.id,
      remainingPieces: quantity,
      lastModified: now,
    );

    final updatedProduct = product.copyWith(
      looseStock: newLoose,
      lastModified: now,
    );

    await _productBox.put(product.id, updatedProduct);
    notifyListeners();

    final msg = product.looseStock == null
        ? "✅ Loose stock created with $quantity piece(s)."
        : "✅ Loose stock updated to $quantity piece(s).";

    SnackbarService.showSuccess(msg);
  }


  /// ➖ Remove sticks
  Future<void> deductLoosePieces(String idOrName, int qty) async {
    final product = _getProduct(idOrName);
    if (product == null || product.looseStock == null) return;

    final loose = product.looseStock!;
    if (loose.remainingPieces < qty) {
      SnackbarService.showWarning("⚠️ Not enough loose pieces.");
      return;
    }

    final updated = loose.copyWith(
      remainingPieces: loose.remainingPieces - qty,
      lastModified: DateTime.now(),
    );

    final updatedProduct = product.copyWith(
      looseStock: updated,
      lastModified: DateTime.now(),
    );

    await _productBox.put(product.id, updatedProduct);
    notifyListeners();
    SnackbarService.showSuccess("✅ Deducted $qty loose piece(s).");
  }

  /// ✏️ Update total count
  Future<void> setLoosePieces(String idOrName, int newQty) async {
    final product = _getProduct(idOrName);
    if (product == null || product.looseStock == null) return;

    final updated = product.looseStock!.copyWith(
      remainingPieces: newQty,
      lastModified: DateTime.now(),
    );

    final updatedProduct = product.copyWith(
      looseStock: updated,
      lastModified: DateTime.now(),
    );

    await _productBox.put(product.id, updatedProduct);
    notifyListeners();
    SnackbarService.showSuccess("✅ Loose stock updated.");
  }

  /// 🗑️ Delete loose stock
  Future<void> deleteLooseStock(String idOrName) async {
    final product = _getProduct(idOrName);
    if (product == null || product.looseStock == null) return;

    final updated = product.copyWith(
      looseStock: null,
      lastModified: DateTime.now(),
    );

    await _productBox.put(product.id, updated);
    notifyListeners();
    SnackbarService.showSuccess("🗑️ Loose stock deleted.");
  }

  /// 🔢 Count of remaining pieces
  int getRemainingPieces(String idOrName) {
    final loose = getLooseStock(idOrName);
    return loose?.remainingPieces ?? 0;
  }

  /// 🧼 Reset to zero
  Future<void> resetLoose(String idOrName) => setLoosePieces(idOrName, 0);
}
