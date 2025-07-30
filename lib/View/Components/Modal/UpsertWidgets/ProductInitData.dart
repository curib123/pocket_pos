import 'dart:io';
import 'package:flutter/material.dart';
import 'package:pocketpos/Model/product_model.dart';
import 'package:pocketpos/Model/product_stock.dart';

class ProductInitData {
  final TextEditingController nameController;
  final TextEditingController barcodeController;
  final TextEditingController looseStockController;
  final TextEditingController piecesPerPackController;
  final List<ProductStock> stock;
  final List<Product> variants;

  bool hasStock;
  bool hasVariant;
  String selectedCategory;
  String selectedUnit;
  bool isSoldByPack;
  bool isSoldByPiece;
  File? selectedImage;

  ProductInitData({
    required this.nameController,
    required this.barcodeController,
    required this.looseStockController,
    required this.piecesPerPackController,
    required this.stock,
    required this.variants,
    this.hasStock = false,
    this.hasVariant = false,
    this.selectedCategory = '',
    this.selectedUnit = '',
    this.isSoldByPack = false,
    this.isSoldByPiece = false,
    this.selectedImage,
  });
}

ProductInitData initProductState({
  required Product? existingProduct,
  required Product? parentProduct,
  required bool isVariant,
  required String passedCategory,
  required void Function() updateLooseStock,
}) {
  final nameController = TextEditingController();
  final barcodeController = TextEditingController();
  final looseStockController = TextEditingController();
  final piecesPerPackController = TextEditingController();
  final stock = <ProductStock>[];
  final variants = <Product>[];

  String selectedCategory = passedCategory;
  String selectedUnit = '';
  bool isSoldByPack = false;
  bool isSoldByPiece = false;
  bool hasVariant = false;
  File? selectedImage;
  bool hasStock = false;

  if (existingProduct != null) {
    final p = existingProduct;
    nameController.text = p.name;
    selectedCategory = p.category!;
    selectedUnit = p.unit!;
    isSoldByPack = p.isSoldByPack;
    isSoldByPiece = p.isSoldByPiece;
    barcodeController.text = p.barcode ?? '';
    hasVariant = p.hasVariant;
    selectedImage = (p.imagePath?.isNotEmpty == true) ? File(p.imagePath!) : null;
    variants.addAll(p.variants);
    piecesPerPackController.text = p.piecesPerPack.toString();
    looseStockController.text = p.looseStock?.remainingPieces.toString() ?? '';
    stock.addAll(p.stocks);
    hasStock = stock.isNotEmpty;

  } else if (isVariant && parentProduct != null) {
    selectedCategory = parentProduct.category!;
    selectedUnit = parentProduct.unit!;
    isSoldByPack = parentProduct.isSoldByPack;
    isSoldByPiece = parentProduct.isSoldByPiece;
    piecesPerPackController.text = parentProduct.piecesPerPack.toString();
    piecesPerPackController.addListener(updateLooseStock);
    updateLooseStock();

  } else {
    piecesPerPackController.text = '0';
    piecesPerPackController.addListener(updateLooseStock);
    updateLooseStock();
  }

  return ProductInitData(
    nameController: nameController,
    barcodeController: barcodeController,
    looseStockController: looseStockController,
    piecesPerPackController: piecesPerPackController,
    stock: stock,
    variants: variants,
    selectedCategory: selectedCategory,
    selectedUnit: selectedUnit,
    isSoldByPack: isSoldByPack,
    isSoldByPiece: isSoldByPiece,
    hasVariant: hasVariant,
    selectedImage: selectedImage,
    hasStock: hasStock,
  );
}
