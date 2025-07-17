import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:mobile_stock_inventory/Model/product_model.dart';
import 'package:mobile_stock_inventory/Model/stock_log.dart';
import 'package:mobile_stock_inventory/View/Components/SnackbarService.dart';

class VariantProductProvider extends ChangeNotifier {
  final Box<Product> _productBox;

  VariantProductProvider(this._productBox);

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

  List<Product> getVariants(String idOrName) {
    final parent = _getParent(idOrName);
    return parent?.variants ?? [];
  }

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

      final List<StockLog> logs = [];

      for (final stock in variant.stocks) {
        if (stock.quantity > 0) {
          logs.add(
            StockLog(
              id: 'log-${stock.id}',
              productId: variant.id,
              quantity: stock.quantity,
              isPiece: false,
              reason: StockLogReason.added,
              remarks: 'Initial stock (pack)',
            ),
          );
        }
      }

      if (variant.looseStock?.remainingPieces != null &&
          variant.looseStock!.remainingPieces > 0) {
        logs.add(
          StockLog(
            id: 'log-${variant.id}-loose',
            productId: variant.id,
            quantity: variant.looseStock!.remainingPieces,
            isPiece: true,
            reason: StockLogReason.added,
            remarks: 'Initial stock (loose)',
          ),
        );
      }

      final newVariant = variant.copyWith(
        logs: [...variant.logs, ...logs],
        lastModified: DateTime.now(),
      );

      final updatedParent = parent.copyWith(
        hasVariant: true,
        variants: [...parent.variants, newVariant],
        lastModified: DateTime.now(),
      );

      await _productBox.put(updatedParent.id, updatedParent);
      notifyListeners();

      SnackbarService.showSuccess("✅ Variant added: ${variant.name}");
    } catch (e) {
      SnackbarService.showError("❌ Failed to add variant: $e");
    }
  }

  Future<void> updateVariant(String idOrName, Product updatedVariant) async {
    try {
      final parent = _getParent(idOrName);
      if (parent == null) return;

      final oldVariant = parent.variants.firstWhere(
            (v) => v.id == updatedVariant.id,
        orElse: () => updatedVariant,
      );

      final List<StockLog> logs = [];

      // Compare stocks
      for (final newStock in updatedVariant.stocks) {
        final oldStock = oldVariant.stocks.firstWhere(
              (s) => s.id == newStock.id,
          orElse: () => newStock,
        );

        if (newStock.quantity != oldStock.quantity) {
          logs.add(
            StockLog(
              id: 'log-${newStock.id}-${DateTime.now().millisecondsSinceEpoch}',
              productId: updatedVariant.id,
              quantity: newStock.quantity,
              isPiece: false,
              reason: StockLogReason.adjusted,
              remarks:
              'Updated stock qty: ${oldStock.quantity} → ${newStock.quantity}',
            ),
          );
        }
      }

      // Compare loose stock
      final oldLoose = oldVariant.looseStock?.remainingPieces ?? 0;
      final newLoose = updatedVariant.looseStock?.remainingPieces ?? 0;

      if (oldLoose != newLoose) {
        logs.add(
          StockLog(
            id: 'log-${updatedVariant.id}-loose-${DateTime.now().millisecondsSinceEpoch}',
            productId: updatedVariant.id,
            quantity: newLoose,
            isPiece: true,
            reason: StockLogReason.adjusted,
            remarks: 'Updated loose stock: $oldLoose → $newLoose',
          ),
        );
      }

      final newVariant = updatedVariant.copyWith(
        logs: [...updatedVariant.logs, ...logs],
        lastModified: DateTime.now(),
      );

      final updatedVariants = parent.variants.map((v) {
        return v.id == updatedVariant.id ? newVariant : v;
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

  Future<void> deleteVariant(String idOrName, String variantId) async {
    try {
      final parent = _getParent(idOrName);
      if (parent == null) return;

      final matchingVariants = parent.variants.where((v) => v.id == variantId).toList();

      if (matchingVariants.isEmpty) {
        SnackbarService.showWarning("⚠️ Variant not found.");
        return;
      }

      final variantToDelete = matchingVariants.first;


      final List<StockLog> logs = [];

      for (final stock in variantToDelete.stocks) {
        if (stock.quantity > 0) {
          logs.add(
            StockLog(
              id: 'log-${stock.id}-removed',
              productId: variantId,
              quantity: stock.quantity,
              isPiece: false,
              reason: StockLogReason.deleted,
              remarks: 'Removed stock on variant delete',
            ),
          );
        }
      }

      final looseQty = variantToDelete.looseStock?.remainingPieces ?? 0;
      if (looseQty > 0) {
        logs.add(
          StockLog(
            id: 'log-${variantId}-loose-removed',
            productId: variantId,
            quantity: looseQty,
            isPiece: true,
            reason: StockLogReason.deleted,
            remarks: 'Removed loose stock on variant delete',
          ),
        );
      }

      final updatedVariants = parent.variants.where((v) => v.id != variantId).toList();

      final updatedParent = parent.copyWith(
        variants: updatedVariants,
        hasVariant: updatedVariants.isNotEmpty,
        lastModified: DateTime.now(),
        logs: [...parent.logs, ...logs],
      );

      await _productBox.put(updatedParent.id, updatedParent);
      notifyListeners();

      SnackbarService.showSuccess("🗑️ Variant deleted.");
    } catch (e) {
      SnackbarService.showError("❌ Failed to delete variant: $e");
    }
  }

}

