import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:nextpos/Helper/Classes_Methods/helper_methods.dart';
import 'package:nextpos/Model/loan_item.dart';
import 'package:nextpos/Model/loose_stock.dart';
import 'package:nextpos/Model/product_model.dart';
import 'package:nextpos/Model/product_stock.dart';
import 'package:nextpos/Model/stock_log.dart';
import 'package:nextpos/View/Components/Alert/CustomNotificationDialog.dart';
import 'package:nextpos/core/data/offline_database.dart';

class InventoryMutationResult {
  final bool success;
  final String message;

  const InventoryMutationResult.success(this.message) : success = true;
  const InventoryMutationResult.failure(this.message) : success = false;
}

class ProductStockProvider extends ChangeNotifier {
  final Box<Product> _productBox = Hive.box<Product>('products');
  final _offlineDatabase = OfflineDatabase.instance;

  Future<void> _mirror(Product product) async {
    try {
      await _offlineDatabase.upsertProduct(product);
    } catch (_) {}
  }

  ProductStockProvider();

  Product? _getProduct(String idOrName) {
    final normalized = idOrName.trim().toLowerCase();

    for (final product in _productBox.values) {
      if (product.isSoftDeleted) continue;

      // 🔍 Match main product
      if (product.id.toLowerCase() == normalized ||
          product.name.trim().toLowerCase() == normalized) {
        return product;
      }

      // 🔍 Match from variants
      if (product.hasVariant && product.variants.isNotEmpty) {
        for (final variant in product.variants.whereType<Product>()) {
          if (variant.isSoftDeleted) continue;

          if (variant.id.toLowerCase() == normalized ||
              variant.name.trim().toLowerCase() == normalized) {
            return variant;
          }
        }
      }
    }

    return null;
  }

