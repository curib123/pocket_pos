import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:mobile_stock_inventory/Model/loose_stock.dart';
import 'package:mobile_stock_inventory/Model/product_model.dart';
import 'package:mobile_stock_inventory/Model/product_stock.dart';
import 'package:mobile_stock_inventory/Model/stock_log.dart';
import 'package:mobile_stock_inventory/View/Components/SnackbarService.dart';

class ProductStockProvider extends ChangeNotifier {
  final Box<Product> _productBox;

  ProductStockProvider(this._productBox);

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

  Future<void> sellPack(String productIdOrName, String stockId) async {
    final product = _getProduct(productIdOrName);
    if (product == null) return;

    final stockIndex = product.stocks.indexWhere((s) => s.id == stockId);
    if (stockIndex == -1) return;

    final updatedStock = product.stocks[stockIndex].copyWith(
      quantity: product.stocks[stockIndex].quantity - 1,
    );

    final updatedStocks = [...product.stocks];
    updatedStocks[stockIndex] = updatedStock;

    final log = StockLog(
      id: 'log-${DateTime.now().millisecondsSinceEpoch}',
      productId: product.id,
      quantity: 1,
      isPiece: false,
      reason: StockLogReason.sold,
      remarks: 'Sold 1 pack',
    );

    final updatedProduct = product.copyWith(
      stocks: updatedStocks,
      lastModified: DateTime.now(),
      logs: [...product.logs, log],
    );

    await _productBox.put(updatedProduct.id, updatedProduct);
    notifyListeners();
  }

  Future<void> sellPiece(String productIdOrName, int quantity) async {
    final product = _getProduct(productIdOrName);
    if (product == null) return;

    final current = product.looseStock;
    if (current == null || current.remainingPieces < quantity) return;

    final updatedLoose = current.copyWith(
      remainingPieces: current.remainingPieces - quantity,
    );

    final log = StockLog(
      id: 'log-${DateTime.now().millisecondsSinceEpoch}',
      productId: product.id,
      quantity: quantity,
      isPiece: true,
      reason: StockLogReason.sold,
      remarks: 'Sold $quantity piece(s)',
    );

    final updatedProduct = product.copyWith(
      looseStock: updatedLoose,
      lastModified: DateTime.now(),
      logs: [...product.logs, log],
    );

    await _productBox.put(updatedProduct.id, updatedProduct);
    notifyListeners();
  }

  Future<void> upsertStock(String productIdOrName, ProductStock stock) async {
    final product = _getProduct(productIdOrName);
    if (product == null) return;

    final existingIndex = product.stocks.indexWhere((s) => s.id == stock.id);
    final updatedStocks = [...product.stocks];

    if (existingIndex != -1) {
      updatedStocks[existingIndex] = stock;
    } else {
      updatedStocks.add(stock);
    }

    final log = StockLog(
      id: 'log-${stock.id}',
      productId: product.id,
      quantity: stock.quantity,
      isPiece: false,
      reason: StockLogReason.restocked,
      remarks: existingIndex != -1 ? 'Updated stock' : 'Added new stock',
    );

    final updatedProduct = product.copyWith(
      stocks: updatedStocks,
      lastModified: DateTime.now(),
      logs: [...product.logs, log],
    );

    await _productBox.put(updatedProduct.id, updatedProduct);
    notifyListeners();
  }

  Future<void> removeStockById(String productIdOrName, String stockId) async {
    final product = _getProduct(productIdOrName);
    if (product == null) return;

    final matching = product.stocks.where((s) => s.id == stockId);
    if (matching.isEmpty) return;

    final stock = matching.first;
    final updatedStocks = product.stocks.where((s) => s.id != stockId).toList();

    final log = StockLog(
      id: 'log-${stock.id}-removed',
      productId: product.id,
      quantity: stock.quantity,
      isPiece: false,
      reason: StockLogReason.damaged,
      remarks: 'Removed stock',
    );

    final updatedProduct = product.copyWith(
      stocks: updatedStocks,
      lastModified: DateTime.now(),
      logs: [...product.logs, log],
    );

    await _productBox.put(updatedProduct.id, updatedProduct);
    notifyListeners();
  }

