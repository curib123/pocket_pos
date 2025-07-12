import 'package:flutter/material.dart';
import 'package:mobile_pos_inventory/Model/product_model.dart';
import 'package:mobile_pos_inventory/View/Components/SnackbarService.dart';

class CartProvider with ChangeNotifier {
  final List<Product> _cart = [];
  List<Product> get cartItems => List.unmodifiable(_cart);

  void addToCart(Product product) {
    final index = _cart.indexWhere((p) => p.name.toLowerCase() == product.name.toLowerCase());
    if (index == -1) {
      _cart.add(product);
      SnackbarService.showSuccess('🛒 Added to cart: ${product.name}');
    } else {
      _cart[index] = product; // Replace with updated product
      SnackbarService.showInfo('🔁 Updated cart item: ${product.name}');
    }
    notifyListeners();
  }


  double getQuantityByProductName(String productName) {
    final product = _cart.firstWhere(
          (p) => p.name.toLowerCase() == productName.toLowerCase(),
      orElse: () => Product(
        id: '',
        name: '',
        costPrice: 0,
        retailPrice: 0,
        unit: '',
        batches: [],
        description: '',
        imageUrl: '',
        category: '',
        lastModified: DateTime.now(),
      ),
    );
    return product.totalQuantity;
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
