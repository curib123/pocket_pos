import 'package:hive/hive.dart';
import 'batch_model.dart';

part 'product_model.g.dart';

@HiveType(typeId: 0)
class Product extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  String unit;

  @HiveField(3)
  List<Batch> batches;

  @HiveField(4)
  String description;

  @HiveField(5)
  String imageUrl;

  @HiveField(6)
  String category;

  @HiveField(7)
  DateTime lastModified;

  @HiveField(8)
  DateTime? deletedAt;

  // 🔥 New pricing and packaging logic
  @HiveField(9)
  double defaultCost;

  @HiveField(10)
  double defaultRetail;

  @HiveField(11)
  bool isPack;

  @HiveField(12)
  double packItems;

  @HiveField(13)
  double packItemsCost;

  @HiveField(14)
  double packItemsRetail;

  @HiveField(15)
  double profitMargin;

  Product({
    required this.id,
    required this.name,
    required this.unit,
    required this.batches,
    required this.description,
    required this.imageUrl,
    required this.category,
    required this.lastModified,
    required this.defaultCost,
    required this.defaultRetail,
    required this.isPack,
    required this.packItems,
    required this.packItemsCost,
    required this.packItemsRetail,
    required this.profitMargin,
    this.deletedAt,
  });

  Future<void> saveWithTimestamp() {
    lastModified = DateTime.now();
    return save();
  }

  Future<void> softDelete() {
    deletedAt = DateTime.now();
    lastModified = deletedAt!;
    return save();
  }

  double get totalQuantity => batches.fold(0, (sum, b) => sum + b.quantity);
  double get subQuantity => batches.fold(0, (sum, b) => sum + (b.subQuantity ?? 0));
  double get costPerItem => totalQuantity == 0 ? 0 : defaultCost / totalQuantity;


  Product copyWith({
    String? id,
    String? name,
    String? unit,
    List<Batch>? batches,
    String? description,
    String? imageUrl,
    String? category,
    DateTime? lastModified,
    DateTime? deletedAt,
    double? defaultCost,
    double? defaultRetail,
    bool? isPack,
    double? packItems,
    double? packItemsCost,
    double? packItemsRetail,
    double? profitMargin,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      unit: unit ?? this.unit,
      batches: batches ?? this.batches,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      category: category ?? this.category,
      lastModified: lastModified ?? this.lastModified,
      deletedAt: deletedAt ?? this.deletedAt,
      defaultCost: defaultCost ?? this.defaultCost,
      defaultRetail: defaultRetail ?? this.defaultRetail,
      isPack: isPack ?? this.isPack,
      packItems: packItems ?? this.packItems,
      packItemsCost: packItemsCost ?? this.packItemsCost,
      packItemsRetail: packItemsRetail ?? this.packItemsRetail,
      profitMargin: profitMargin ?? this.profitMargin,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'unit': unit,
      'batches': batches.map((b) => b.toMap()).toList(),
      'description': description,
      'image_url': imageUrl,
      'category': category,
      'last_modified': lastModified.toIso8601String(),
      'deleted_at': deletedAt?.toIso8601String(),
      'default_cost': defaultCost,
      'default_retail': defaultRetail,
      'is_pack': isPack,
      'pack_items': packItems,
      'pack_items_cost': packItemsCost,
      'pack_items_retail': packItemsRetail,
      'profit_margin': profitMargin,
    };
  }

  static Product fromMap(Map<String, dynamic> json) {
    return Product(
      id: json['id'],
      name: json['name'],
      unit: json['unit'],
      batches: (json['batches'] as List).map((e) => Batch.fromMap(e)).toList(),
      description: json['description'],
      imageUrl: json['image_url'],
      category: json['category'],
      lastModified: DateTime.parse(json['last_modified']),
      deletedAt: json['deleted_at'] != null
          ? DateTime.tryParse(json['deleted_at'])
          : null,
      defaultCost: (json['default_cost'] ?? 0).toDouble(),
      defaultRetail: (json['default_retail'] ?? 0).toDouble(),
      isPack: json['is_pack'] ?? false,
      packItems: (json['pack_items'] ?? 0).toDouble(),
      packItemsCost: (json['pack_items_cost'] ?? 0).toDouble(),
      packItemsRetail: (json['pack_items_retail'] ?? 0).toDouble(),
      profitMargin: (json['profit_margin'] ?? 0).toDouble(),
    );
  }

  @override
  String toString() {
    return '''
Product {
  id: $id,
  name: $name,
  defaultCost: $defaultCost,
  defaultRetail: $defaultRetail,
  unit: $unit,
  isPack: $isPack,
  packItems: $packItems,
  packItemsCost: $packItemsCost,
  packItemsRetail: $packItemsRetail,
  profitMargin: $profitMargin,
  totalQuantity: $totalQuantity,
  costPerItem: $costPerItem,
  batches: ${batches.map((b) => b.toString()).join(', ')}
}''';
  }
}
