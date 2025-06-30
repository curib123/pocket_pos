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
  String unit; // Still useful for pricing label or UI

  @HiveField(5)
  List<Batch> batches;

  @HiveField(6)
  String description;

  @HiveField(7)
  String imageUrl;

  @HiveField(8)
  String category;

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
  });

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
}
