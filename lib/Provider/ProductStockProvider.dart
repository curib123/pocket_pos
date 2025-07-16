import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:mobile_pos_inventory/Model/product_model.dart';
import 'package:mobile_pos_inventory/Model/product_stock.dart';
import 'package:mobile_pos_inventory/Model/stock_log.dart';
import 'package:mobile_pos_inventory/View/Components/SnackbarService.dart';

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

  /// Deduct packs using FIFO, unpack loose pieces if needed, and auto-log everything
  Future<void> sellPack(String idOrName, int packs) async {
    final product = _getProduct(idOrName);
    if (product == null) return SnackbarService.showWarning("⚠️ Not found.");

    if (!product.isSoldByPack) {
      return SnackbarService.showWarning("⚠️ Not sold by pack.");
    }

    int toRemove = packs;
    final sorted = [...product.stocks]..sort((a, b) => a.dateReceived.compareTo(b.dateReceived));
    final List<ProductStock> updatedStocks = [];

    for (var s in sorted) {
      if (toRemove <= 0) { updatedStocks.add(s); continue; }
      if (s.quantity > toRemove) {
        updatedStocks.add(s.copyWith(quantity: s.quantity - toRemove, lastModified: DateTime.now()));
        toRemove = 0;
      } else {
        toRemove -= s.quantity;
      }
    }

    if (toRemove > 0) return SnackbarService.showWarning("⚠️ Not enough packs.");

    if (product.piecesPerPack == null) {
      throw Exception("Product must have piecesPerPack to unpack.");
    }

    final unpackedPieces = packs * product.piecesPerPack!;

    final loose = product.looseStock?.copyWith(
      remainingPieces: (product.looseStock?.remainingPieces ?? 0) + unpackedPieces,
      lastModified: DateTime.now(),
    );

    // log pack sale
    final packLog = StockLog(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      productId: product.id,
      quantity: packs,
      isPiece: false,
      reason: StockOutType.sold,
      remarks: 'Sold $packs pack(s)',
    );

    final updatedProduct = product.copyWith(
      stocks: updatedStocks,
      looseStock: loose,
      logs: [...product.logs, packLog],
      lastModified: DateTime.now(),
    );

    await _productBox.put(updatedProduct.id, updatedProduct);
    notifyListeners();
    SnackbarService.showSuccess("✅ Sold $packs pack(s) and unpacked $unpackedPieces pcs.");
  }

  /// Sell loose pieces (pieces coming from looseStock), auto-log
  Future<void> sellPiece(String idOrName, int qty) async {
    final product = _getProduct(idOrName);
    if (product == null) return SnackbarService.showWarning("⚠️ Not found.");

    if (!product.isSoldByPiece || product.looseStock == null) {
      return SnackbarService.showWarning("⚠️ Not sold by piece.");
    }

    if (product.looseStock!.remainingPieces < qty) {
      return SnackbarService.showWarning("⚠️ Not enough pieces.");
    }

    final newLoose = product.looseStock!.copyWith(
      remainingPieces: product.looseStock!.remainingPieces - qty,
      lastModified: DateTime.now(),
    );

    final pieceLog = StockLog(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      productId: product.id,
      quantity: qty,
      isPiece: true,
      reason: StockOutType.sold,
      remarks: 'Sold $qty piece(s)',
    );

    final updatedProduct = product.copyWith(
      looseStock: newLoose,
      logs: [...product.logs, pieceLog],
      lastModified: DateTime.now(),
    );

    await _productBox.put(updatedProduct.id, updatedProduct);
    notifyListeners();
    SnackbarService.showSuccess("✅ Sold $qty piece(s).");
  }

  /// 📦 Get all stock entries (newest first)
  List<ProductStock> getStocks(String idOrName) {
    final product = _getProduct(idOrName);
    return product?.stocks.reversed.toList() ?? [];
  }

  /// ➕ Add new stock entry
  Future<void> addStock(String idOrName, ProductStock newStock) async {
    try {
      final product = _getProduct(idOrName);
      if (product == null) {
        SnackbarService.showWarning("⚠️ Product not found.");
        return;
      }

      final updated = product.copyWith(
        stocks: [...product.stocks, newStock],
        lastModified: DateTime.now(),
      );

      await _productBox.put(updated.id, updated);
      notifyListeners();
      SnackbarService.showSuccess("✅ Stock added.");
    } catch (e) {
      SnackbarService.showError("❌ Failed to add stock: $e");
    }
  }

  /// 🛠️ Update a specific stock (quantity, cost, retail)
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

      for (var stock in product.stocks) {
        if (stock.id == stockId) {
          final updatedQty = newQuantity ?? stock.quantity;
          if (updatedQty <= 0) continue; // Remove 0-qty stock

          final updatedStock = stock.copyWith(
            quantity: updatedQty,
            costPrice: newCostPrice ?? stock.costPrice,
            retailPrice: newRetailPrice ?? stock.retailPrice,
            lastModified: DateTime.now(),
          );
          updatedStocks.add(updatedStock);
        } else {
          updatedStocks.add(stock);
        }
      }

      final updatedProduct = product.copyWith(
        stocks: updatedStocks,
        lastModified: DateTime.now(),
      );

      await _productBox.put(updatedProduct.id, updatedProduct);
      notifyListeners();
      SnackbarService.showSuccess("✅ Stock updated.");
    } catch (e) {
      SnackbarService.showError("❌ Failed to update stock: $e");
    }
  }

  /// 🚚 Deduct quantity FIFO-style
  Future<void> deductQuantityFifo(String idOrName, int quantityToDeduct) async {
    try {
      final product = _getProduct(idOrName);
      if (product == null) {
        SnackbarService.showWarning("⚠️ Product not found.");
        return;
      }

      if (quantityToDeduct <= 0) {
        SnackbarService.showWarning("⚠️ Quantity must be positive.");
        return;
      }

      final List<ProductStock> sortedStocks = [...product.stocks]
        ..sort((a, b) => a.dateReceived.compareTo(b.dateReceived));

      final List<ProductStock> updatedStocks = [];
      int remaining = quantityToDeduct;

      for (var stock in sortedStocks) {
        if (remaining <= 0) {
          updatedStocks.add(stock);
          continue;
        }

        if (stock.quantity > remaining) {
          updatedStocks.add(stock.copyWith(
            quantity: stock.quantity - remaining,
            lastModified: DateTime.now(),
          ));
          remaining = 0;
        } else {
          remaining -= stock.quantity;
          // stock.quantity == 0, so skip adding it
        }
      }

      if (remaining > 0) {
        SnackbarService.showWarning("⚠️ Not enough stock.");
        return;
      }

      final updatedProduct = product.copyWith(
        stocks: updatedStocks,
        lastModified: DateTime.now(),
      );

      await _productBox.put(updatedProduct.id, updatedProduct);
      notifyListeners();
      SnackbarService.showSuccess("✅ Deducted $quantityToDeduct item(s).");
    } catch (e) {
      SnackbarService.showError("❌ Deduction failed: $e");
    }
  }

  Future<void> updateRetailPrice({
    required String productIdOrName,
    required String stockId,
    required double newRetailPrice,
  }) async {
    try {
      final product = _getProduct(productIdOrName);
      if (product == null) {
        SnackbarService.showWarning("⚠️ Product not found.");
        return;
      }

      final updatedStocks = product.stocks.map((s) {
        if (s.id == stockId) {
          return s.copyWith(
            retailPrice: newRetailPrice,
            lastModified: DateTime.now(),
          );
        }
        return s;
      }).toList();

      final updatedProduct = product.copyWith(
        stocks: updatedStocks,
        lastModified: DateTime.now(),
      );

      await _productBox.put(updatedProduct.id, updatedProduct);
      notifyListeners();
      SnackbarService.showSuccess("✅ Retail price updated.");
    } catch (e) {
      SnackbarService.showError("❌ Failed to update retail price: $e");
    }
  }

  Future<void> updateCostPrice({
    required String productIdOrName,
    required String stockId,
    required double newCostPrice,
  }) async {
    try {
      final product = _getProduct(productIdOrName);
      if (product == null) {
        SnackbarService.showWarning("⚠️ Product not found.");
        return;
      }

      final updatedStocks = product.stocks.map((s) {
        if (s.id == stockId) {
          return s.copyWith(
            costPrice: newCostPrice,
            lastModified: DateTime.now(),
          );
        }
        return s;
      }).toList();

      final updatedProduct = product.copyWith(
        stocks: updatedStocks,
        lastModified: DateTime.now(),
      );

      await _productBox.put(updatedProduct.id, updatedProduct);
      notifyListeners();
      SnackbarService.showSuccess("✅ Cost price updated.");
    } catch (e) {
      SnackbarService.showError("❌ Failed to update cost price: $e");
    }
  }

  /// ❌ Delete a stock entry by stockId
  Future<void> deleteStock(String idOrName, String stockId) async {
    try {
      final product = _getProduct(idOrName);
      if (product == null) {
        SnackbarService.showWarning("⚠️ Product not found.");
        return;
      }

      final updatedStocks =
      product.stocks.where((s) => s.id != stockId).toList();

      final updatedProduct = product.copyWith(
        stocks: updatedStocks,
        lastModified: DateTime.now(),
      );

      await _productBox.put(updatedProduct.id, updatedProduct);
      notifyListeners();
      SnackbarService.showSuccess("🗑️ Stock deleted.");
    } catch (e) {
      SnackbarService.showError("❌ Failed to delete stock: $e");
    }
  }

  /// 🧼 Clear all stock entries
  Future<void> clearStocks(String idOrName) async {
    try {
      final product = _getProduct(idOrName);
      if (product == null) {
        SnackbarService.showWarning("⚠️ Product not found.");
        return;
      }

      final updatedProduct = product.copyWith(
        stocks: [],
        lastModified: DateTime.now(),
      );

      await _productBox.put(product.id, updatedProduct);
      notifyListeners();
      SnackbarService.showSuccess("🧹 All stocks cleared.");
    } catch (e) {
      SnackbarService.showError("❌ Failed to clear stocks: $e");
    }
  }

  /// 🔢 Total quantity (across all non-null stocks)
  int getTotalQuantity(String idOrName) {
    final product = _getProduct(idOrName);
    if (product == null || product.stocks.isEmpty) return 0;

    return product.stocks.fold<int>(0, (sum, s) => sum + (s.quantity));
  }


  /// 💰 Weighted average cost
  double getAverageCostPrice(String idOrName) {
    final product = _getProduct(idOrName);
    if (product == null || product.stocks.isEmpty) return 0.0;

    double totalCost = 0.0;
    int totalQty = 0;

    for (var s in product.stocks) {
      totalCost += s.costPrice * s.quantity;
      totalQty += s.quantity;
    }

    return totalQty > 0 ? totalCost / totalQty : 0.0;
  }

  /// 🏷️ Get latest retail price
  double getLatestRetailPrice(String idOrName) {
    final product = _getProduct(idOrName);
    if (product == null || product.stocks.isEmpty) return 0.0;
    return product.stocks.last.retailPrice;
  }

  /// 🕰️ Get most recent stock
  ProductStock? getLatestStock(String idOrName) {
    final product = _getProduct(idOrName);
    if (product == null || product.stocks.isEmpty) return null;
    return product.stocks.last;
  }

  /// 🔍 Get specific stock
  ProductStock? getStockById(String idOrName, String stockId) {
    final product = _getProduct(idOrName);
    try {
      return product?.stocks.firstWhere((s) => s.id == stockId);
    } catch (_) {
      return null;
    }
  }

  /// 🧠 Sale conditions
  bool canSellByPack(String idOrName) =>
      _getProduct(idOrName)?.isSoldByPack ?? false;

  bool canSellByPiece(String idOrName) =>
      _getProduct(idOrName)?.isSoldByPiece ?? false;
}