  Future<void> deductQuantityFifo(String productIdOrName, int quantity) async {
    final product = _getProduct(productIdOrName);
    if (product == null) return;

    List<ProductStock> updatedStocks = [...product.stocks];
    List<StockLog> logs = [];

    for (int i = 0; i < updatedStocks.length; i++) {
      if (quantity <= 0) break;

      final available = updatedStocks[i].quantity;
      if (available <= 0) continue;

      final deduct = quantity < available ? quantity : available;
      quantity -= deduct;

      updatedStocks[i] = updatedStocks[i].copyWith(
        quantity: available - deduct,
      );

      logs.add(
        StockLog(
          id: 'log-${updatedStocks[i].id}-${DateTime.now().millisecondsSinceEpoch}',
          productId: product.id,
          quantity: deduct,
          isPiece: false,
          reason: StockLogReason.sold,
          remarks: 'FIFO deduction',
        ),
      );
    }

    final updatedProduct = product.copyWith(
      stocks: updatedStocks,
      lastModified: DateTime.now(),
      logs: [...product.logs, ...logs],
    );

    await _productBox.put(updatedProduct.id, updatedProduct);
    notifyListeners();
  }

  Future<void> updateLooseStock(String productIdOrName, int remainingPieces) async {
    final product = _getProduct(productIdOrName);
    if (product == null) return;

    final current = product.looseStock;
    if (current == null) return;

    final updatedLoose = current.copyWith(remainingPieces: remainingPieces);

    final updatedProduct = product.copyWith(
      looseStock: updatedLoose,
      lastModified: DateTime.now(),
    );

    await _productBox.put(updatedProduct.id, updatedProduct);
    notifyListeners();
  }

  Future<void> updateStockDetails({
    required String productIdOrName,
    required String stockId,
    int? newQuantity,
    double? newCostPrice,
    double? newRetailPrice,
  }) async {
    try {
      final product = _getProduct(productIdOrName);
      if (product == null) {
        SnackbarService.showWarning("⚠️ Product not found.");
        return;
      }

      final List<ProductStock> updatedStocks = [];
      LooseStock? updatedLoose = product.looseStock;
      final piecesPerPack = product.piecesPerPack;
      StockLog? log;

      for (var stock in product.stocks) {
        if (stock.id == stockId) {
          final oldQty = stock.quantity;
          final updatedQty = newQuantity ?? oldQty;

          if (updatedQty <= 0) continue;

          final updatedStock = stock.copyWith(
            quantity: updatedQty,
            costPrice: newCostPrice ?? stock.costPrice,
            retailPrice: newRetailPrice ?? stock.retailPrice,
            lastModified: DateTime.now(),
          );
          updatedStocks.add(updatedStock);

          if (product.isSoldByPiece && piecesPerPack != null) {
            final diff = (updatedQty - oldQty) * piecesPerPack;
            if (diff != 0) {
              updatedLoose = (product.looseStock ?? LooseStock(remainingPieces: 0, productId: product.id)).copyWith(
                remainingPieces: (product.looseStock?.remainingPieces ?? 0) + diff,
                lastModified: DateTime.now(),
              );
            }
          }

          log = StockLog(
            id: 'log-${DateTime.now().millisecondsSinceEpoch}',
            productId: product.id,
            quantity: updatedQty,
            isPiece: false,
            reason: StockLogReason.adjusted,
            remarks: 'Edited stock: qty $oldQty → $updatedQty',
          );
        } else {
          updatedStocks.add(stock);
        }
      }

      final updatedProduct = product.copyWith(
        stocks: updatedStocks,
        looseStock: updatedLoose,
        lastModified: DateTime.now(),
        logs: log != null ? [...product.logs, log] : product.logs,
      );

      await _productBox.put(updatedProduct.id, updatedProduct);
      notifyListeners();

      SnackbarService.showSuccess("✅ Stock updated and loose pieces synced.");
    } catch (e) {
      SnackbarService.showError("❌ Failed to update stock: $e");
    }
  }
}

