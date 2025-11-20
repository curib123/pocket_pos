import 'dart:io';
import 'package:flutter/material.dart';
import 'package:nextpos/Model/product_model.dart';
import 'package:nextpos/Provider/ProductProvider.dart';
import 'package:nextpos/View/Components/Modal/UpsertProductModal.dart';

Future<void> openAddVariantDialog({
  required BuildContext context,
  required ProductProvider productProvider,
  required Product? existingProduct,
  required String? selectedUnit,
  required bool isSoldByPack,
  required bool isSoldByPiece,
  required String? selectedCategory,
  required String piecesPerPackText,
  required File? selectedImage,
  required TextEditingController nameController,
  required String categoryFromParent,
  required void Function(Product newVariant) onVariantAdded,
}) async {
  final now = DateTime.now();
  final parentId = existingProduct?.id ?? now.millisecondsSinceEpoch.toString();

  final parent = Product(
    id: parentId,
    name: nameController.text.trim(),
    unit: selectedUnit ?? 'pcs',
    isSoldByPack: isSoldByPack,
    isSoldByPiece: isSoldByPiece,
    category: selectedCategory ?? "Uncategorized",
    piecesPerPack: int.tryParse(piecesPerPackText.trim()) ?? 1,
    createdAt: now,
    lastModified: now,
    imagePath: selectedImage?.path ?? '',
    hasVariant: true,
    variants: const [],
    stocks: const [],
    logs: const [],
    barcode: '',
    looseStock: null,
  );

  final newVariant = await showModalBottomSheet<Product>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
    ),
    builder: (context) => DraggableScrollableSheet(
      expand: false,
      maxChildSize: 0.80,
      initialChildSize: 0.75,
      minChildSize: 0.6,
      builder: (_, controller) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Material(
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
          child: SafeArea(
            top: false,
            child: SingleChildScrollView(
              controller: controller,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              child: UpsertProductModal(
                Category: categoryFromParent,
                isVariant: true,
                existingProduct: null,
                parentProduct: parent,
              ),
            ),
          ),
        ),
      ),
    ),
  );

  if (newVariant != null) {
    onVariantAdded(newVariant); // Call the callback to add to list
  }
}
