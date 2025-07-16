import 'package:flutter/material.dart';
import 'package:mobile_stock_inventory/Model/product_model.dart';
import 'package:mobile_stock_inventory/View/Components/SnackbarService.dart';

class CartProvider with ChangeNotifier {
  final List<Product> _cart = [];

  List<Product> get cartItems => List.unmodifiable(_cart);

  void addToCart(Product product) {
    final index = _cart.indexWhere((p) => p.name.toLowerCase() == product.name.toLowerCase());
    if (index == -1) {
      _cart.add(product);
      SnackbarService.showSuccess('🛒 Added to cart: ${product.name}');
    } else {
      _cart[index] = product;
      SnackbarService.showInfo('🔁 Updated cart item: ${product.name}');
    }
    notifyListeners();
  }


  void removeFromCart(String productName) {
    _cart.removeWhere((p) => p.name.toLowerCase() == productName.toLowerCase());
    SnackbarService.showSuccess('🗑️ Removed from cart: $productName');
    notifyListeners();
  }

  void clearCart() {
    _cart.clear();
    SnackbarService.showSuccess('🧹 Cart cleared');
    notifyListeners();
  }

  bool isInCart(String productName) {
    return _cart.any((p) => p.name.toLowerCase() == productName.toLowerCase());
  }
}
