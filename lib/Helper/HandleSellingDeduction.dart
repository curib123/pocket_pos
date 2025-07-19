import 'package:flutter/material.dart';
import 'package:mobile_stock_inventory/Model/cart_item_model.dart';
import 'package:mobile_stock_inventory/Provider/ProductProvider.dart';
import 'package:mobile_stock_inventory/Provider/ProductStockProvider.dart';

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
    _showAlert(context, "Selling Error", "Product must be marked as sold by pack or piece.");
    return;
  }

  try {
    final int qty = quantity.toInt();

    bool success = false;

    if (!isSoldByPack && isSoldByPiece) {
      success = await productStockProvider.sellPack(productId, qty);
    }

    if (isSoldByPack && isSoldByPiece) {
      if (sellingType == SellingType.pack) {
        success = await productStockProvider.sellPack(productId, qty);
      } else {
        success = await productStockProvider.sellPiece(productId, qty);
      }
    }

    if (isSoldByPack && !isSoldByPiece) {
      success = await productStockProvider.sellPack(productId, qty);
    }

    if (success) {
      _showSuccessSnack(context, "Sold successfully.");
      productProvider.refreshProducts();
    }
  } catch (e) {
    print('❌ Error during selling deduction: $e');
    _showAlert(context, "Selling Failed", "An error occurred while deducting stock.\nError: $e");
  }
}

void _showAlert(BuildContext context, String title, String message) {
  showDialog(
    context: context,
    builder: (_) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          child: const Text("OK"),
          onPressed: () => Navigator.pop(context),
        ),
      ],
    ),
  );
}

void _showSuccessSnack(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: Colors.green,
      duration: const Duration(seconds: 2),
    ),
  );
}
