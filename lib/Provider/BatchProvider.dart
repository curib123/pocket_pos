import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:mobile_pos_inventory/Model/product_model.dart';
import 'package:mobile_pos_inventory/Model/batch_model.dart';
import 'package:mobile_pos_inventory/View/Components/SnackbarService.dart';

class BatchProvider with ChangeNotifier {
  final Box<Product> _productBox;

  BatchProvider(this._productBox);

  Product? _getProduct(String productName) {
    try {
      return _productBox.values.firstWhere(
            (p) =>
        p.name.trim().toLowerCase() == productName.trim().toLowerCase() &&
            p.deletedAt == null,
      );
    } catch (_) {
      return null;
    }
  }

  List<Batch> getBatchesByProductName(String productName) {
    final product = _getProduct(productName);
    return product?.batches ?? [];
  }

  Future<void> addBatch(
      String productName,
      Batch newBatch,
      double itemsPerBundle,
      ) async {
    try {
      final product = _getProduct(productName);
      if (product == null) return;

      final existing = product.batches.firstWhere(
            (b) =>
        b.createdAt.year == newBatch.createdAt.year &&
            b.createdAt.month == newBatch.createdAt.month &&
            b.createdAt.day == newBatch.createdAt.day,
        orElse: () => Batch(id: '', quantity: 0, createdAt: DateTime(2000)),
      );

      if (existing.id.isNotEmpty) {
        existing.quantity += newBatch.quantity;
        existing.subQuantity =
            (existing.subQuantity ?? 0) + (newBatch.quantity * itemsPerBundle);
      } else {
        newBatch.subQuantity = newBatch.quantity * itemsPerBundle;
        product.batches.add(newBatch);
      }

      product.lastModified = DateTime.now();
      await _productBox.put(product.id, product);
      SnackbarService.showSuccess('✅ Batch added to $productName');
      notifyListeners();
    } catch (e) {
      SnackbarService.showError('❌ Failed to add batch: $e');
    }
  }

  Future<void> updateSubQuantity(
      String productName,
      String batchId,
      double newSubQuantity,
      ) async {
    try {
      final product = _getProduct(productName);
      if (product == null) return;

      final index = product.batches.indexWhere((b) => b.id == batchId);
      if (index == -1) {
        SnackbarService.showWarning('⚠️ Batch not found in $productName');
        return;
      }

      final updated = product.batches[index].copyWith(subQuantity: newSubQuantity);
      product.batches[index] = updated;
      product.lastModified = DateTime.now();

      await _productBox.put(product.id, product);
      SnackbarService.showSuccess('✅ Updated subQuantity for batch in $productName');
      notifyListeners();
    } catch (e) {
      SnackbarService.showError('❌ Failed to update subQuantity: $e');
    }
  }

  String? getBatchIdByIndex(String productName, int index) {
    final product = _getProduct(productName);
    if (product == null || index < 0 || index >= product.batches.length) return null;
    return product.batches[index].id;
  }

  Future<void> updateBatchQuantity(
      String productName,
      String batchId,
      double newQuantity,
      ) async {
    try {
      final product = _getProduct(productName);
      if (product == null) return;

      final index = product.batches.indexWhere((b) => b.id == batchId);
      if (index == -1) {
        SnackbarService.showWarning('⚠️ Batch not found in $productName');
        return;
      }

      final updated = product.batches[index].copyWith(quantity: newQuantity);
      product.batches[index] = updated;
      product.lastModified = DateTime.now();

      await _productBox.put(product.id, product);
      SnackbarService.showSuccess('✅ Updated quantity for batch in $productName');
      notifyListeners();
    } catch (e) {
      SnackbarService.showError('❌ Failed to update batch quantity: $e');
    }
  }

  Future<void> deleteBatch(String productName, String batchId) async {
    try {
      final product = _getProduct(productName);
      if (product == null) return;

      product.batches.removeWhere((b) => b.id == batchId);
      product.lastModified = DateTime.now();
      await _productBox.put(product.id, product);
      SnackbarService.showSuccess('🗑️ Batch deleted from $productName');
      notifyListeners();
    } catch (e) {
      SnackbarService.showError('❌ Failed to delete batch: $e');
    }
  }

  Future<void> deleteSubQuantity(String productName, String batchId) async {
    try {
      final product = _getProduct(productName);
      if (product == null) return;

      final index = product.batches.indexWhere((b) => b.id == batchId);
      if (index == -1) {
        SnackbarService.showWarning('⚠️ Batch not found in $productName');
        return;
      }

      final updated = product.batches[index].copyWith(subQuantity: null);
      product.batches[index] = updated;
      product.lastModified = DateTime.now();

      await _productBox.put(product.id, product);
      SnackbarService.showSuccess('🗑️ subQuantity removed from batch in $productName');
      notifyListeners();
    } catch (e) {
      SnackbarService.showError('❌ Failed to delete subQuantity: $e');
    }
  }


  Future<void> incrementFIFO(
      String productName,
      double quantityToAdd,
      double itemsPerBundle,
      ) async {
    try {
      final product = _getProduct(productName);
      if (product == null || product.batches.isEmpty) return;

      product.batches.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      final first = product.batches.first;
      final index = product.batches.indexOf(first);

      product.batches[index] = first.copyWith(
        quantity: first.quantity + quantityToAdd,
        subQuantity:
        (first.subQuantity ?? 0) + (quantityToAdd * itemsPerBundle),
      );

      product.lastModified = DateTime.now();
      await _productBox.put(product.id, product);
      SnackbarService.showSuccess('➕ Incremented $quantityToAdd to $productName');
      notifyListeners();
    } catch (e) {
      SnackbarService.showError('❌ Failed to increment batch: $e');
    }
  }
}
