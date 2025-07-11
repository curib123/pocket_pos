import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../model/stock_batch_model.dart';

class StockBatchProvider extends ChangeNotifier {
  final Box<StockBatch> _stockBox = Hive.box<StockBatch>('stock_batches');

  // ─────────────────────────────────────────────────────────────
  // GET: All non-deleted stock batches
  List<StockBatch> get allBatches =>
      _stockBox.values.where((b) => !b.isDeleted).toList();

  // GET: Single batch by ID
  StockBatch? getById(String id) => _stockBox.get(id);

  // GET: All batches by productId
  List<StockBatch> getBatchesByProduct(String productId) {
    return _stockBox.values
        .where((b) => b.productId == productId && !b.isDeleted)
        .toList();
  }

  // ─────────────────────────────────────────────────────────────
  // ADD: New stock batch
  Future<void> addBatch(StockBatch batch) async {
    await _stockBox.put(batch.batchId, batch);
    notifyListeners();
  }

  // ─────────────────────────────────────────────────────────────
  // UPDATE: Existing stock batch
  Future<void> updateBatch(StockBatch batch) async {
    if (_stockBox.containsKey(batch.batchId)) {
      await _stockBox.put(batch.batchId, batch);
      notifyListeners();
    }
  }

  // ─────────────────────────────────────────────────────────────
  // DELETE: Soft delete
  Future<void> deleteBatch(String batchId) async {
    final batch = _stockBox.get(batchId);
    if (batch != null) {
      batch.isDeleted = true;
      await batch.save();
      notifyListeners();
    }
  }

  // PERMANENT DELETE (optional)
  Future<void> deletePermanently(String batchId) async {
    await _stockBox.delete(batchId);
    notifyListeners();
  }

  // RESTORE
  Future<void> restoreBatch(String batchId) async {
    final batch = _stockBox.get(batchId);
    if (batch != null && batch.isDeleted) {
      batch.isDeleted = false;
      await batch.save();
      notifyListeners();
    }
  }

  // GET: Remaining quantity for a product
  int getTotalRemaining(String productId) {
    return getBatchesByProduct(productId)
        .fold(0, (sum, b) => sum + b.remainingQuantity);
  }
}
