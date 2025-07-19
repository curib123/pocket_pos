enum SellingType {
  piece,
  pack,
}

class CartItem {
  final String productId;
  final String name;
  final double price;
  int quantity;
  final int maxQuantity;
  final String? imagePath;
  final bool isSoldPerPack;
  final bool isSoldPerPiece;
  final SellingType sellingType;

  CartItem({
    required this.productId,
    required this.name,
    required this.price,
    required this.quantity,
    this.maxQuantity = 999,
    this.imagePath,
    required this.isSoldPerPack,
    required this.isSoldPerPiece,
    required this.sellingType,
  });

  double getSubtotal() => price * quantity;

  CartItem copyWith({
    String? productId,
    String? name,
    double? price,
    int? quantity,
    int? maxQuantity,
    String? imagePath,
    bool? isSoldPerPack,
    bool? isSoldPerPiece,
    SellingType? sellingType,
  }) {
    return CartItem(
      productId: productId ?? this.productId,
      name: name ?? this.name,
      price: price ?? this.price,
      quantity: quantity ?? this.quantity,
      maxQuantity: maxQuantity ?? this.maxQuantity,
      imagePath: imagePath ?? this.imagePath,
      isSoldPerPack: isSoldPerPack ?? this.isSoldPerPack,
      isSoldPerPiece: isSoldPerPiece ?? this.isSoldPerPiece,
      sellingType: sellingType ?? this.sellingType,
    );
  }
}