  Future<bool> sellPack(
    String productIdOrName,
    int quantity,
    StockLogReason reason, // <- added here
    bool isSellingINPiece, {
    bool isLoan = false,
    String borrowName = 'Unknown',
  }) async {
    final product = _getProduct(productIdOrName);
    if (product == null) {
      print('❌ Product not found: $productIdOrName');
      return false;
    }

    print('🟡 DEBUG: isLoan = $isLoan, borrowName = $borrowName');

    final sortedStocks = [...product.stocks]
      ..sort((a, b) => a.dateReceived.compareTo(b.dateReceived));
    int remainingToDeduct = quantity;
    List<ProductStock> updatedStocks = [...product.stocks];
    List<StockLog> logs = [];

    print(
      '🛒 ${isLoan ? 'Loaning' : reason.name} $quantity pack(s) of ${product.name}',
    );
    print('📦 Initial stocks:');
    for (final s in sortedStocks) {
      print(' - ${s.id} | qty: ${s.quantity} | received: ${s.dateReceived}');
    }

    double totalProfit = 0;

    for (final stock in sortedStocks) {
      if (remainingToDeduct <= 0) break;
      if (stock.quantity <= 0) continue;

      final deduct = stock.quantity >= remainingToDeduct
          ? remainingToDeduct
          : stock.quantity;

      final updated = stock.copyWith(quantity: stock.quantity - deduct);
      final index = updatedStocks.indexWhere((s) => s.id == stock.id);
      if (index != -1) updatedStocks[index] = updated;

      final unitProfit = stock.retailPrice - stock.costPrice;
      totalProfit = unitProfit * deduct;

      remainingToDeduct -= deduct;
    }

    if (remainingToDeduct > 0) {
      print(
        '❗ Not enough stock to fulfill request. Needed $quantity, could only deduct ${quantity - remainingToDeduct}.',
      );
      return false;
    }

    LooseStock? updatedLoose;
    if (product.looseStock != null && product.piecesPerPack != null) {
      final totalPiecesDeducted = quantity * product.piecesPerPack!;
      final newRemaining =
          (product.looseStock!.remainingPieces - totalPiecesDeducted)
              .clamp(0, double.infinity)
              .toInt();

      updatedLoose = product.looseStock!.copyWith(
        remainingPieces: newRemaining,
      );

      logs.add(
        StockLog(
          id: 'log-${DateTime.now().millisecondsSinceEpoch}-loose',
          productId: product.id,
          profit: totalProfit,
          quantity: quantity,
          isPiece: isSellingINPiece,
          reason: isLoan
              ? StockLogReason.borrowed
              : reason, // ✅ use passed reason
          remarks: isLoan
              ? 'Loaned out $quantity pack(s) • $totalPiecesDeducted pcs deducted from inventory'
              : '${reason.name} $quantity pack(s) • Deducted $totalPiecesDeducted pcs from stock',
        ),
      );

      print(
        '🔁 Synced loose stock: -$totalPiecesDeducted pcs, newRemaining: $newRemaining',
      );
    } else {
      print('⚠️ Skipped loose stock sync: looseStock or piecesPerPack is null');
    }

    LoanItem? loanItem;
    if (isLoan) {
      final double unitPrice = updatedStocks.first.retailPrice;
      final double loanAmount = unitPrice * quantity;

      loanItem = LoanItem(
        productId: product.id,
        name: product.name,
        price: unitPrice,
        quantity: quantity,
        imagePath: product.imagePath,
        barcode: product.barcode,
        borrowerName: borrowName,
        loanDate: DateTime.now(),
        amount: loanAmount,
        paid: 0.0,
        isReturned: false,
        returnDate: null,
      );

      print('📋 LoanItem created for $borrowName | ₱$loanAmount total');
    }

    final updatedProduct = product.copyWith(
      stocks: updatedStocks,
      looseStock: updatedLoose ?? product.looseStock,
      lastModified: DateTime.now(),
      logs: [...product.logs, ...logs],
      loans: loanItem != null
          ? [...(product.loans ?? []), loanItem]
          : product.loans,
    );

    Product? parent;
    for (final p in _productBox.values) {
      if (p.hasVariant && p.variants.any((v) => v.id == product.id)) {
        parent = p;
        print('🔄 Found parent product: ${parent.id}');
        break;
      }
    }

    if (parent != null) {
      final updatedVariants = parent.variants
          .map((v) => v.id == product.id ? updatedProduct : v)
          .toList();

      final updatedParent = parent.copyWith(
        variants: updatedVariants,
        lastModified: DateTime.now(),
      );

      await _productBox.put(updatedParent.id, updatedParent);
      await _mirror(updatedParent);
      print('📦 Updated parent with new variant info');
    } else {
      await _productBox.put(updatedProduct.id, updatedProduct);
      await _mirror(updatedProduct);
      print('📦 Updated main product entry directly');
    }

    notifyListeners();

    return true;
  }

