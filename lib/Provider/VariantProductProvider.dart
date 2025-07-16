import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:mobile_stock_inventory/Model/product_model.dart';
import 'package:mobile_stock_inventory/View/Components/SnackbarService.dart';

class VariantProductProvider extends ChangeNotifier {
  final Box<Product> _productBox;

  VariantProductProvider(this._productBox);

  /// 🔍 Utility to find the parent product by ID or name
  Product? _getParent(String idOrName) {
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

  /// ✅ Get variants by parent product ID or name
  List<Product> getVariants(String idOrName) {
    final parent = _getParent(idOrName);
    return parent?.variants ?? [];
  }

  /// ➕ Add a new variant
  Future<void> addVariant(String idOrName, Product variant) async {
    try {
      final parent = _getParent(idOrName);
      if (parent == null) {
        SnackbarService.showWarning("❌ Parent product not found.");
        return;
      }

      final variantExists = parent.variants.any(
            (v) => v.name.trim().toLowerCase() == variant.name.trim().toLowerCase(),
      );

      if (variantExists) {
        SnackbarService.showWarning("⚠️ Variant already exists.");
        return;
      }

      final updatedParent = parent.copyWith(
        hasVariant: true,
        variants: [...parent.variants, variant],
        lastModified: DateTime.now(),
      );

      await _productBox.put(updatedParent.id, updatedParent);
      notifyListeners();

      SnackbarService.showSuccess("✅ Variant added: ${variant.name}");
    } catch (e) {
      SnackbarService.showError("❌ Failed to add variant: $e");
    }
  }

  /// 📝 Update existing variant
  Future<void> updateVariant(String idOrName, Product updatedVariant) async {
    try {
      final parent = _getParent(idOrName);
      if (parent == null) return;

      final updatedVariants = parent.variants.map((v) {
        return v.id == updatedVariant.id ? updatedVariant : v;
      }).toList();

      final updatedParent = parent.copyWith(
        variants: updatedVariants,
        lastModified: DateTime.now(),
      );

      await _productBox.put(updatedParent.id, updatedParent);
      notifyListeners();

      SnackbarService.showSuccess("✅ Variant updated: ${updatedVariant.name}");
    } catch (e) {
      SnackbarService.showError("❌ Failed to update variant: $e");
    }
  }

  /// 🗑️ Delete variant by ID
  Future<void> deleteVariant(String idOrName, String variantId) async {
    try {
      final parent = _getParent(idOrName);
      if (parent == null) return;

      final updatedVariants =
      parent.variants.where((v) => v.id != variantId).toList();

      final updatedParent = parent.copyWith(
        variants: updatedVariants,
        hasVariant: updatedVariants.isNotEmpty,
        lastModified: DateTime.now(),
      );

      await _productBox.put(updatedParent.id, updatedParent);
      notifyListeners();

      SnackbarService.showSuccess("🗑️ Variant deleted.");
    } catch (e) {
      SnackbarService.showError("❌ Failed to delete variant: $e");
    }
  }


}
