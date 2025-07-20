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
          remarks: 'Sold $deduct pack(s) from stock ${stock.id} in ${product.id}',
        ),
      );

      remainingToDeduct -= deduct;
    }

    // ❌ Not enough stock
    if (remainingToDeduct > 0) return false;

    // ✅ Update loose stock if it exists
    LooseStock? updatedLoose;
    if (product.looseStock != null && product.piecesPerPack != null) {
      final totalPiecesDeducted = quantity * (product.piecesPerPack ?? 0);
      final newRemaining = (product.looseStock!.remainingPieces - totalPiecesDeducted).clamp(0, double.infinity).toInt();

      updatedLoose = product.looseStock!.copyWith(remainingPieces: newRemaining);

      logs.add(
        StockLog(
          id: 'log-${DateTime.now().millisecondsSinceEpoch}-loose',
          productId: product.id,
          quantity: totalPiecesDeducted.toInt(),
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
    // 🚫 Step 1: Quantity sanity check
    if (quantity <= 0) {
      print('❌ Invalid quantity: $quantity');
      return false;
    }

    // 🔍 Step 2: Find the product by ID or name
    final product = _getProduct(productIdOrName);
    if (product == null) {
      print('❌ Product not found: $productIdOrName');
      return false;
    }

    // 📦 Step 3: Prepare loose stock and unit data
    final current = product.looseStock;
    final itemsPerPack = product.piecesPerPack ?? 1;

    // ⚠️ Step 4: Validate that loose stock exists
    if (current == null) {
      print('⚠️ No loose stock found for product ${product.id} product name : ${product.name} ');
      return false;
    }

    // 🧮 Step 5: Check if there's enough loose pieces to sell
    final looseBefore = current.remainingPieces;
    if (looseBefore < quantity) {
      print('⚠️ Not enough loose stock. Requested: $quantity, Available: $looseBefore');
      showDialog(
        context: context,
        builder: (_) => CustomNotificationDialog(
          title: 'Not Enough',
          content: 'Not enough loose stock. Requested: $quantity, Available: $looseBefore',
        ),
      );
      return false;
    }

    // 🔢 Step 6: Calculate new loose stock after selling
    final looseAfter = looseBefore - quantity;

    // 🧠 Step 7: Check how many full packs this sale would deduct
    final fullPacksSold = quantity ~/ itemsPerPack;

    // 🛠️ Step 8: Auto-deduct those packs from the FIFO ProductStock list
    List<ProductStock> updatedStocks = [...product.stocks];
    List<StockLog> logs = [];

    int packsToDeduct = fullPacksSold;
    for (int i = 0; i < updatedStocks.length && packsToDeduct > 0; i++) {
      final stock = updatedStocks[i];
      if (stock.quantity <= 0) continue;

      final deduct = (stock.quantity >= packsToDeduct) ? packsToDeduct : stock.quantity;
      updatedStocks[i] = stock.copyWith(quantity: stock.quantity - deduct);

      // 🧾 Add log for each pack deduction
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

    // 🧾 Step 9: Add log for the actual piece sale
    logs.add(StockLog(
      id: 'log-${DateTime.now().millisecondsSinceEpoch}-${product.id}',
      productId: product.id,
      quantity: quantity,
      isPiece: true,
      reason: StockLogReason.sold,
      remarks: 'Sold $quantity piece(s)',
    ));

    // ✏️ Step 10: Update the loose stock count
    final updatedLoose = current.copyWith(remainingPieces: looseAfter);

    // 🛒 Step 11: Prepare updated product
    final updatedProduct = product.copyWith(
      looseStock: updatedLoose,
      stocks: updatedStocks,
      logs: [...product.logs, ...logs],
      lastModified: DateTime.now(),
    );

    Product? parent;
    try {
      parent = _productBox.values.firstWhere(
            (p) => p.hasVariant && p.variants.any((v) => v.id == product.id),
      );
    } catch (_) {
      parent = null;
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

    // ✅ Step 13: Done! Print confirmation
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