  Future<bool> sellItemsPerPack(
    String productIdOrName,
    int quantity,
    StockLogReason reason,
    BuildContext context, {
    bool isLoan = false,
    String borrowName = 'Unknown',
  }) async {
    if (quantity <= 0) {
      print('❌ Invalid quantity: $quantity');
      return false;
    }

    final product = _getProduct(productIdOrName);
    if (product == null) {
      showDialog(
        context: context,
        builder: (_) => CustomNotificationDialog(
          title: 'Product Not Found',
          content:
              'The product "$productIdOrName" could not be found in your inventory.',
          onConfirm: () => Navigator.pop(context),
        ),
      );
      return false;
    }

    final looseStock = product.looseStock;
    final itemsPerPack = product.piecesPerPack ?? 1;

    if (looseStock == null) {
      showDialog(
        context: context,
        builder: (_) => CustomNotificationDialog(
          title: 'Loose Stock Not Available',
          content:
              'This product has no loose stock configured. Please set it up before selling by piece.',
          onConfirm: () => Navigator.pop(context),
        ),
      );
      return false;
    }

    final looseBefore = looseStock.remainingPieces;
    if (looseBefore < quantity) {
      showDialog(
        context: context,
        builder: (_) => CustomNotificationDialog(
          title: 'Not Enough Stock',
          content:
              'Only $looseBefore pieces available, but $quantity requested.',
          onConfirm: () => Navigator.pop(context),
        ),
      );
      return false;
    }

    final looseAfter = looseBefore - quantity;
    final currentPackCount = looseBefore ~/ itemsPerPack;
    final newPackCount = looseAfter ~/ itemsPerPack;
    final packsToDeduct = currentPackCount - newPackCount;

    final updatedLooseStock = looseStock.copyWith(remainingPieces: looseAfter);
    List<ProductStock> updatedStocks = [...product.stocks];
    double totalPackProfit = 0;
    int remainingToDeduct = packsToDeduct;

    for (int i = 0; i < updatedStocks.length && remainingToDeduct > 0; i++) {
      final stock = updatedStocks[i];
      if (stock.quantity <= 0) continue;

      final deduct = stock.quantity >= remainingToDeduct
          ? remainingToDeduct
          : stock.quantity;
      updatedStocks[i] = stock.copyWith(quantity: stock.quantity - deduct);

      final unitProfit = (stock.retailPrice) - (stock.costPrice);
      totalPackProfit += unitProfit * deduct;
      remainingToDeduct -= deduct;
    }

    final retailPerPiece = (product.stocks.first.retailPrice) / itemsPerPack;
    final costPerPiece = (product.stocks.first.costPrice) / itemsPerPack;
    final pieceProfit = (retailPerPiece - costPerPiece) * quantity;
    final totalProfit = totalPackProfit + pieceProfit;

    final singleLog = StockLog(
      id: 'log-${DateTime.now().millisecondsSinceEpoch}-${product.id}',
      productId: product.id,
      quantity: quantity,
      isPiece: true,
      profit: totalProfit,
      reason: isLoan ? StockLogReason.borrowed : reason,
      remarks:
          '${isLoan ? 'Loaned' : reason.name} $quantity pcs, auto-deducted $packsToDeduct pack(s)',
    );

    print(singleLog.quantity);
    LoanItem? loanItem;
    if (isLoan) {
      final firstAvailableStock = updatedStocks.firstWhere(
        (s) => s.retailPrice != null,
        orElse: () => updatedStocks.first,
      );

      final double unitPrice = firstAvailableStock.retailPrice ?? 0;
      final double loanAmount = unitPrice * quantity;

      loanItem = LoanItem(
        productId: product.id,
        name: product.name,
        price: unitPrice,
        quantity: quantity,
        imagePath: product.imagePath,
        barcode: product.barcode,
        borrowerName: borrowName,
        loanDate: DateTime.now(),
        amount: loanAmount,
        paid: 0.0,
        isReturned: false,
        returnDate: null,
      );

      print('📋 New loan created: ₱$loanAmount from $borrowName');
    }

    final updatedProduct = product.copyWith(
      looseStock: updatedLooseStock,
      stocks: updatedStocks,
      logs: [...product.logs, singleLog],
      loans: loanItem != null ? [...product.loans, loanItem] : product.loans,
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
      final updatedVariants = parent.variants
          .map((v) => v.id == product.id ? updatedProduct : v)
          .toList();
      final updatedParent = parent.copyWith(
        variants: updatedVariants,
        lastModified: DateTime.now(),
      );
      await _productBox.put(updatedParent.id, updatedParent);
      await _mirror(updatedParent);
      print('🧬 Variant updated under parent: ${updatedParent.name}');
    } else {
      await _productBox.put(updatedProduct.id, updatedProduct);
      await _mirror(updatedProduct);
      print('📦 Product updated: ${updatedProduct.name}');
    }

    notifyListeners();

    print('🧮 Loose stock: $looseBefore ➡️ $looseAfter');
    print(
      '📦 Pack count: $currentPackCount ➡️ $newPackCount (deducted $packsToDeduct pack[s])',
    );

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
    await _mirror(updatedProduct);
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
    await _mirror(updatedProduct);
    notifyListeners();
  }

  Future<void> updateLooseStock(
    String productIdOrName,
    int remainingPieces,
  ) async {
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
    await _mirror(updatedProduct);
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
              updatedLoose =
                  (product.looseStock ??
                          LooseStock(remainingPieces: 0, productId: product.id))
                      .copyWith(
                        remainingPieces:
                            (product.looseStock?.remainingPieces ?? 0) + diff,
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
      await _mirror(updatedProduct);
      notifyListeners();
    } catch (e) {}
  }

