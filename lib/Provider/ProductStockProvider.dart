import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:mobile_stock_inventory/Model/loose_stock.dart';
import 'package:mobile_stock_inventory/Model/product_model.dart';
import 'package:mobile_stock_inventory/Model/product_stock.dart';
import 'package:mobile_stock_inventory/Model/stock_log.dart';
import 'package:mobile_stock_inventory/View/Components/Alert/CustomNotificationDialog.dart';

class ProductStockProvider extends ChangeNotifier {
  final Box<Product> _productBox;

  ProductStockProvider(this._productBox);

  Product? _getProduct(String idOrName) {
    try {
      // 🔍 First, try matching main products
      return _productBox.values.firstWhere(
            (p) =>
        p.deletedAt == null &&
            (p.id == idOrName ||
                p.name.trim().toLowerCase() == idOrName.trim().toLowerCase()),
      );
    } catch (_) {
      // ❌ Not found in top-level, now check inside variants
      for (final parent in _productBox.values) {
        if (parent.hasVariant && parent.variants.isNotEmpty) {
          try {
            return parent.variants.firstWhere(
                  (v) =>
              v.deletedAt == null &&
                  (v.id == idOrName ||
                      v.name.trim().toLowerCase() ==
                          idOrName.trim().toLowerCase()),
            );
          } catch (_) {
            // ignore and continue
          }
        }
      }
      return null; // 🫥 No match found anywhere
    }
  }


  Future<bool> sellPack(String productIdOrName, int quantity) async {
    final product = _getProduct(productIdOrName);
    if (product == null) return false;

    // Clone & sort FIFO by dateReceived
    final sortedStocks = [...product.stocks]
      ..sort((a, b) => a.dateReceived.compareTo(b.dateReceived));

    int remainingToDeduct = quantity;
    List<ProductStock> updatedStocks = [...product.stocks];
    List<StockLog> logs = [];

    for (final stock in sortedStocks) {
      if (remainingToDeduct <= 0) break;
      if (stock.quantity <= 0) continue;

      final deduct = stock.quantity >= remainingToDeduct
          ? remainingToDeduct
          : stock.quantity;

      final updated = stock.copyWith(quantity: stock.quantity - deduct);
      final index = updatedStocks.indexWhere((s) => s.id == stock.id);
      if (index != -1) updatedStocks[index] = updated;

      logs.add(
        StockLog(
          id: 'log-${DateTime.now().millisecondsSinceEpoch}-${stock.id}',
          productId: product.id,
          quantity: deduct,
          isPiece: false,
          reason: StockLogReason.sold,
          remarks: 'Sold $deduct pack(s) from stock ${stock.id} - ${stock.quantity ?? "N/A"}',
        ),
      );

      remainingToDeduct -= deduct;
    }

    // Not enough stock
    if (remainingToDeduct > 0) return false;

    final updatedProduct = product.copyWith(
      stocks: updatedStocks,
      lastModified: DateTime.now(),
      logs: [...product.logs, ...logs],
    );

    await _productBox.put(updatedProduct.id, updatedProduct);
    notifyListeners();

    return true;
  }

  Future<bool> sellPiece(String productIdOrName, int quantity,BuildContext context) async {
    if (quantity <= 0) {
      print('❌ Invalid quantity: $quantity');
      return false;
    }

    final product = _getProduct(productIdOrName);
    if (product == null) {
      print('❌ Product not found: $productIdOrName');
      return false;
    }

    final current = product.looseStock;
    final itemsPerPack = product.piecesPerPack ?? 1;

    if (current == null) {
      print('⚠️ No loose stock found for product ${product.id}');
      return false;
    }

    final looseBefore = current.remainingPieces;

    if (looseBefore < quantity) {
      print('⚠️ Not enough loose stock. Requested: $quantity, Available: $looseBefore');
      showDialog(context: context, builder: (_) =>  CustomNotificationDialog(title: 'Not Enough', content: 'Not enough loose stock. Requested: $quantity, Available: $looseBefore'));
      return false;
    }

    final looseAfter = looseBefore - quantity;

    /// 🔁 Check how many full packs were "sold" from the loose count
    final fullPacksSold = quantity ~/ itemsPerPack;

    /// 🧮 Deduct that many packs from stock (FIFO style)
    List<ProductStock> updatedStocks = [...product.stocks];
    List<StockLog> logs = [];

    int packsToDeduct = fullPacksSold;
    for (int i = 0; i < updatedStocks.length && packsToDeduct > 0; i++) {
      final stock = updatedStocks[i];
      if (stock.quantity <= 0) continue;

      final deduct = (stock.quantity >= packsToDeduct) ? packsToDeduct : stock.quantity;
      updatedStocks[i] = stock.copyWith(quantity: stock.quantity - deduct);

      logs.add(StockLog(
        id: 'log-${DateTime.now().millisecondsSinceEpoch}-pack-${stock.id}',
        productId: product.id,
        quantity: deduct,
        isPiece: false,
        reason: StockLogReason.sold,
        remarks: 'Auto-synced: $deduct pack(s) deducted after selling $quantity pcs',
      ));

      packsToDeduct -= deduct;
    }

    // 🧾 Log the piece sale itself
    logs.add(StockLog(
      id: 'log-${DateTime.now().millisecondsSinceEpoch}-${product.id}',
      productId: product.id,
      quantity: quantity,
      isPiece: true,
      reason: StockLogReason.sold,
      remarks: 'Sold $quantity piece(s)',
    ));

    final updatedLoose = current.copyWith(
      remainingPieces: looseAfter,
    );

    final updatedProduct = product.copyWith(
      looseStock: updatedLoose,
      stocks: updatedStocks,
      logs: [...product.logs, ...logs],
      lastModified: DateTime.now(),
    );

    await _productBox.put(updatedProduct.id, updatedProduct);
    notifyListeners();

    print('✅ Sold $quantity piece(s) of ${product.name}');
    if (fullPacksSold > 0) {
      print('🔁 Auto-deducted $fullPacksSold pack(s) from ProductStock');
    }

    return true;
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

    } catch (e) {
    }
  }
}

