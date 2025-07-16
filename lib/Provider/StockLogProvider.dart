import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:mobile_stock_inventory/Model/product_model.dart';
import 'package:mobile_stock_inventory/Model/stock_log.dart';
import 'package:mobile_stock_inventory/View/Components/SnackbarService.dart';

class StockLogProvider extends ChangeNotifier {
  final Box<Product> _productBox;

  StockLogProvider(this._productBox);

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

  /// 📜 Get all logs (latest first)
  List<StockLog> getLogs(String idOrName) {
    final product = _getProduct(idOrName);
    return product?.logs.reversed.toList() ?? [];
  }

  /// ➕ Add new log
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
    notifyListeners();
    SnackbarService.showSuccess("✅ Log added.");
  }

  /// ✏️ Update a log by ID
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
    notifyListeners();
    SnackbarService.showSuccess("✅ Log updated.");
  }

  /// 🗑️ Soft delete log by ID
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
    notifyListeners();
    SnackbarService.showSuccess("🗑️ Log deleted.");
  }

  /// 🧼 Clear all logs
  Future<void> clearLogs(String idOrName) async {
    final product = _getProduct(idOrName);
    if (product == null) return;

    final updatedProduct = product.copyWith(
      logs: [],
      lastModified: DateTime.now(),
    );

    await _productBox.put(updatedProduct.id, updatedProduct);
    notifyListeners();
    SnackbarService.showSuccess("🧹 Logs cleared.");
  }

  /// 📊 Get total stock out (filtered)
  int getTotalByReason(String idOrName, StockOutType type) {
    final product = _getProduct(idOrName);
    if (product == null) return 0;

    return product.logs
        .where((log) => log.reason == type && log.deletedAt == null)
        .fold(0, (sum, log) => sum + log.quantity);
  }

  /// 📊 Get total quantity sold
  int getTotalSold(String idOrName) => getTotalByReason(idOrName, StockOutType.sold);

  /// 🕰️ Get latest log
  StockLog? getLatestLog(String idOrName) {
    final product = _getProduct(idOrName);
    if (product == null || product.logs.isEmpty) return null;
    return product.logs.last;
  }

  /// 🔎 Get logs by reason
  List<StockLog> getLogsByReason(String idOrName, StockOutType reason) {
    final product = _getProduct(idOrName);
    if (product == null) return [];
    return product.logs
        .where((log) => log.reason == reason && log.deletedAt == null)
        .toList();
  }
}
