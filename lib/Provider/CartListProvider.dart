import 'package:flutter/material.dart';
import 'package:mobile_stock_inventory/Model/cart_item_model.dart';

class CartListProvider with ChangeNotifier {
  final List<CartItem> _cartItems = [];

  List<CartItem> get cartItems => List.unmodifiable(_cartItems);

  // 🚀 Add or update
  void addToCart(CartItem item, {int quantity = 1}) {
    final index = _cartItems.indexWhere((e) => e.productId == item.productId);

    if (index >= 0) {
      _cartItems[index].quantity += quantity;
    } else {
      _cartItems.add(item.copyWith(quantity: quantity));
    }

    notifyListeners();
  }

  // ✏️ Update quantity
  void updateQuantity(String productId, int quantity) {
    final index = _cartItems.indexWhere((e) => e.productId == productId);
    if (index >= 0) {
      _cartItems[index].quantity = quantity;
      notifyListeners();
    }
  }

  // ❌ Remove item
  void removeFromCart(String productId) {
    _cartItems.removeWhere((e) => e.productId == productId);
    notifyListeners();
  }

  // 🧹 Clear everything
  void clearCart() {
    _cartItems.clear();
    notifyListeners();
  }

  // 💰 Total cost
  double get totalPrice => _cartItems.fold(
    0,
        (sum, item) => sum + (item.price * item.quantity),
  );

  // 🔍 Check presence
  bool isInCart(String productId) =>
      _cartItems.any((e) => e.productId == productId);

  // 📦 Get quantity
  int getQuantity(String productId) =>
      _cartItems.firstWhere(
            (e) => e.productId == productId,
        orElse: () => CartItem(productId: '', name: '', price: 0),
      ).quantity;
}
