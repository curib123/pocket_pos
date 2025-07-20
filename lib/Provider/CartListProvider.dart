import 'package:flutter/material.dart';
import 'package:mobile_stock_inventory/Model/cart_item_model.dart';

class CartListProvider with ChangeNotifier {
  final List<CartItem> _cartItems = [];

  List<CartItem> get cartItems => List.unmodifiable(_cartItems);

  String getTaggedName(CartItem item) {
    final rawName = item.name.replaceAll(RegExp(r' \((pcs|pack)\)$'), '');

    final label = item.sellingType == SellingType.piece
        ? ' (pcs)'
        : ' (pack)';
    
    return '$rawName$label';
  }


  void addToCart(CartItem item) {
    if (item.quantity <= 0) return;

    final taggedName = getTaggedName(item);
    final updatedItem = item.copyWith(name: taggedName);

    final index = _cartItems.indexWhere((e) =>
    e.name == taggedName &&
        e.sellingType == updatedItem.sellingType);

    if (index >= 0) {
      final existing = _cartItems[index];
      final newQuantity = existing.quantity + updatedItem.quantity;
      _cartItems[index] = existing.copyWith(quantity: newQuantity);
    } else {
      _cartItems.add(updatedItem);
    }

    notifyListeners();
  }



  /// ✏️ Update quantity by name
  void updateQuantity(String name, int quantity) {
    if (quantity <= 0) return removeFromCart(name);

    final index = _cartItems.indexWhere((e) => e.name == name);
    if (index >= 0) {
      _cartItems[index].quantity = quantity;
      notifyListeners();
    }
  }

  /// ➕ Increment quantity by name
  void incrementQuantity(String name) {
    final index = _cartItems.indexWhere((e) => e.name == name);
    if (index >= 0) {
      _cartItems[index].quantity += 1;
      notifyListeners();
    }
  }

  /// ➖ Decrement quantity by name
  void decrementQuantity(String name) {
    final index = _cartItems.indexWhere((e) => e.name == name);
    if (index >= 0) {
      final newQty = _cartItems[index].quantity - 1;
      if (newQty <= 0) {
        removeFromCart(name);
      } else {
        _cartItems[index].quantity = newQty;
        notifyListeners();
      }
    }
  }

  /// 🎯 Get item by name
  CartItem? getCartItem(String name) {
    try {
      return _cartItems.firstWhere((e) => e.name == name);
    } catch (_) {
      return null;
    }
  }

  /// ❌ Remove item by name
  void removeFromCart(String name) {
    _cartItems.removeWhere((e) => e.name == name);
    notifyListeners();
  }

  /// 🔍 Check if in cart by name
  bool isInCart(String name) => _cartItems.any((e) => e.name == name);

  /// 💵 Total cost
  double get totalPrice =>
      _cartItems.fold(0, (sum, item) => sum + item.getSubtotal());

  /// 🧮 Total items
  int get totalItems =>
      _cartItems.fold(0, (sum, item) => sum + item.quantity);

  /// 🧼 Replace all
  void replaceCart(List<CartItem> newCart) {
    _cartItems
      ..clear()
      ..addAll(newCart);
    notifyListeners();
  }

  /// 🧹 Clear everything
  void clearAll() {
    _cartItems.clear();
    notifyListeners();
  }

}
