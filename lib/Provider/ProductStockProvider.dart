import 'package:flutter/foundation.dart';
import 'package:nextpos/core/data/product_store.dart';
import 'package:nextpos/Model/loose_stock.dart';
import 'package:nextpos/Model/product_model.dart';
import 'package:nextpos/Model/product_stock.dart';
import 'package:nextpos/Model/stock_log.dart';
import 'package:nextpos/core/inventory/stock_rules.dart';

class StockOperationResult {
  final bool success;
  final String message;
  final int? previousStock;
  final int? newStock;
  final int? difference;

  const StockOperationResult._({
    required this.success,
    required this.message,
    this.previousStock,
    this.newStock,
    this.difference,
  });

  factory StockOperationResult.success({
    required String message,
    required int previousStock,
    required int newStock,
    int? difference,
  }) {
    return StockOperationResult._(
      success: true,
      message: message,
      previousStock: previousStock,
      newStock: newStock,
      difference: difference,
    );
  }

  factory StockOperationResult.failure(String message) {
    return StockOperationResult._(success: false, message: message);
  }
}

class ProductStockProvider extends ChangeNotifier {
  final ProductStore _productBox = ProductStore.instance;

  Product? _getProduct(String idOrName) {
    final normalized = idOrName.trim().toLowerCase();

    for (final product in _productBox.values) {
      if (product.isSoftDeleted || product.isDeletedPermanent) continue;
      if (product.id.toLowerCase() == normalized ||
          product.name.trim().toLowerCase() == normalized) {
        return product;
      }

      for (final variant in product.variants) {
        if (variant.isSoftDeleted || variant.isDeletedPermanent) continue;
        if (variant.id.toLowerCase() == normalized ||
            variant.name.trim().toLowerCase() == normalized) {
          return variant;
        }
      }
    }
    return null;
  }

  int getCurrentStock(String productIdOrName) {
    return _getProduct(productIdOrName)?.totalQuantity ?? 0;
  }

  Future<StockOperationResult> stockIn({
    required String productId,
    required int quantity,
    String remarks = '',
    double? costPrice,
    double? retailPrice,
  }) async {
    final product = _getProduct(productId);
    if (product == null) {
      return StockOperationResult.failure('Product not found.');
    }

    try {
      final current = StockRules.validateStockValue(product.totalQuantity);
      final newTotal = StockRules.stockIn(current, quantity);
      final now = DateTime.now();
      final lastStock = product.stocks.isNotEmpty ? product.stocks.last : null;

      final batch = ProductStock(
        id: 'stock-in-' + now.microsecondsSinceEpoch.toString(),
        productId: product.id,
        quantity: quantity,
        costPrice: costPrice ?? lastStock?.costPrice ?? 0,
        retailPrice: retailPrice ?? lastStock?.retailPrice ?? 0,
        dateReceived: now,
        lastModified: now,
      );

      final log = StockLog(
        id: 'movement-' + now.microsecondsSinceEpoch.toString(),
        productId: product.id,
        quantity: quantity,
        isPiece: false,
        reason: StockLogReason.stockIn,
        remarks: _movementNote(
          'Stock In',
          current,
          newTotal,
          remarks,
        ),
        dateLogged: now,
        lastModified: now,
      );

      final updated = product.copyWith(
        stocks: [...product.stocks, batch],
        logs: [...product.logs, log],
        lastModified: now,
      );

      await _saveResolvedProduct(product, updated);
      notifyListeners();

      return StockOperationResult.success(
        message: 'Stock In saved. ' +
            product.name +
            ': ' +
            current.toString() +
            ' → ' +
            newTotal.toString() +
            '.',
        previousStock: current,
        newStock: newTotal,
      );
    } on ArgumentError catch (error) {
      return StockOperationResult.failure(error.message.toString());
    }
  }

  Future<StockOperationResult> stockOut({
    required String productId,
    required int quantity,
    String remarks = '',
  }) async {
    final product = _getProduct(productId);
    if (product == null) {
      return StockOperationResult.failure('Product not found.');
    }

    try {
      final current = StockRules.validateStockValue(product.totalQuantity);
      final newTotal = StockRules.stockOut(current, quantity);
      final now = DateTime.now();
      final updatedStocks = _deductFromBatches(product.stocks, quantity);

      final log = StockLog(
        id: 'movement-' + now.microsecondsSinceEpoch.toString(),
        productId: product.id,
        quantity: quantity,
        isPiece: false,
        reason: StockLogReason.stockOut,
        remarks: _movementNote(
          'Stock Out',
          current,
          newTotal,
          remarks,
        ),
        dateLogged: now,
        lastModified: now,
      );

      final updated = product.copyWith(
        stocks: updatedStocks,
        logs: [...product.logs, log],
        lastModified: now,
      );

      await _saveResolvedProduct(product, updated);
      notifyListeners();

      return StockOperationResult.success(
        message: 'Stock Out saved. ' +
            product.name +
            ': ' +
            current.toString() +
            ' → ' +
            newTotal.toString() +
            '.',
        previousStock: current,
        newStock: newTotal,
      );
    } on StateError catch (error) {
      return StockOperationResult.failure(error.message.toString());
    } on ArgumentError catch (error) {
      return StockOperationResult.failure(error.message.toString());
    }
  }

