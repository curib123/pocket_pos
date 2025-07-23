import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:pocketpos/Model/cart_item_model.dart';
import 'package:pocketpos/Model/product_model.dart';

class CartListProvider with ChangeNotifier {
  final List<CartItem> _cartItems = [];
  final Box<Product> _productBox;

  CartListProvider(this._productBox);

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

  /// 🚀 Scan barcode → find product → add to cart
  Product? getProductByBarcode(String barcode) {
    final normalized = barcode.trim().toLowerCase();

    for (final product in _productBox.values) {
      if (product.deletedAt != null) continue;

      // 🔍 Check main product barcode
      if ((product.barcode ?? '').trim().toLowerCase() == normalized) {
        return product;
      }

      // 🔍 Check variants' barcodes
      if (product.hasVariant && product.variants.isNotEmpty) {
        for (final variant in product.variants.whereType<Product>()) {
          if (variant.deletedAt != null) continue;

          if ((variant.barcode ?? '').trim().toLowerCase() == normalized) {
            return variant;
          }
        }
      }
    }

    return null;
  }

  ({bool success, String? error}) scanAndAddByBarcode({
    required String barcode,
    required bool isPackView,
  }) {
    final product = getProductByBarcode(barcode);
    if (product == null) {
      final msg = 'Product not found for barcode $barcode';
      debugPrint('❌ $msg');
      return (success: false, error: msg);
    }


    final latest = product.stocks.isNotEmpty ? product.stocks.last : null;

    if (latest == null) {
      final msg = 'No stock found for ${product.name}';
      debugPrint('⚠️ $msg');
      return (success: false, error: msg);
    }

    final isPieceOnly = product.isSoldByPiece && !product.isSoldByPack;
    final perPack = product.piecesPerPack ?? 0;
    final sellingType =  isPieceOnly ? SellingType.piece : isPackView ? SellingType.pack : SellingType.piece;


    // 🧮 Pricing logic
    final price = isPieceOnly
        ? latest.retailPrice
        : isPackView
        ? latest.retailPrice
        : latest.retailPrice / perPack;

    // 🧮 Pricing logic
    final qty = isPieceOnly
        ? product.totalQuantity
        : isPackView
        ? product.totalQuantity
        : product.looseStock!.remainingPieces.toDouble();

    final cartItem = CartItem(
      productId: product.id,
      name: product.name,
      price: price,
      quantity: 1,
      maxQuantity: qty.toInt(),
      imagePath: product.imagePath,
      isSoldPerPack: product.isSoldByPack,
      isSoldPerPiece: product.isSoldByPiece,
      sellingType: sellingType,
      barcode: product.barcode,
    );

    addToCart(cartItem);
    return (success: true, error: null);
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
