import 'package:hive/hive.dart';

part 'product_model.g.dart';

@HiveType(typeId: 0)
class Product extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  String? description;

  @HiveField(3)
  String? category; // ← changed from categoryId to category

  @HiveField(4)
  String type;

  @HiveField(5)
  String status;

  @HiveField(6)
  String? sku;

  @HiveField(7)
  String? barcode;

  @HiveField(8)
  double? defaultPrice;

  @HiveField(9)
  double? costPrice;

  @HiveField(10)
  double? taxRate;

  @HiveField(11)
  double? discount;

  @HiveField(12)
  bool isActive;

  @HiveField(13)
  bool isDeleted;

  @HiveField(14)
  List<String>? images;

  @HiveField(15)
  String? mainImage;

  @HiveField(16)
  bool hasVariants;

  @HiveField(17)
  List<String>? variantIds;

  @HiveField(18)
  List<String>? addonIds;

  @HiveField(19)
  List<String>? stockBatchIds;

  @HiveField(20)
  String? unit;

  @HiveField(21)
  String? unitType;

  @HiveField(22)
  double? unitConversion;

  @HiveField(23)
  String? unitPriceBasis;

  @HiveField(24)
  Map<String, dynamic>? attributes;

  @HiveField(25)
  DateTime? createdAt;

  @HiveField(26)
  DateTime? updatedAt;

  Product({
    required this.id,
    required this.name,
    required this.type,
    required this.status,
    this.description,
    this.category,
    this.sku,
    this.barcode,
    this.defaultPrice,
    this.costPrice,
    this.taxRate,
    this.discount,
    this.isActive = true,
    this.isDeleted = false,
    this.images,
    this.mainImage,
    this.hasVariants = false,
    this.variantIds,
    this.addonIds,
    this.stockBatchIds,
    this.unit,
    this.unitType,
    this.unitConversion,
    this.unitPriceBasis,
    this.attributes,
    this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'category': category,
      'type': type,
      'status': status,
      'sku': sku,
      'barcode': barcode,
      'default_price': defaultPrice,
      'cost_price': costPrice,
      'tax_rate': taxRate,
      'discount': discount,
      'is_active': isActive,
      'is_deleted': isDeleted,
      'images': images,
      'main_image': mainImage,
      'has_variants': hasVariants,
      'variant_ids': variantIds,
      'addon_ids': addonIds,
      'stock_batch_ids': stockBatchIds,
      'unit': unit,
      'unit_type': unitType,
      'unit_conversion': unitConversion,
      'unit_price_basis': unitPriceBasis,
      'attributes': attributes,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'],
      name: json['name'] ?? '',
      description: json['description'],
      category: json['category'],
      type: json['type'],
      status: json['status'],
      sku: json['sku'],
      barcode: json['barcode'],
      defaultPrice: (json['default_price'] as num?)?.toDouble(),
      costPrice: (json['cost_price'] as num?)?.toDouble(),
      taxRate: (json['tax_rate'] as num?)?.toDouble(),
      discount: (json['discount'] as num?)?.toDouble(),
      isActive: json['is_active'] ?? true,
      isDeleted: json['is_deleted'] ?? false,
      images: (json['images'] as List?)?.map((e) => e.toString()).toList(),
      mainImage: json['main_image'],
      hasVariants: json['has_variants'] ?? false,
      variantIds: (json['variant_ids'] as List?)?.map((e) => e.toString()).toList(),
      addonIds: (json['addon_ids'] as List?)?.map((e) => e.toString()).toList(),
      stockBatchIds: (json['stock_batch_ids'] as List?)?.map((e) => e.toString()).toList(),
      unit: json['unit'],
      unitType: json['unit_type'],
      unitConversion: (json['unit_conversion'] as num?)?.toDouble(),
      unitPriceBasis: json['unit_price_basis'],
      attributes: json['attributes'] is Map ? Map<String, dynamic>.from(json['attributes']) : null,
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at']) : null,
      updatedAt: json['updated_at'] != null ? DateTime.tryParse(json['updated_at']) : null,
    );
  }
}
