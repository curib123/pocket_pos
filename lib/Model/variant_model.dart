import 'package:hive/hive.dart';

part 'variant_model.g.dart';

@HiveType(typeId: 1)
class Variant extends HiveObject {
  @HiveField(0)
  String variantId;

  @HiveField(1)
  String productId;

  @HiveField(2)
  String name;

  @HiveField(3)
  String? sku;

  @HiveField(4)
  String? barcode;

  @HiveField(5)
  double? price;

  @HiveField(6)
  double? costPrice;

  @HiveField(7)
  int? stockQuantity;

  @HiveField(8)
  int? reorderLevel;

  @HiveField(9)
  List<String>? images;

  @HiveField(10)
  String? mainImage;

  @HiveField(11)
  String? unit;

  @HiveField(12)
  String? unitType;

  @HiveField(13)
  double? unitConversion;

  @HiveField(14)
  String? unitPriceBasis;

  @HiveField(15)
  bool isDeleted;

  @HiveField(16)
  DateTime? createdAt;

  @HiveField(17)
  DateTime? updatedAt;

  Variant({
    required this.variantId,
    required this.productId,
    required this.name,
    this.sku,
    this.barcode,
    this.price,
    this.costPrice,
    this.stockQuantity,
    this.reorderLevel,
    this.images,
    this.mainImage,
    this.unit,
    this.unitType,
    this.unitConversion,
    this.unitPriceBasis,
    this.isDeleted = false,
    this.createdAt,
    this.updatedAt,
  });

  factory Variant.fromJson(Map<String, dynamic> json) {
    return Variant(
      variantId: json['variantId'] as String,
      productId: json['productId'] as String,
      name: json['name'] as String,
      sku: json['sku'] as String?,
      barcode: json['barcode'] as String?,
      price: json['price'] != null ? (json['price'] as num).toDouble() : null,
      costPrice: json['costPrice'] != null ? (json['costPrice'] as num).toDouble() : null,
      stockQuantity: json['stockQuantity'] as int?,
      reorderLevel: json['reorderLevel'] as int?,
      images: json['images'] != null ? List<String>.from(json['images']) : null,
      mainImage: json['mainImage'] as String?,
      unit: json['unit'] as String?,
      unitType: json['unitType'] as String?,
      unitConversion: json['unitConversion'] != null ? (json['unitConversion'] as num).toDouble() : null,
      unitPriceBasis: json['unitPriceBasis'] as String?,
      isDeleted: json['isDeleted'] ?? false,
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt']) : null,
      updatedAt: json['updatedAt'] != null ? DateTime.tryParse(json['updatedAt']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'variantId': variantId,
      'productId': productId,
      'name': name,
      'sku': sku,
      'barcode': barcode,
      'price': price,
      'costPrice': costPrice,
      'stockQuantity': stockQuantity,
      'reorderLevel': reorderLevel,
      'images': images,
      'mainImage': mainImage,
      'unit': unit,
      'unitType': unitType,
      'unitConversion': unitConversion,
      'unitPriceBasis': unitPriceBasis,
      'isDeleted': isDeleted,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }
}
