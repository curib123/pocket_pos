import 'package:flutter/material.dart';
import 'package:mobile_stock_inventory/Model/cart_item_model.dart';
import 'package:mobile_stock_inventory/Provider/ProductProvider.dart';
import 'package:mobile_stock_inventory/Provider/ProductStockProvider.dart';
import 'package:mobile_stock_inventory/View/Components/Alert/CustomNotificationDialog.dart';

Future<void> handleSellingDeduction(
    BuildContext context,
    ProductStockProvider productStockProvider,
    ProductProvider productProvider,
    String productId,
    bool isSoldByPack,
    bool isSoldByPiece,
    SellingType sellingType,
    double quantity,
    ) async {
  if (!isSoldByPack && !isSoldByPiece) {
    showDialog(
      context: context,
      builder: (_) => const CustomNotificationDialog(
        title: "Selling Error",
        content: "Product must be marked as sold by pack or piece.",
        type: "error",
      ),
    );
    return;
  }

  if (quantity % 1 != 0) {
    print('⚠️ Quantity has decimals: $quantity (will be truncated to ${quantity.toInt()})');
  }

  try {
    final int qty = quantity.toInt();

    if (!isSoldByPack && isSoldByPiece) {
      final success = await productStockProvider.sellPack(
        productId,
        qty,
      );
      if (success) _showSuccessDialog(context, qty, isPiece: true);
      productProvider.refreshProducts();
      return;
    }

    if (isSoldByPack && isSoldByPiece) {
      if (sellingType == SellingType.pack) {
        final success = await productStockProvider.sellPack(
          productId,
          qty,
        );
        if (success) _showSuccessDialog(context, qty, isPiece: false);
      } else {
        final success = await productStockProvider.sellPiece(
          productId,
          qty,
        );
        if (success) _showSuccessDialog(context, qty, isPiece: true);
      }
      productProvider.refreshProducts();
      return;
    }

    if (isSoldByPack && !isSoldByPiece) {
      final success = await productStockProvider.sellPack(
        productId,
        qty,
      );
      if (success) _showSuccessDialog(context, qty, isPiece: false);
      productProvider.refreshProducts();
      return;
    }
  } catch (e) {
    print('❌ Error during selling deduction: $e');
    showDialog(
      context: context,
      builder: (_) => CustomNotificationDialog(
        title: "Selling Failed",
        content: "An error occurred while deducting stock.\nError: $e",
        type: "error",
      ),
    );
  }
}

void _showSuccessDialog(BuildContext context, int quantity, {required bool isPiece}) {
  showDialog(
    context: context,
    builder: (_) => CustomNotificationDialog(
      onConfirm: () {
        Navigator.pop(context);
        Navigator.pop(context);
      } ,
      title: "Success!",
      content: "Sold $quantity ${isPiece ? "piece(s)" : "pack(s)"} successfully.",
      type: "success",
    ),
  );
}
