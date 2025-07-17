import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:mobile_stock_inventory/Model/product_model.dart';
import 'package:mobile_stock_inventory/Model/stock_log.dart';
import 'package:mobile_stock_inventory/Provider/ProductSync.dart';
import 'package:mobile_stock_inventory/View/Components/SnackbarService.dart';

class StockLogProvider extends ChangeNotifier {
  final Box<Product> _productBox;
  late final ProductSync _productSync;

  StockLogProvider(this._productBox);

  void attachSync(ProductSync sync) {
    _productSync = sync;
  }


  Product? _getProduct(String idOrName) {
    try {
      return _productBox.values.firstWhere(
            (p) =>
        p.deletedAt == null &&
            (p.id == idOrName ||
                p.name.trim().toLowerCase() ==
                    idOrName.trim().toLowerCase()),
      );
    } catch (_) {
      return null;
    }
  }

  List<StockLog> getLogs(String idOrName) {
    final product = _getProduct(idOrName);
    return product?.logs
        .where((log) => log.deletedAt == null)
        .toList()
        .reversed
        .toList() ??
        [];
  }

  Future<void> addLog(String idOrName, StockLog log) async {
    final product = _getProduct(idOrName);
    if (product == null) {
      SnackbarService.showWarning("⚠️ Product not found.");
      return;
    }

    final updated = product.copyWith(
      logs: [...product.logs, log],
      lastModified: DateTime.now(),
    );

    await _productBox.put(updated.id, updated);
    await _productSync.autoSync(); // 🔁 auto-sync
    notifyListeners();
    SnackbarService.showSuccess("✅ Log added.");
  }

  Future<void> updateLog(String idOrName, StockLog updatedLog) async {
    final product = _getProduct(idOrName);
    if (product == null) return;

    final updatedLogs = product.logs.map((log) {
      return log.id == updatedLog.id ? updatedLog : log;
    }).toList();

    final updatedProduct = product.copyWith(
      logs: updatedLogs,
      lastModified: DateTime.now(),
    );

    await _productBox.put(updatedProduct.id, updatedProduct);
    await _productSync.autoSync();
    notifyListeners();
    SnackbarService.showSuccess("✅ Log updated.");
  }

  Future<void> deleteLog(String idOrName, String logId) async {
    final product = _getProduct(idOrName);
    if (product == null) return;

    final updatedLogs = product.logs.map((log) {
      if (log.id == logId) {
        return log.copyWith(
          deletedAt: DateTime.now(),
          lastModified: DateTime.now(),
        );
      }
      return log;
    }).toList();

    final updatedProduct = product.copyWith(
      logs: updatedLogs,
      lastModified: DateTime.now(),
    );

    await _productBox.put(updatedProduct.id, updatedProduct);
    await _productSync.autoSync();
    notifyListeners();
    SnackbarService.showSuccess("🗑️ Log deleted.");
  }

  Future<void> clearLogs(String idOrName) async {
    final product = _getProduct(idOrName);
    if (product == null) return;

    final updatedProduct = product.copyWith(
      logs: [],
      lastModified: DateTime.now(),
    );

    await _productBox.put(updatedProduct.id, updatedProduct);
    await _productSync.autoSync();
    notifyListeners();
    SnackbarService.showSuccess("🧹 Logs cleared.");
  }

  int getTotalByReason(String idOrName, StockLogReason reason) {
    final product = _getProduct(idOrName);
    if (product == null) return 0;

    return product.logs
        .where((log) => log.reason == reason && log.deletedAt == null)
        .fold(0, (sum, log) => sum + log.quantity);
  }

  int getTotalSold(String idOrName) =>
      getTotalByReason(idOrName, StockLogReason.sold);

  StockLog? getLatestLog(String idOrName) {
    final product = _getProduct(idOrName);
    if (product == null || product.logs.isEmpty) return null;

    final logs = product.logs.where((log) => log.deletedAt == null).toList();
    return logs.isEmpty ? null : logs.last;
  }

  List<StockLog> getLogsByReason(String idOrName, StockLogReason reason) {
    final product = _getProduct(idOrName);
    if (product == null) return [];

    return product.logs
        .where((log) => log.reason == reason && log.deletedAt == null)
        .toList();
  }
}
