import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:retailpos/Model/loose_stock.dart';
import 'package:retailpos/Model/product_model.dart';
import 'package:retailpos/Model/product_stock.dart';
import 'package:retailpos/Model/stock_log.dart';
import 'package:retailpos/View/Components/Alert/CustomNotificationDialog.dart';

class ProductStockProvider extends ChangeNotifier {
  final Box<Product> _productBox;

  ProductStockProvider(this._productBox);

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

  Future<bool> sellPack(String productIdOrName, int quantity) async {
    final product = _getProduct(productIdOrName);
    if (product == null) return false;

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

      // 💰 Calculate profit per pack
      final double unitProfit = (stock.retailPrice ?? 0) - (stock.costPrice ?? 0);
      final double totalProfit = unitProfit * deduct;

      logs.add(
        StockLog(
          id: 'log-${DateTime.now().millisecondsSinceEpoch}-${stock.id}',
          productId: product.id,
          quantity: deduct,
          isPiece: false,
          profit: totalProfit,
          reason: StockLogReason.sold,
          remarks: 'Sold $deduct pack(s) from stock ${stock.id} in ${product.id}',
        ),
      );

      remainingToDeduct -= deduct;
    }

    if (remainingToDeduct > 0) return false;

    LooseStock? updatedLoose;
    if (product.looseStock != null && product.piecesPerPack != null) {
      final totalPiecesDeducted = quantity * (product.piecesPerPack ?? 0);
      final newRemaining = (product.looseStock!.remainingPieces - totalPiecesDeducted).clamp(0, double.infinity).toInt();

      updatedLoose = product.looseStock!.copyWith(remainingPieces: newRemaining);

      logs.add(
        StockLog(
          id: 'log-${DateTime.now().millisecondsSinceEpoch}-loose',
          productId: product.id,
          quantity: totalPiecesDeducted,
          isPiece: true,
          reason: StockLogReason.sold,
          remarks: 'Auto-synced: Deducted $totalPiecesDeducted pcs after selling $quantity pack(s)',
        ),
      );
    }

    final updatedProduct = product.copyWith(
      stocks: updatedStocks,
      looseStock: updatedLoose ?? product.looseStock,
      lastModified: DateTime.now(),
      logs: [...product.logs, ...logs],
    );

    Product? parent;
    for (final p in _productBox.values) {
      if (p.hasVariant && p.variants.any((v) => v.id == product.id)) {
        parent = p;
        break;
      }
    }

    if (parent != null) {
      final updatedVariants = parent.variants.map((v) {
        return v.id == product.id ? updatedProduct : v;
      }).toList();

      final updatedParent = parent.copyWith(
        variants: updatedVariants,
        lastModified: DateTime.now(),
      );

      await _productBox.put(updatedParent.id, updatedParent);
    } else {
      await _productBox.put(updatedProduct.id, updatedProduct);
    }

    notifyListeners();

    print('✅ Sold $quantity pack(s) of ${product.name} id ${product.id}');
    if (updatedLoose != null) {
      print('🔁 Auto-synced loose stock. Deducted ${quantity * (product.piecesPerPack ?? 0)} pcs');
    }

