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
  DateTime lastModified;  // <-- New field

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
  });

  /// Convenience method to update timestamp and save
  Future<void> saveWithTimestamp() {
    lastModified = DateTime.now();
    return save();
  }

  /// Total number of sacks/bags
  double get totalSacks => batches.fold(0, (sum, batch) => sum + batch.quantity);

  /// Total weight in kilos
  double get totalKilos => batches.fold(0, (sum, batch) => sum + batch.kiloQuantity);

  /// Total cost based on kilos only
  double get totalCostValueKilo => totalKilos * costPrice;

  /// Total cost based on sacks only
  double get totalCostValueSack => totalSacks * costPrice;

  /// Total retail based on kilos
  double get totalRetailValueKilo => totalKilos * retailPrice;

  /// Total retail based on sacks
  double get totalRetailValueSack => totalSacks * retailPrice;

  /// For Supabase Insert / Update
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
      'last_modified': lastModified.toIso8601String(), // Include timestamp
    };
  }
}

/// External Mapper (for Supabase Query)
Product mapProductFromJson(Map<String, dynamic> json) {
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
  );
}
