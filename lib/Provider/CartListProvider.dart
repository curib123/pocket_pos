import 'package:flutter/material.dart';
import 'package:mobile_stock_inventory/Model/cart_item_model.dart';

class CartListProvider with ChangeNotifier {
  final List<CartItem> _cartItems = [];

  List<CartItem> get cartItems => List.unmodifiable(_cartItems);

  /// 🚀 Add to cart or update existing item (Upsert logic)
  void addToCart(CartItem item) {
    if (item.quantity <= 0) return;

    final index = _cartItems.indexWhere((e) => e.productId == item.productId);

    if (index >= 0) {
      // 🔁 Update existing item
      final existing = _cartItems[index];
      final newQuantity = existing.quantity + item.quantity;
      _cartItems[index] = existing.copyWith(quantity: newQuantity);
    } else {
      // ➕ Add new item
      _cartItems.add(item);
    }

    notifyListeners();
  }

  /// ✏️ Update exact quantity
  void updateQuantity(String productId, int quantity) {
    if (quantity <= 0) return removeFromCart(productId);

    final index = _cartItems.indexWhere((e) => e.productId == productId);
    if (index >= 0) {
      _cartItems[index].quantity = quantity;
      notifyListeners();
    }
  }

  /// ➕ Increment quantity by 1
  void incrementQuantity(String productId) {
    final index = _cartItems.indexWhere((e) => e.productId == productId);
    if (index >= 0) {
      _cartItems[index].quantity += 1;
      notifyListeners();
    }
  }

  /// ➖ Decrement quantity by 1 (removes if hits 0)
  void decrementQuantity(String productId) {
    final index = _cartItems.indexWhere((e) => e.productId == productId);
    if (index >= 0) {
      final newQty = _cartItems[index].quantity - 1;
      if (newQty <= 0) {
        removeFromCart(productId);
      } else {
        _cartItems[index].quantity = newQty;
        notifyListeners();
      }
    }
  }

  /// 🎯 Get a specific CartItem by productId
  CartItem? getCartItem(String productId) {
    try {
      return _cartItems.firstWhere((e) => e.productId == productId);
    } catch (_) {
      return null;
    }
  }

  /// ❌ Remove item
  void removeFromCart(String productId) {
    _cartItems.removeWhere((e) => e.productId == productId);
    notifyListeners();
  }

  /// 🧹 Clear everything
  void clearCart() {
    _cartItems.clear();
    notifyListeners();
  }

  /// 🔍 Check if item is in cart
  bool isInCart(String productId) =>
      _cartItems.any((e) => e.productId == productId);

  /// 💵 Get total cost
  double get totalPrice =>
      _cartItems.fold(0, (sum, item) => sum + item.getSubtotal());

  /// 🧮 Total items (for cart badge)
  int get totalItems =>
      _cartItems.fold(0, (sum, item) => sum + item.quantity);

  /// 🪄 Replace the whole cart (e.g. from saved state)
  void replaceCart(List<CartItem> newCart) {
    _cartItems
      ..clear()
      ..addAll(newCart);
    notifyListeners();
  }
}
