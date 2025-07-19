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

  LooseStock? getLooseStock(String idOrName) {
    final product = _getProduct(idOrName);
    return product?.looseStock;
  }

  /// 🪵 CREATE / UPDATE Loose Stock
  Future<void> upsertLooseStock(String idOrName, int quantity) async {
    final product = _getProduct(idOrName);
    if (product == null) return;

    final now = DateTime.now();

    final isNew = product.looseStock == null;
    final previousQty = product.looseStock?.remainingPieces ?? 0;

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

    await _productBox.put(product.id, updatedProduct);
    notifyListeners();

  }

  /// ➖ Deduct Loose Pieces
  Future<void> deductLoosePieces(String idOrName, int qty) async {
    final product = _getProduct(idOrName);
    if (product == null || product.looseStock == null) return;

    final loose = product.looseStock!;
    if (loose.remainingPieces < qty) {
      return;
    }

    final newQty = loose.remainingPieces - qty;
    final now = DateTime.now();

    final updatedLoose = loose.copyWith(
      remainingPieces: newQty,
      lastModified: now,
    );

    final updatedProduct = product.copyWith(
      looseStock: updatedLoose,
      lastModified: now,
      logs: [
        ...product.logs,
        StockLog(
          id: uuid.v4(),
          productId: product.id,
          quantity: qty,
          isPiece: true,
          reason: StockLogReason.sold,
          remarks: "Deducted $qty piece(s) from loose stock",
        ),
      ],
    );

    await _productBox.put(product.id, updatedProduct);
    notifyListeners();
  }

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
