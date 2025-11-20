import 'package:flutter/material.dart';
import 'package:nextpos/Model/product_model.dart';
import 'package:nextpos/Model/product_stock.dart';
import 'package:nextpos/Model/loose_stock.dart';
import 'package:nextpos/Provider/ProductProvider.dart';
import 'package:nextpos/Provider/VariantProductProvider.dart';
import 'package:nextpos/Provider/LooseStockProvider.dart';
import 'package:nextpos/View/Components/Alert/CustomNotificationDialog.dart';

Future<void> submitProductHelper({
  required BuildContext context,
  required ProductProvider productProvider,
  required VariantProductProvider variantProductProvider,
  required LooseStockProvider looseStockProvider,
  required bool isSoldByPack,
  required bool isSoldByPiece,
  required String name,
  required String barcode,
  required bool isEditing,
  required bool isVariant,
  required bool hasVariant,
  required String? selectedUnit,
  required String? selectedCategory,
  required String? imagePath,
  required String piecesPerPackText,
  required List<ProductStock> stock,
  required List<Product> variants,
  required Product? existingProduct,
  required Product? parentProduct,
  required String looseStockText,
  required TextEditingController nameController,
  required TextEditingController barcodeController,
  required TextEditingController piecesPerPackController,
  required TextEditingController looseStockController,
}) async {
  if (!isSoldByPack && !isSoldByPiece) {
    showDialog(
      context: context,
      builder: (_) => CustomNotificationDialog(
        title: "Missing Selling Method",
        content: "Please select at least one selling method: Pack, Piece, or both.",
        type: 'warning',
        onConfirm: () => Navigator.pop(context),
      ),
    );
    return;
  }

  final now = DateTime.now();
  final productId = isEditing
      ? existingProduct!.id
      : now.millisecondsSinceEpoch.toString();

  final updatedStocks = stock
      .map((s) => s.copyWith(productId: productId))
      .toList();

  final updatedVariants = variants
      .map((variant) => variant.copyWith(
    isVariant: true,
    looseStock: LooseStock(
      productId: variant.id,
      remainingPieces: variant.totalQuantityByPieces,
    ),
  ))
      .toList();

  final product = Product(
    id: productId,
    name: name,
    category: selectedCategory ?? "Uncategorized",
    unit: selectedUnit ?? 'pcs',
    piecesPerPack: isSoldByPiece
        ? int.tryParse(piecesPerPackText.trim()) ?? 0
        : 0,
    isSoldByPack: isSoldByPack,
    isSoldByPiece: isSoldByPiece,
    imagePath: imagePath ?? '',
    barcode: barcode,
    createdAt: isEditing ? existingProduct!.createdAt : now,
    lastModified: now,
    isSoftDeleted: false,
    stocks: updatedStocks,
    logs: existingProduct?.logs ?? [],
    hasVariant: hasVariant,
    variants: hasVariant ? updatedVariants : [],
    looseStock: null,
  );

  if (!isEditing && productProvider.productExistsByName(name)) {
    showDialog(
      context: context,
      builder: (_) => CustomNotificationDialog(
        onConfirm: () => Navigator.pop(context),
        type: 'warning',
        title: "Product Already Exists",
        content:
        "A product or variant with the name \"$name\" already exists. Please use a different name.",
      ),
    );
    return;
  }

  try {
    if (isVariant) {

      final parentId = parentProduct!.id;
      print(productProvider.getProductById(parentId)!.name.toString());
      await variantProductProvider.upsertVariant(parentId, product);
      Navigator.pop(context, product);
      return;
    }

    if (isEditing && existingProduct!.isVariant) {
      final parentId = variantProductProvider
          .getParentProductIdFromVariantId(productId)
          ?.toString() ??
          'unknown';
      await variantProductProvider.upsertVariant(parentId, product);
      Navigator.pop(context, product);
      return;
    }

    await productProvider.upsertProduct(product);

    if (isSoldByPiece) {
      final looseQty = int.tryParse(looseStockText.trim()) ?? 0;
      await looseStockProvider.upsertLooseStock(productId, looseQty);
    } else {
      await looseStockProvider.deleteLooseStock(productId);
    }

    showDialog(
      context: context,
      builder: (_) => CustomNotificationDialog(
        onConfirm: () {
          Navigator.pop(context);
          Navigator.pop(context);
        },
        type: 'success',
        title: isEditing ? "Product Updated" : "Product Added",
        content: isEditing
            ? "The product was successfully updated!"
            : "The product was successfully added!",
      ),
    );
  } catch (e) {
    debugPrint("❌ Error saving product: $e");
    showDialog(
      context: context,
      builder: (_) => CustomNotificationDialog(
        onConfirm: () => Navigator.pop(context),
        type: 'error',
        title: "Failed to Save",
        content:
        "Something went wrong while saving the product.\nError: $e",
      ),
    );
  }
}
