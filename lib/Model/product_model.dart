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
  double costPrice;

  @HiveField(3)
  double retailPrice;

  @HiveField(4)
  String unit;

  @HiveField(5)
  List<Batch> batches;

  @HiveField(6)
  String description;

  @HiveField(7)
  String imageUrl;

  @HiveField(8)
  String category;

  @HiveField(9)
  DateTime lastModified;

  @HiveField(10)
  DateTime? deletedAt;

  Product({
    required this.id,
    required this.name,
    required this.costPrice,
    required this.retailPrice,
    required this.unit,
    required this.batches,
    required this.description,
    required this.imageUrl,
    required this.category,
    required this.lastModified,
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

  double get totalQuantity => batches.fold(0, (sum, batch) => sum + batch.quantity);

  double get totalCostValue => totalQuantity * costPrice;

  double get totalRetailValue => totalQuantity * retailPrice;

  Product copyWith({
    String? id,
    String? name,
    double? costPrice,
    double? retailPrice,
    String? unit,
    String? description,
    String? imageUrl,
    String? category,
    List<Batch>? batches,
    DateTime? lastModified,
    DateTime? deletedAt,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      costPrice: costPrice ?? this.costPrice,
      retailPrice: retailPrice ?? this.retailPrice,
      unit: unit ?? this.unit,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      category: category ?? this.category,
      batches: batches ?? this.batches,
      lastModified: lastModified ?? this.lastModified,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }

  String toString() {
    return '''
Product {
  id: $id,
  name: $name,
  description: $description,
  cost_price: $costPrice,
  retail_price: $retailPrice,
  unit: $unit,
  category: $category,
  image_url: $imageUrl,
  lastModified: $lastModified,
  deletedAt: $deletedAt,
  batches: ${batches.map((b) => b.toString()).join(',\n           ')}
}''';
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'cost_price': costPrice,
      'retail_price': retailPrice,
      'unit': unit,
      'batches': batches.map((e) => e.toMap()).toList(),
      'description': description,
      'image_url': imageUrl,
      'category': category,
      'last_modified': lastModified.toIso8601String(),
      'deleted_at': deletedAt?.toIso8601String(),
    };
  }

  /// ✅ Static factory method for deserialization
  static Product fromMap(Map<String, dynamic> json) {
    return Product(
      id: json['id'] as String,
      name: json['name'] as String,
      costPrice: (json['cost_price'] as num).toDouble(),
      retailPrice: (json['retail_price'] as num).toDouble(),
      unit: json['unit'] as String,
      batches: (json['batches'] as List<dynamic>)
          .map((e) => Batch.fromMap(e as Map<String, dynamic>))
          .toList(),
      description: json['description'] as String,
      imageUrl: json['image_url'] as String,
      category: json['category'] as String,
      lastModified: json['last_modified'] != null
          ? DateTime.parse(json['last_modified'])
          : DateTime.now(),
      deletedAt: json['deleted_at'] != null
          ? DateTime.tryParse(json['deleted_at'])
          : null,
    );
  }
}