    return true;
  }

  Future<bool> sellPiece(String productIdOrName, int quantity, BuildContext context) async {
    if (quantity <= 0) {
      print('❌ Invalid quantity: $quantity');
      return false;
    }

    final product = _getProduct(productIdOrName);
    if (product == null) {
      print('❌ Product not found: $productIdOrName');
      showDialog(
        context: context,
        builder: (_) => CustomNotificationDialog(
          title: 'Product Not Found',
          content: 'The product "$productIdOrName" could not be found in your inventory.',
          onConfirm: () => Navigator.pop(context),
        ),
      );
      return false;
    }

    final looseStock = product.looseStock;
    final itemsPerPack = product.piecesPerPack ?? 1;

    if (looseStock == null) {
      print('⚠️ No loose stock for ${product.name}');
      showDialog(
        context: context,
        builder: (_) => CustomNotificationDialog(
          title: 'Loose Stock Not Available',
          content: 'This product has no loose stock configured. Please set it up before selling by piece.',
          onConfirm: () => Navigator.pop(context),
        ),
      );
      return false;
    }

    final looseBefore = looseStock.remainingPieces;
    if (looseBefore < quantity) {
      print('⚠️ Not enough loose stock. Requested: $quantity, Available: $looseBefore');
      showDialog(
        context: context,
        builder: (_) => CustomNotificationDialog(
          title: 'Not Enough Stock',
          content: 'Only $looseBefore pieces available, but $quantity requested.',
          onConfirm: () => Navigator.pop(context),
        ),
      );
      return false;
    }

    // 🔄 Calculate new loose and pack values
    final looseAfter = looseBefore - quantity;
    final currentPackCount = looseBefore ~/ itemsPerPack;
    final newPackCount = looseAfter ~/ itemsPerPack;
    final packsToDeduct = currentPackCount - newPackCount;

    final updatedLooseStock = looseStock.copyWith(remainingPieces: looseAfter);

    // 💾 Deduct packs from batch stock
    List<ProductStock> updatedStocks = [...product.stocks];
    List<StockLog> logs = [];

    int remainingToDeduct = packsToDeduct;
    for (int i = 0; i < updatedStocks.length && remainingToDeduct > 0; i++) {
      final stock = updatedStocks[i];
      if (stock.quantity <= 0) continue;

      final deduct = (stock.quantity >= remainingToDeduct) ? remainingToDeduct : stock.quantity;
      updatedStocks[i] = stock.copyWith(quantity: stock.quantity - deduct);

      final unitProfit = (stock.retailPrice ?? 0) - (stock.costPrice ?? 0);
      final totalProfit = unitProfit * deduct;

      logs.add(StockLog(
        id: 'log-${DateTime.now().millisecondsSinceEpoch}-pack-${stock.id}',
        productId: product.id,
        quantity: deduct,
        isPiece: false,
        profit: totalProfit,
        reason: StockLogReason.sold,
        remarks: 'Auto-deducted $deduct pack(s) after selling $quantity pcs',
      ));

      remainingToDeduct -= deduct;
    }

    // 🧾 Log the piece sale
    final retailPerPiece = (product.stocks.first.retailPrice ?? 0) / itemsPerPack;
    final costPerPiece = (product.stocks.first.costPrice ?? 0) / itemsPerPack;
    final pieceProfit = (retailPerPiece - costPerPiece) * quantity;

    logs.add(StockLog(
      id: 'log-${DateTime.now().millisecondsSinceEpoch}-${product.id}',
      productId: product.id,
      quantity: quantity,
      isPiece: true,
      profit: pieceProfit,
      reason: StockLogReason.sold,
      remarks: 'Sold $quantity piece(s)',
    ));

    // 🛠 Update product
    final updatedProduct = product.copyWith(
      looseStock: updatedLooseStock,
      stocks: updatedStocks,
      logs: [...product.logs, ...logs],
      lastModified: DateTime.now(),
    );

    // 🔁 Update parent if variant
    Product? parent;
    try {
      parent = _productBox.values.firstWhere(
            (p) => p.hasVariant && p.variants.any((v) => v.id == product.id),
      );
    } catch (_) {
      parent = null;
    }

    if (parent != null) {
      final updatedVariants = parent.variants.map((v) =>
      v.id == product.id ? updatedProduct : v,
      ).toList();

      final updatedParent = parent.copyWith(
        variants: updatedVariants,
        lastModified: DateTime.now(),
      );

      await _productBox.put(updatedParent.id, updatedParent);
      print('🧬 Variant updated under parent: ${updatedParent.name}');
    } else {
      await _productBox.put(updatedProduct.id, updatedProduct);
      print('📦 Product updated: ${updatedProduct.name}');
    }

    notifyListeners();

    // 🧠 Debugging Logs
    print('✅ Sold $quantity pcs of ${product.name}');
    print('🧮 Loose stock: $looseBefore ➡️ $looseAfter');
    print('📦 Pack count: $currentPackCount ➡️ $newPackCount (deducted $packsToDeduct pack[s])');

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

