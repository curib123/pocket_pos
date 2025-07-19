class CartItem {
  final String productId;
  final String name;
  final double price;
  int quantity;
  final int maxQuantity;
  final String? imagePath;

  CartItem({
    required this.productId,
    required this.name,
    required this.price,
    this.quantity = 1,
    this.maxQuantity = 999, // default cap
    this.imagePath,
  });

  // Optional: for immutability
  CartItem copyWith({
    String? productId,
    String? name,
    double? price,
    int? quantity,
    int? maxQuantity,
    String? imagePath,
  }) {
    return CartItem(
      productId: productId ?? this.productId,
      name: name ?? this.name,
      price: price ?? this.price,
      quantity: quantity ?? this.quantity,
      maxQuantity: maxQuantity ?? this.maxQuantity,
      imagePath: imagePath ?? this.imagePath,
    );
  }
}
