import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../model/variant_model.dart';

class VariantProvider extends ChangeNotifier {
  final Box<Variant> _variantBox = Hive.box<Variant>('variants');

  // ─────────────────────────────────────────────────────────────
  // GET: All non-deleted variants
  List<Variant> get allVariants =>
      _variantBox.values.where((v) => !v.isDeleted).toList();

  // GET: Single variant by ID
  Variant? getById(String id) => _variantBox.values.firstWhere(
        (variant) => variant.variantId == id && !variant.isDeleted,
  );

  // GET: Variants by Product ID
  List<Variant> getByProductId(String productId) {
    return _variantBox.values
        .where((v) => v.productId == productId && !v.isDeleted)
        .toList();
  }

  // ─────────────────────────────────────────────────────────────
  // ADD: New variant
  Future<void> addVariant(Variant variant) async {
    await _variantBox.put(variant.variantId, variant);
    notifyListeners();
  }

  // ─────────────────────────────────────────────────────────────
  // UPDATE: Existing variant
  Future<void> updateVariant(Variant updatedVariant) async {
    if (_variantBox.containsKey(updatedVariant.variantId)) {
      await _variantBox.put(updatedVariant.variantId, updatedVariant);
      notifyListeners();
    }
  }

  // ─────────────────────────────────────────────────────────────
  // DELETE: Soft delete (sets isDeleted = true)
  Future<void> deleteVariant(String id) async {
    final variant = _variantBox.get(id);
    if (variant != null) {
      variant.isDeleted = true;
      await variant.save();
      notifyListeners();
    }
  }

  // PERMANENT DELETE
  Future<void> deletePermanently(String id) async {
    await _variantBox.delete(id);
    notifyListeners();
  }

  // RESTORE: Undelete
  Future<void> restoreVariant(String id) async {
    final variant = _variantBox.get(id);
    if (variant != null && variant.isDeleted) {
      variant.isDeleted = false;
      await variant.save();
      notifyListeners();
    }
  }
}
