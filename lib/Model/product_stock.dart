import 'package:hive/hive.dart';

part 'product_stock.g.dart';

@HiveType(typeId: 1)
class ProductStock extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String productId;

  @HiveField(2)
  int quantity;

  @HiveField(3)
  final double costPrice;

  @HiveField(4)
  final DateTime dateReceived;

  @HiveField(5)
  final DateTime lastModified;

  @HiveField(6)
  final DateTime? deletedAt;

  @HiveField(7) // 👈 new field
  final double retailPrice;

  ProductStock({
    required this.id,
    required this.productId,
    required this.quantity,
    required this.costPrice,
    required this.dateReceived,
    DateTime? lastModified,
    this.deletedAt,
    required this.retailPrice, // 👈 required for consistency
  }) : lastModified = lastModified ?? DateTime.now();

  // ✅ toMap
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'productId': productId,
      'quantity': quantity,
      'costPrice': costPrice,
      'retailPrice': retailPrice,
      'dateReceived': dateReceived.toIso8601String(),
      'lastModified': lastModified.toIso8601String(),
      'deletedAt': deletedAt?.toIso8601String(),
    };
  }

  // ✅ fromMap
  factory ProductStock.fromMap(Map<String, dynamic> map) {
    return ProductStock(
      id: map['id'],
      productId: map['productId'],
      quantity: map['quantity'],
      costPrice: map['costPrice'],
      retailPrice: map['retailPrice'] ?? 0.0, // 👈 fallback to 0.0 if missing
      dateReceived: DateTime.parse(map['dateReceived']),
      lastModified: DateTime.parse(map['lastModified']),
      deletedAt: map['deletedAt'] != null ? DateTime.parse(map['deletedAt']) : null,
    );
  }

  // ✅ copyWith
  ProductStock copyWith({
    String? id,
    String? productId,
    int? quantity,
    double? costPrice,
    double? retailPrice,
    DateTime? dateReceived,
    DateTime? lastModified,
    DateTime? deletedAt,
  }) {
    return ProductStock(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      quantity: quantity ?? this.quantity,
      costPrice: costPrice ?? this.costPrice,
      retailPrice: retailPrice ?? this.retailPrice,
      dateReceived: dateReceived ?? this.dateReceived,
      lastModified: lastModified ?? this.lastModified,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }
}