  List<Product> getProductsByStockRange({
    required int minQty,
    required int maxQty,
    required BuildContext context,
  }) {
    final List<Product> matchingProducts = [];

    for (final product in _productBox.values) {
      if (product.isSoftDeleted) continue;

      // 🔢 Calculate total quantity from all ProductStock entries
      final int totalQty = product.stocks.fold(0, (sum, s) => sum + s.quantity);

      if (totalQty >= minQty && totalQty <= maxQty) {
        matchingProducts.add(product);
      }

      // 🔍 Check variants if any
      if (product.hasVariant && product.variants.isNotEmpty) {
        for (final variant in product.variants.whereType<Product>()) {
          if (variant.isSoftDeleted) continue;

          final int variantQty = variant.stocks.fold(
            0,
            (sum, s) => sum + s.quantity,
          );

          if (variantQty >= minQty && variantQty <= maxQty) {
            matchingProducts.add(variant);
          }
        }
      }
    }

    return matchingProducts;
  }

  Future<void> _persistInventoryMutation(
    Product original,
    Product updated,
  ) async {
    Product? parent;

    for (final candidate in _productBox.values) {
      if (candidate.hasVariant &&
          candidate.variants.any((variant) => variant.id == original.id)) {
        parent = candidate;
        break;
      }
    }

    if (parent != null) {
      final updatedParent = parent.copyWith(
        variants: parent.variants
            .map((variant) => variant.id == original.id ? updated : variant)
            .toList(),
        lastModified: updated.lastModified,
      );
      await _productBox.put(updatedParent.id, updatedParent);
      await _mirror(updatedParent);
    } else {
      await _productBox.put(updated.id, updated);
      await _mirror(updated);
    }

    notifyListeners();
  }

  /// Inventory-first stock in action used by the simplified BantayStock UI.
  Future<InventoryMutationResult> stockIn({
    required String productIdOrName,
    required int quantity,
  }) async {
    if (quantity <= 0) {
      return const InventoryMutationResult.failure(
        'Enter a quantity greater than zero.',
      );
    }

    final product = _getProduct(productIdOrName);
    if (product == null) {
      return const InventoryMutationResult.failure('Product not found.');
    }

    final now = DateTime.now();
    final stocks = [...product.stocks];

    if (stocks.isEmpty) {
      stocks.add(
        ProductStock(
          id: 'stock-${product.id}-${now.microsecondsSinceEpoch}',
          productId: product.id,
          quantity: quantity,
          costPrice: 0,
          retailPrice: 0,
          dateReceived: now,
          lastModified: now,
        ),
      );
    } else {
      final latest = stocks.last;
      stocks[stocks.length - 1] = latest.copyWith(
        quantity: latest.quantity + quantity,
        lastModified: now,
      );
    }

    LooseStock? looseStock = product.looseStock;
    if (product.isSoldByPiece && product.piecesPerPack != null) {
      final piecesAdded = quantity * product.piecesPerPack!;
      looseStock =
          (looseStock ??
                  LooseStock(
                    remainingPieces: 0,
                    productId: product.id,
                  ))
              .copyWith(
                remainingPieces:
                    (looseStock?.remainingPieces ?? 0) + piecesAdded,
                lastModified: now,
              );
    }

    final updated = product.copyWith(
      stocks: stocks,
      looseStock: looseStock,
      lastModified: now,
      logs: [
        ...product.logs,
        StockLog(
          id: 'log-${product.id}-in-${now.microsecondsSinceEpoch}',
          productId: product.id,
          quantity: quantity,
          isPiece: false,
          reason: StockLogReason.restocked,
          remarks: 'Stock In: +$quantity',
          dateLogged: now,
          lastModified: now,
        ),
      ],
    );

    await _persistInventoryMutation(product, updated);
    return InventoryMutationResult.success(
      'Added $quantity to ${product.name}.',
    );
  }