  Future<StockOperationResult> adjustStock({
    required String productId,
    required int actualStock,
    required String reason,
  }) async {
    final product = _getProduct(productId);
    if (product == null) {
      return StockOperationResult.failure('Product not found.');
    }
    if (reason.trim().isEmpty) {
      return StockOperationResult.failure(
        'A reason is required for a stock adjustment.',
      );
    }

    try {
      final current = StockRules.validateStockValue(product.totalQuantity);
      final actual = StockRules.validateStockValue(actualStock);
      final difference = StockRules.adjustmentDifference(current, actual);

      if (difference == 0) {
        return StockOperationResult.failure(
          'Actual stock already matches system stock. No adjustment is needed.',
        );
      }

      final now = DateTime.now();
      List<ProductStock> updatedStocks;

      if (difference > 0) {
        final lastStock = product.stocks.isNotEmpty ? product.stocks.last : null;
        updatedStocks = [
          ...product.stocks,
          ProductStock(
            id: 'adjustment-' + now.microsecondsSinceEpoch.toString(),
            productId: product.id,
            quantity: difference,
            costPrice: lastStock?.costPrice ?? 0,
            retailPrice: lastStock?.retailPrice ?? 0,
            dateReceived: now,
            lastModified: now,
          ),
        ];
      } else {
        updatedStocks = _deductFromBatches(
          product.stocks,
          difference.abs(),
        );
      }

      final signedDifference =
          (difference > 0 ? '+' : '') + difference.toString();
      final log = StockLog(
        id: 'movement-' + now.microsecondsSinceEpoch.toString(),
        productId: product.id,
        quantity: difference,
        isPiece: false,
        reason: StockLogReason.stockAdjustment,
        remarks: 'Adjustment • System ' +
            current.toString() +
            ' → Actual ' +
            actual.toString() +
            ' • Difference ' +
            signedDifference +
            ' • ' +
            reason.trim(),
        dateLogged: now,
        lastModified: now,
      );

      final updated = product.copyWith(
        stocks: updatedStocks,
        logs: [...product.logs, log],
        lastModified: now,
      );

      await _saveResolvedProduct(product, updated);
      notifyListeners();

      return StockOperationResult.success(
        message: 'Adjustment saved. ' +
            product.name +
            ': ' +
            current.toString() +
            ' → ' +
            actual.toString() +
            ' (' +
            signedDifference +
            ').',
        previousStock: current,
        newStock: actual,
        difference: difference,
      );
    } on ArgumentError catch (error) {
      return StockOperationResult.failure(error.message.toString());
    }
  }

  Future<void> updateLooseStock(
    String productIdOrName,
    int remainingPieces,
  ) async {
    final product = _getProduct(productIdOrName);
    if (product == null || product.looseStock == null) return;
    if (remainingPieces < 0) return;

    final updated = product.copyWith(
      looseStock: product.looseStock!.copyWith(
        remainingPieces: remainingPieces,
        lastModified: DateTime.now(),
      ),
      lastModified: DateTime.now(),
    );

    await _saveResolvedProduct(product, updated);
    notifyListeners();
  }

  List<ProductStock> _deductFromBatches(
    List<ProductStock> stocks,
    int quantity,
  ) {
    var remaining = quantity;
    final ordered = [...stocks]
      ..sort((a, b) => a.dateReceived.compareTo(b.dateReceived));
    final byId = <String, ProductStock>{
      for (final stock in stocks) stock.id: stock,
    };

    for (final stock in ordered) {
      if (remaining <= 0) break;
      if (stock.quantity <= 0) continue;

      final deduct = stock.quantity >= remaining ? remaining : stock.quantity;
      byId[stock.id] = stock.copyWith(
        quantity: stock.quantity - deduct,
        lastModified: DateTime.now(),
      );
      remaining -= deduct;
    }

    if (remaining > 0) {
      throw StateError('Insufficient stock for this transaction.');
    }

    return stocks.map((stock) => byId[stock.id] ?? stock).toList();
  }

  Future<void> _saveResolvedProduct(
    Product original,
    Product updated,
  ) async {
    for (final parent in _productBox.values) {
      final index =
          parent.variants.indexWhere((variant) => variant.id == original.id);
      if (index == -1) continue;

      final List<Product> variants = List<Product>.from(parent.variants);
      variants[index] = updated;
      final updatedParent = parent.copyWith(
        variants: variants,
        lastModified: updated.lastModified,
      );
      await _productBox.put(updatedParent.id, updatedParent);
      return;
    }

    await _productBox.put(updated.id, updated);
  }

  String _movementNote(
    String type,
    int before,
    int after,
    String remarks,
  ) {
    final note = remarks.trim();
    return type +
        ' • ' +
        before.toString() +
        ' → ' +
        after.toString() +
        (note.isEmpty ? '' : ' • ' + note);
  }
}
