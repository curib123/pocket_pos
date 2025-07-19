import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:mobile_stock_inventory/Model/product_model.dart';
import 'package:mobile_stock_inventory/Model/stock_log.dart';
import 'package:mobile_stock_inventory/Provider/ProductProvider.dart';

class VariantProductProvider extends ChangeNotifier {
  final Box<Product> _productBox;
  late ProductProvider _productProvider;

  VariantProductProvider(this._productBox);

  void attachProductProvider(ProductProvider provider) {
    _productProvider = provider;
  }

  ProductProvider get productProvider => _productProvider;

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

  String? getParentProductIdFromVariantId(String variantId) {
    try {
      final parent = _productBox.values.firstWhere(
            (product) =>
        product.deletedAt == null &&
            product.hasVariant &&
            product.variants.any((v) => v.id == variantId),
      );
      return parent.id;
    } catch (_) {
      return null;
    }
  }

  Future<void> upsertVariant(String parentId, Product variant) async {
    try {
      final parent = _getParent(parentId);

      if (parent == null) {

        return;
      }

      Product updatedVariant = variant.copyWith(
        isVariant: true,
        lastModified: DateTime.now(),
      );

      final int existingIndex =
      parent.variants.indexWhere((v) => v.id == updatedVariant.id);
      List<StockLog> logs = [];

      if (existingIndex == -1) {
        // ➕ NEW VARIANT
        for (final stock in updatedVariant.stocks) {
          if (stock.quantity > 0) {
            logs.add(
              StockLog(
                id: 'log-${stock.id}',
                productId: updatedVariant.id,
                quantity: stock.quantity,
                isPiece: false,
                reason: StockLogReason.added,
                remarks: 'Initial stock (pack)',
              ),
            );
          }
        }

        final loose = updatedVariant.looseStock?.remainingPieces ?? 0;
        if (loose > 0) {
          logs.add(
            StockLog(
              id: 'log-${updatedVariant.id}-loose',
              productId: updatedVariant.id,
              quantity: loose,
              isPiece: true,
              reason: StockLogReason.added,
              remarks: 'Initial stock (loose)',
            ),
          );
        }

        updatedVariant = updatedVariant.copyWith(
          logs: [...updatedVariant.logs, ...logs],
        );

        final updatedParent = parent.copyWith(
          hasVariant: true,
          variants: [...parent.variants, updatedVariant],
          lastModified: DateTime.now(),
        );

        await _productBox.put(updatedParent.id, updatedParent);
        _productProvider.refreshProducts();
        notifyListeners();

      } else {
        // 🔁 UPDATE EXISTING VARIANT
        final oldVariant = parent.variants[existingIndex];

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
                remarks: 'Updated stock: ${oldStock.quantity} → ${newStock.quantity}',
              ),
            );
          }
        }

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
              remarks: 'Updated loose: $oldLoose → $newLoose',
            ),
          );
        }

        updatedVariant = updatedVariant.copyWith(
          logs: [...updatedVariant.logs, ...logs],
        );

        final updatedVariants = [...parent.variants];
        updatedVariants[existingIndex] = updatedVariant;

        final updatedParent = parent.copyWith(
          variants: updatedVariants,
          lastModified: DateTime.now(),
        );

        await _productBox.put(updatedParent.id, updatedParent);
        _productProvider.refreshProducts();
        notifyListeners();


        final savedParent = _productBox.get(parent.id);
        if (savedParent != null) {
          debugPrint("🧠 Parent updated: ${savedParent.name}, Variants: ${savedParent.variants.map((v) => v.name).toList()}");
        }
      }
    } catch (e) {

      debugPrint("❌ Variant upsert error: $e");
    }
  }

  Future<void> deleteVariant(String idOrName, String variantId) async {
    try {
      final parent = _getParent(idOrName);
      if (parent == null) return;

      final matchingVariants = parent.variants.where((v) => v.id == variantId).toList();

      if (matchingVariants.isEmpty) {

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
      _productProvider.refreshProducts();
      notifyListeners();


    } catch (e) {

    }
  }
}