  /// Inventory-first stock out action. It never allows negative inventory.
  Future<InventoryMutationResult> stockOut({
    required String productIdOrName,
    required int quantity,
  }) async {
    if (quantity <= 0) {
      return const InventoryMutationResult.failure(
        'Enter a quantity greater than zero.',
      );
    }

    final product = _getProduct(productIdOrName);
    if (product == null) {
      return const InventoryMutationResult.failure('Product not found.');
    }

    final available =
        product.stocks.fold<int>(0, (total, stock) => total + stock.quantity);

    if (quantity > available) {
      return InventoryMutationResult.failure(
        'Only $available available. Stock cannot go below zero.',
      );
    }

    final now = DateTime.now();
    var remaining = quantity;
    final stocks = [...product.stocks]
      ..sort((a, b) => a.dateReceived.compareTo(b.dateReceived));

    final updatedStocks = <ProductStock>[];
    for (final stock in stocks) {
      if (remaining <= 0 || stock.quantity <= 0) {
        updatedStocks.add(stock);
        continue;
      }

      final deducted =
          remaining > stock.quantity ? stock.quantity : remaining;
      updatedStocks.add(
        stock.copyWith(
          quantity: stock.quantity - deducted,
          lastModified: now,
        ),
      );
      remaining -= deducted;
    }

    LooseStock? looseStock = product.looseStock;
    if (looseStock != null &&
        product.isSoldByPiece &&
        product.piecesPerPack != null) {
      final piecesRemoved = quantity * product.piecesPerPack!;
      final nextPieces =
          (looseStock.remainingPieces - piecesRemoved).clamp(0, 1 << 31).toInt();
      looseStock = looseStock.copyWith(
        remainingPieces: nextPieces,
        lastModified: now,
      );
    }

    final updated = product.copyWith(
      stocks: updatedStocks,
      looseStock: looseStock,
      lastModified: now,
      logs: [
        ...product.logs,
        StockLog(
          id: 'log-${product.id}-out-${now.microsecondsSinceEpoch}',
          productId: product.id,
          quantity: quantity,
          isPiece: false,
          reason: StockLogReason.consumed,
          remarks: 'Stock Out: -$quantity',
          dateLogged: now,
          lastModified: now,
        ),
      ],
    );

    await _persistInventoryMutation(product, updated);
    return InventoryMutationResult.success(
      'Removed $quantity from ${product.name}.',
    );
  }

  /// Reconciles system stock with a physical count.
  Future<InventoryMutationResult> adjustStockCount({
    required String productIdOrName,
    required int physicalCount,
  }) async {
    if (physicalCount < 0) {
      return const InventoryMutationResult.failure(
        'Physical count cannot be negative.',
      );
    }

    final product = _getProduct(productIdOrName);
    if (product == null) {
      return const InventoryMutationResult.failure('Product not found.');
    }

    final now = DateTime.now();
    final previousCount =
        product.stocks.fold<int>(0, (total, stock) => total + stock.quantity);
    final difference = physicalCount - previousCount;
    final stocks = [...product.stocks];

    if (stocks.isEmpty) {
      if (physicalCount > 0) {
        stocks.add(
          ProductStock(
            id: 'stock-${product.id}-${now.microsecondsSinceEpoch}',
            productId: product.id,
            quantity: physicalCount,
            costPrice: 0,
            retailPrice: 0,
            dateReceived: now,
            lastModified: now,
          ),
        );
      }
    } else {
      for (var i = 0; i < stocks.length; i++) {
        stocks[i] = stocks[i].copyWith(
          quantity: i == stocks.length - 1 ? physicalCount : 0,
          lastModified: now,
        );
      }
    }

    LooseStock? looseStock = product.looseStock;
    if (product.isSoldByPiece && product.piecesPerPack != null) {
      final pieceCount = physicalCount * product.piecesPerPack!;
      looseStock =
          (looseStock ??
                  LooseStock(
                    remainingPieces: 0,
                    productId: product.id,
                  ))
              .copyWith(
                remainingPieces: pieceCount,
                lastModified: now,
              );
    }

    final updated = product.copyWith(
      stocks: stocks,
      looseStock: looseStock,
      lastModified: now,
      logs: [
        ...product.logs,
        StockLog(
          id: 'log-${product.id}-adjust-${now.microsecondsSinceEpoch}',
          productId: product.id,
          quantity: difference.abs(),
          isPiece: false,
          reason: StockLogReason.adjusted,
          remarks:
              'Physical count: $previousCount → $physicalCount (${difference >= 0 ? '+' : ''}$difference)',
          dateLogged: now,
          lastModified: now,
        ),
      ],
    );

    await _persistInventoryMutation(product, updated);
    return InventoryMutationResult.success(
      'Adjusted ${product.name} to $physicalCount.',
    );
  }

}
