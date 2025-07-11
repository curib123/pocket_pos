import 'package:hive/hive.dart';

part 'stock_batch_model.g.dart';

@HiveType(typeId: 3)
class StockBatch extends HiveObject {
  @HiveField(0)
  String batchId;

  @HiveField(1)
  String productId;

  @HiveField(2)
  int quantity;

  @HiveField(3)
  int quantitySold;

  @HiveField(4)
  DateTime receivedDate;

  @HiveField(5)
  String? supplier;

  @HiveField(6)
  DateTime? expiryDate;

  @HiveField(7)
  double? costPrice;

  @HiveField(8)
  bool isDeleted;

  StockBatch({
    required this.batchId,
    required this.productId,
    required this.quantity,
    this.quantitySold = 0,
    required this.receivedDate,
    this.supplier,
    this.expiryDate,
    this.costPrice,
    this.isDeleted = false,
  });

  int get remainingQuantity => quantity - quantitySold;

  factory StockBatch.fromJson(Map<String, dynamic> json) {
    return StockBatch(
      batchId: json['batchId'] as String,
      productId: json['productId'] as String,
      quantity: json['quantity'] ?? 0,
      quantitySold: json['quantitySold'] ?? 0,
      receivedDate: DateTime.parse(json['receivedDate']),
      supplier: json['supplier'] as String?,
      expiryDate: json['expiryDate'] != null
          ? DateTime.tryParse(json['expiryDate'])
          : null,
      costPrice: json['costPrice'] != null
          ? (json['costPrice'] as num).toDouble()
          : null,
      isDeleted: json['isDeleted'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'batchId': batchId,
      'productId': productId,
      'quantity': quantity,
      'quantitySold': quantitySold,
      'receivedDate': receivedDate.toIso8601String(),
      'supplier': supplier,
      'expiryDate': expiryDate?.toIso8601String(),
      'costPrice': costPrice,
      'isDeleted': isDeleted,
    };
  }
}
